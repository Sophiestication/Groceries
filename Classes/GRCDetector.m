//
// MIT License
//
// Copyright (c) 2008-2023 Sophiestication Software, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "GRCDetector.h"

#import "GRCDetectorValue+Private.h"

#import "GRCUnitFormatter.h"

#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"
#import "NSString+Additions.h"

@interface GRCDetector()

@property(nonatomic, strong) NSMutableDictionary* unitIndex;
@property(nonatomic, strong) NSNumberFormatter* quantityFormatter;

@end

@implementation GRCDetector

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		NSNumberFormatter* quantityFormatter = [[NSNumberFormatter alloc] init];
		quantityFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		self.quantityFormatter = quantityFormatter;

		self.locale = [NSLocale autoupdatingCurrentLocale]; // also sets the quantity formatter locale
	}

	return self;
}

#pragma mark - GRCGroceryDataDetector

- (void)setLocale:(NSLocale *)locale {
	if(locale == self.locale) { return; }

	_locale = locale;
	
	// self.unitIndex = nil; // force re-evalutation of localized strings
	self.quantityFormatter.locale = locale;
}

- (id)detectInString:(NSString*)string error:(NSError* __autoreleasing *)error {
	if(!string) { return nil; }
	
	NSArray* scannedObjects = [self scanObjects:string];

	NSDictionary* quantity;
	NSDictionary* unit;

	NSRange quantityRange = NSMakeRange(0, 0);
	NSRange groceryTitleRange = NSMakeRange(0, 0);

	for(NSDictionary* scannedObject in scannedObjects) {
		NSString* tag = scannedObject[@"tag"];

		if(!quantity && [tag isEqualToString:@"quantity"]) {
			quantity = scannedObject;
			quantityRange = [[scannedObject objectForKey:@"range"] rangeValue];

			continue;
		}

		if(!unit && [tag isEqualToString:@"unit"]) {
			unit = scannedObject;

			NSRange unitRange = [[scannedObject objectForKey:@"range"] rangeValue];
			quantityRange = NSUnionRange(quantityRange, unitRange);

			continue;
		}

		if([tag isEqualToString:@"word"]) {
			NSRange range = [[scannedObject objectForKey:@"range"] rangeValue];

			if(groceryTitleRange.length == 0) {
				groceryTitleRange = range;
			} else {
				groceryTitleRange = NSUnionRange(groceryTitleRange, range);

				if(quantity && quantityRange.location > groceryTitleRange.location) {
					quantity = nil;
					unit = nil;

					groceryTitleRange = NSUnionRange(groceryTitleRange, quantityRange);
				}
			}
		}
	}

	NSMutableDictionary* tags = [NSMutableDictionary dictionaryWithCapacity:3];

	BOOL hasQuantity = quantity != nil;
	BOOL quantityBeforeTitle = hasQuantity && quantityRange.location < groceryTitleRange.location;
	BOOL hasNotes = NO; // TODO:
	
	if(quantityBeforeTitle) {
		groceryTitleRange.length = string.length - groceryTitleRange.location;
	}
	
	if(groceryTitleRange.length == 0 || (!hasQuantity && !hasNotes)) {
		groceryTitleRange = NSMakeRange(0, [string length]);
		quantity = unit = nil;
	}

	NSString* groceryTitle = [string substringWithRange:groceryTitleRange];

	tags[@"title"] = @{
		@"value": groceryTitle,
		@"range": [NSValue valueWithRange:groceryTitleRange] };

	if(quantity) {
		NSMutableDictionary* quantityTag = [NSMutableDictionary dictionaryWithCapacity:3];
		
		[quantityTag setObject:quantity[@"value"] forKey:@"value"];
		[quantityTag setObject:quantity[@"range"] forKey:@"range"];
		
		if(unit) {
			[quantityTag setObject:unit[@"value"] forKey:@"unit"];
			
			NSRange quantityUnitRange = NSUnionRange(
				[quantity[@"range"] rangeValue],
				[unit[@"range"] rangeValue]);
			[quantityTag setObject:[NSValue valueWithRange:quantityUnitRange] forKey:@"range"];
		}
		
		tags[@"quantity"] = quantityTag;
	}

//	if(unit) {
//		tags[@"unit"] = @{
//			@"value": unit[@"value"],
//			@"range": unit[@"range"] };
//	}

	GRCDetectorValue* detectorValue = [[GRCDetectorValue alloc]
		initWithString:string
		tags:tags
		locale:[self locale]];

	return detectorValue;
}

#pragma mark - Private

- (NSArray*)scanObjects:(NSString*)string {
	__block NSMutableArray* scannedObjects = [NSMutableArray arrayWithCapacity:3];

	__block BOOL scannedQuantity = NO;
	__block BOOL scannedAtLeastOneWord = NO;

	NSRegularExpression* tokenizer = [[self class] sharedTokenizer];
	NSRange range = NSMakeRange(0, [string length]);

	NSMutableArray* tokens = [NSMutableArray array];

	[tokenizer enumerateMatchesInString:string options:0 range:range usingBlock:^(NSTextCheckingResult* match, NSMatchingFlags flags, BOOL* stop) {
		NSRange substringRange = [match range];
		NSString* substring = [string substringWithRange:substringRange];

		[tokens addObject:@{
			@"substring": substring,
			@"substringRange": [NSValue valueWithRange:substringRange] }];
	}];

	[tokens enumerateObjectsUsingBlock:^(NSDictionary* token, NSUInteger index, BOOL* stop) {
		NSRange substringRange = [[token objectForKey:@"substringRange"] rangeValue];
		NSString* substring = [token objectForKey:@"substring"];

		BOOL isLastToken = index + 1 >= tokens.count;

		// quantities
		if(!scannedQuantity) {
			NSArray* scannedQuantities = [self scanQuantity:substring ofRange:substringRange];
		
			if(scannedQuantities.count > 0) {
				[scannedObjects addObjectsFromArray:scannedQuantities];
				scannedQuantity = YES;

				return;
			}
		}
		
		// units
		if(!(isLastToken && !scannedAtLeastOneWord) && [[[scannedObjects lastObject] objectForKey:@"tag"] isEqualToString:@"quantity"]) { // last scan was a quantity
			NSArray* scannedUnits = [self scanUnit:substring ofRange:substringRange];
		
			if(scannedUnits.count > 0) {
				[scannedObjects addObjectsFromArray:scannedUnits];
				return;
			}
		}
		
		// grocery title
		NSArray* scannedWords = [self scanWord:substring ofRange:substringRange];
		
		if(scannedWords.count > 0) {
			scannedAtLeastOneWord = YES;
			[scannedObjects addObjectsFromArray:scannedWords];
			return;
		}
	}];

	return scannedObjects;
}

- (NSArray*)scanQuantity:(NSString*)substring ofRange:(NSRange)substringRange {
	NSNumber* value;
	NSRange quantityRange = NSMakeRange(0, [substring length]);
	
	if(![[self quantityFormatter] getObjectValue:&value forString:substring range:&quantityRange error:nil]) {
		return nil;
	}
	
	NSMutableArray* scannedObjects = [NSMutableArray array];
	
	[scannedObjects addObject:@{
		@"value": value,
		@"range": [NSValue valueWithRange:quantityRange],
		@"tag": @"quantity" }];

	NSRange unitRange = NSMakeRange(
		NSMaxRange(quantityRange),
		substringRange.length - NSMaxRange(quantityRange));
	
	if(unitRange.length > 0) {
		NSString* unitString = [substring substringWithRange:unitRange];
		NSArray* scannedUnits = [self scanUnit:unitString ofRange:unitRange];
		
		if(scannedUnits) {
			[scannedObjects addObjectsFromArray:scannedUnits];
		}
	}
	
	return scannedObjects;
}

- (NSArray*)scanUnit:(NSString*)substring ofRange:(NSRange)substringRange {
	GRCUnit* unit = [self unitForSearchString:substring];
	if(!unit) { return nil; }
	
	NSMutableArray* scannedObjects = [NSMutableArray array];
	
	[scannedObjects addObject:@{
		@"value": unit,
		@"range": [NSValue valueWithRange:substringRange],
		@"tag": @"unit"
	}];
		
	return scannedObjects;
}

- (NSArray*)scanWord:(NSString*)substring ofRange:(NSRange)substringRange {
	NSMutableArray* scannedObjects = [NSMutableArray array];
	
	[scannedObjects addObject:@{
		@"value": substring,
		@"range": [NSValue valueWithRange:substringRange],
		@"tag": @"word"
	}];
		
	return scannedObjects;
}

- (GRCUnit*)unitForSearchString:(NSString*)searchString {
	[self initUnitIndexIfNeeded];

	NSDictionary* unitIndex = self.unitIndex;

	// look for exact matches
	GRCUnit* unit = [unitIndex objectForKey:searchString];
	if(unit) { return unit; }

	// look for "begins with" matches
	for(NSString* key in unitIndex) {
		NSRange range = [key
			rangeOfString:searchString
			options:NSCaseInsensitiveSearch|NSAnchoredSearch|NSDiacriticInsensitiveSearch
			range:NSMakeRange(0, key.length)
			locale:[self locale]];

		if(range.location != NSNotFound) {
			return [unitIndex objectForKey:key];
		}
	}

	return nil;
}

- (void)initUnitIndexIfNeeded {
	if(self.unitIndex) { return; }

	NSArray* units = self.units;
	NSMutableDictionary* unitIndex = [NSMutableDictionary dictionaryWithCapacity:[units count] * 3];

	for(GRCUnit* unit in units) {
		NSSet* possibleStrings = [GRCUnitFormatter possibleStringsForUnit:unit locale:[self locale]];
		for(NSString* string in possibleStrings) { [unitIndex setObject:unit forKey:string]; }
	}

	self.unitIndex = unitIndex;
}

+ (NSRegularExpression*)sharedTokenizer {
	static NSRegularExpression* _groceries_sharedTokenizer = nil;
    static dispatch_once_t _groceries_sharedTokenizerOnce;

    dispatch_once(&_groceries_sharedTokenizerOnce, ^{
		_groceries_sharedTokenizer = [NSRegularExpression
			regularExpressionWithPattern:@"(\\\"[^\\\"]+\\\"|'[^']+')|([^\\s]+)"
			options:0
			error:nil];
    });

	return _groceries_sharedTokenizer;
}

@end
