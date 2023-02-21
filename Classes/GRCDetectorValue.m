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

#import "GRCDetectorValue.h"
#import "GRCDetectorValue+Private.h"

#import "GRCUnit.h"
#import "GRCUnitFormatter.h"

@implementation GRCDetectorValue

@dynamic groceryTitle;
@dynamic notes;
@dynamic quantity;
@dynamic unit;

#pragma mark - Construction & Destruction

- (id)initWithString:(NSString*)string tags:(NSDictionary*)tags locale:(NSLocale*)locale {
	if((self = [super init])) {
		self.string = string;
		self.tags = [tags mutableCopy];
		self.locale = locale;
	}

	return self;
}

#pragma mark - NSObject

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {string = %@, tags = %@}",
		[super description],
		[self string],
		[self tags]];
}

#pragma mark - GRCDetectorValue

- (NSString*)groceryTitle {
	return self.tags[@"title"][@"value"];
}

- (void)setGroceryTitle:(NSString*)groceryTitle {
	if(!groceryTitle) { groceryTitle = @""; }

	NSDictionary* tag = self.tags[@"title"];
	if([groceryTitle isEqual:[tag objectForKey:@"value"]]) { return; }

	NSRange range = [[tag objectForKey:@"range"] rangeValue];
	NSRange newRange = NSMakeRange(range.location, groceryTitle.length);

	NSDictionary* newTag = @{
		@"value": groceryTitle,
		@"range": [NSValue valueWithRange:newRange] };
	self.tags[@"title"] = newTag;

	NSInteger shift = newRange.length - range.length;
	[self shiftRangesAfterLocation:range.location by:shift];

	[self updateStringWithSubstring:groceryTitle range:range];
}

- (NSString*)notes {
	return self.tags[@"notes"][@"value"];
}

- (NSNumber*)quantity {
	return self.tags[@"quantity"][@"value"];
}

- (GRCUnit*)unit {
	return self.tags[@"quantity"][@"unit"];
}

- (void)setQuantity:(NSNumber*)quantity unit:(GRCUnit*)unit {
	if([quantity isEqual:[self quantity]] && [unit isEqual:[self unit]]) { return; }
	
	// format the quantity and unit into a string
	NSString* newQuantityString;

	if(quantity) {
		GRCUnitFormatter* formatter = [[GRCUnitFormatter alloc] initWithUnitStyle:GRCUnitFormatterStyleQuantity];
		
		formatter.quantity = quantity;
		newQuantityString = [formatter stringForUnit:unit];
	}
	
	NSDictionary* tag = self.tags[@"quantity"];
	
	NSRange range;
	NSRange newRange;
	
	if(tag) {
		range = [[tag objectForKey:@"range"] rangeValue];
	} else if(NO) { // TODO: 
		// insert a whitespace in front of the title
		NSRange titleRange = [self.tags[@"title"][@"range"] rangeValue];
		
		NSInteger location = titleRange.location <= 0 ?
			0 : titleRange.location - 1;
		[self shiftRangesAfterLocation:location - 1 by:1];
		
		NSMutableString* string = [[self string] mutableCopy];
		[string insertString:@" " atIndex:location];
		self.string = string;
		
		range = NSMakeRange(location, 0);
	} else {
		range = NSMakeRange(0, 0);
	}
	
	newRange = NSMakeRange(range.location, newQuantityString.length);
	
	if(quantity) {
		NSMutableDictionary* newTag = [NSMutableDictionary dictionaryWithCapacity:3];
		
		[newTag setObject:quantity forKey:@"value"];
		[newTag setObject:[NSValue valueWithRange:newRange] forKey:@"range"];
		
		if(unit) {
			[newTag setObject:unit forKey:@"unit"];
		}
	
		self.tags[@"quantity"] = newTag;
	} else {
		[[self tags] removeObjectForKey:@"quantity"];
	}
	
	// shift the following ranges
	NSInteger shift = newRange.length - range.length;
	[self shiftRangesAfterLocation:range.location by:shift];

	[self updateStringWithSubstring:newQuantityString range:range];
}

#pragma mark - Private

- (void)shiftRangesAfterLocation:(NSInteger)location by:(NSInteger)shift {
	NSMutableDictionary* tags = self.tags;
	NSArray* keys = [tags allKeys];

	for(NSString* key in keys) {
		NSDictionary* tag = tags[key];

		NSRange range = [[tag objectForKey:@"range"] rangeValue];
		if((NSInteger)range.location <= location) { continue; }

		range.location += shift;
		// range.length += shift;

		tags[key] = @{
			@"value": tag[@"value"],
			@"range": [NSValue valueWithRange:range] };
	}
}

- (void)updateStringWithSubstring:(NSString*)substring range:(NSRange)range {
	NSMutableString* newString = [[self string] mutableCopy];

	substring = substring ? substring : @"";
	[newString replaceCharactersInRange:range withString:substring];

	self.string = newString;
}

@end
