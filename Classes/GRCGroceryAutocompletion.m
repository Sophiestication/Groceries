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

#import "GRCGroceryAutocompletion.h"

#import "GRCDefaultStore.h"
#import "GRCGroceryStore.h"
#import "GRCDetector.h"
#import "GRCGrocery.h"
#import "GRCUnit.h"

#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"
#import "NSString+Additions.h"

@interface GRCGroceryAutocompletion()

@property(nonatomic, strong) NSOperationQueue* operationQueue;
@property(nonatomic) NSUInteger numberOfRunningOperations;

@property(nonatomic, copy) NSString* autocompletionString;

@property(strong) GRCGroceryStore* groceryStore;
@property(strong) GRCDetector* detector;

@end

@implementation GRCGroceryAutocompletion

@dynamic running;

#pragma mark - GRCGroceryAutocompletion

- (BOOL)isRunning {
	return self.numberOfRunningOperations > 0;
}

- (void)autocompleteForString:(NSString*)string scope:(GRCGroceryAutocompletionScope)scope completion:(void (^)(GRCDetectorValue* detectorValue, NSArray* items, NSError* error))completion {
	// if([[self autocompletionString] isEqualToString:string]) { return; }
	
	self.autocompletionString = string;
	
	[self initDispatchQueueIfNeeded];
	++self.numberOfRunningOperations;
	
	[[self operationQueue] addOperationWithBlock:^() {
		[self initGroceryStoreIfNeeded];
		[self initDetectorIfNeeded];

		NSError* error = nil;

		GRCDetectorValue* value = [self detectorValueForString:string error:&error];
		NSArray* items = [self fetchItemsForDetectorValue:value scope:scope error:&error];

		if(error) {
			NSLog(@"Could not autocomplete string %@: %@", string, error);
		}
		
		dispatch_async(dispatch_get_main_queue(), ^() {
			--self.numberOfRunningOperations;

			if(![string isEqualToString:[self autocompletionString]]) { return; }
			completion(value, items, error);
		});
	}];
}

#pragma mark - Private

NSString* const GRCGroceryAutocompletionStoreKey = @"GRCGroceryAutocompletionStore";
NSString* const GRCGroceryAutocompletionDataDetectorKey = @"GRCGroceryAutocompletionDataDetector";

- (void)initDispatchQueueIfNeeded {
	if(self.operationQueue) { return; }

	NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];
		
	[operationQueue setMaxConcurrentOperationCount:1];
	[operationQueue setName:@"com.sophiestication.groceries.autocompletion"];
	
	self.operationQueue = operationQueue;
	self.numberOfRunningOperations = 0;
}

- (void)initGroceryStoreIfNeeded {
	if(self.groceryStore) { return; }
	self.groceryStore = [[GRCGroceryStore alloc] initWithSQLiteStore:GRCNewDefaultStore()];
}

- (void)initDetectorIfNeeded {
	if(!self.detector) {
		self.detector = [[GRCDetector alloc] init];
	}

	// always use the latest units and locale
	self.detector.units = self.units;
	self.detector.locale = self.locale;
}

- (GRCDetectorValue*)detectorValueForString:(NSString*)string error:(NSError* __autoreleasing *)error {
	GRCDetectorValue* value = [[self detector] detectInString:string error:error];
	return value;
}

- (NSArray*)fetchItemsForDetectorValue:(GRCDetectorValue*)value scope:(GRCGroceryAutocompletionScope)scope error:(NSError* __autoreleasing *)error {
	NSSet* searchStrings = [self autocompletionStringsForString:[value groceryTitle]];
	NSLocale* locale = self.locale;
	
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:15];
	
	if(scope & GRCGroceryAutocompletionScopeGenerics) {
		NSArray* results = [[[self groceryStore]
			autocompleteWithStrings:searchStrings
			scope:GRCGroceryStoreAutocompletionScopeGenerics
			locale:locale
			error:error] allObjects];
		if(results.count > 0) { [items addObjectsFromArray:results]; }
	}
	
	if(scope & GRCGroceryAutocompletionScopeBrands) {
		NSArray* results = [[[self groceryStore]
			autocompleteWithStrings:searchStrings
			scope:GRCGroceryStoreAutocompletionScopeBrands
			locale:locale
			error:error] allObjects];
		if(results.count > 0) { [items addObjectsFromArray:results]; }
	}

	if(items.count == 0) { return nil; }

	// add quantity and unit from the data detector
	for(GRCGrocery* grocery in items) {
		if(value.quantity) {
			grocery.quantity = value.quantity;
			grocery.unit = [self defaultUnitFromUnitsInArray:[self units]];
		}

		if(value.unit) {
			grocery.unit = value.unit;
		}
	}
	
	return items;
}

- (NSSet*)autocompletionStringsForString:(NSString*)string {
	if(string.length == 0) { return [NSSet set]; }

	NSCharacterSet* whitespaceCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSArray* tokens = [string componentsSeparatedByCharactersInSet:whitespaceCharacters];

	return [NSSet setWithArray:tokens];
}

- (GRCUnit*)defaultUnitFromUnitsInArray:(NSArray*)array {
	for(GRCUnit* unit in self.units) {
		if(unit.unitDatabaseIdentifier == GRCDefaultUnitDatabaseIdentifier) {
			return unit;
		}
	}

	return nil;
}

- (NSArray*)guessItemsForDetectorValue:(GRCDetectorValue*)value scope:(GRCGroceryAutocompletionScope)scope error:(NSError* __autoreleasing *)error {
	NSString* groceryTitle = value.groceryTitle;
	
	__block UITextChecker* checker = [[UITextChecker alloc] init];
	NSString* language = [[self locale] preferredLanguageCode];
	
	__block NSMutableArray* replacementStrings = [NSMutableArray array];
	
	id block = ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
		NSArray* completions = [checker
			completionsForPartialWordRange:NSMakeRange(0, [substring length])
			inString:substring
			language:language];
		
		NSString* completionString = [completions firstObject];
		if(!completionString) { return; }
			
		[replacementStrings addObject:@{
			@"string": completionString,
			@"range": [NSValue valueWithRange:substringRange] }];
	};
	
	[groceryTitle
		enumerateSubstringsInRange:NSMakeRange(0, [groceryTitle length])
		options:NSStringEnumerationByWords|NSStringEnumerationLocalized
		usingBlock:block];
	
	return nil;
}

- (NSArray*)spellCheckGuessItemsForDetectorValue:(GRCDetectorValue*)value scope:(GRCGroceryAutocompletionScope)scope error:(NSError* __autoreleasing *)error {
	NSString* groceryTitle = value.groceryTitle;
	
	__block UITextChecker* checker = [[UITextChecker alloc] init];
	NSString* language = [[self locale] preferredLanguageCode];
	
	__block NSMutableArray* replacementStrings = [NSMutableArray array];
	
	id block = ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
		NSRange range = [checker
			rangeOfMisspelledWordInString:substring
			range:NSMakeRange(0, [substring length])
			startingAt:0
			wrap:NO
			language:language];
			
		if(range.location != NSNotFound) {
			NSArray* guesses = [checker guessesForWordRange:range inString:substring language:language];
			
			NSString* guessString = [guesses firstObject];
			if(!guessString) { return; }
			
			[replacementStrings addObject:@{
				@"string": guessString,
				@"range": [NSValue valueWithRange:range] }];
		}
	};
	
	[groceryTitle
		enumerateSubstringsInRange:NSMakeRange(0, [groceryTitle length])
		options:NSStringEnumerationByWords|NSStringEnumerationLocalized
		usingBlock:block];
		
	NSLog(@"%@", replacementStrings);
	
	return nil;
}

@end
