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

#import "GRCBarcodeFormatter.h"

@implementation GRCBarcodeFormatter

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		self.barcodeStyle = [[self class]
			preferredBarcodeStyleForLocale:[NSLocale autoupdatingCurrentLocale]];
		self.groupingSeparator = @"-"; // dash
	}
	
	return self;
}

#pragma mark - GRCBarcodeFormatter

+ (GRCBarcodeFormatterStyle)preferredBarcodeStyleForLocale:(NSLocale*)locale {
	return GRCBarcodeFormatterStyleEAN13;
}

- (BOOL)getObjectValue:(out id*)obj forString:(NSString*)string range:(inout NSRange*)rangep error:(out NSError* __autoreleasing *)error {
	if([self getObjectValue:obj forString:string errorDescription:nil]) {
		if(rangep) { *rangep = NSMakeRange(0, [string length]); }
		return YES;
	}
	
	return NO;
}

#pragma mark - NSFormatter

- (NSString*)stringForObjectValue:(id)object {
	NSArray* separatorIndexes;
	NSString* separator = self.groupingSeparator;
	
	if(self.barcodeStyle == GRCBarcodeFormatterStyleISBN13) {
		separatorIndexes = @[ @(3), @(4), @(6), @(12) ];
	}
	
	if(self.barcodeStyle == GRCBarcodeFormatterStyleISBN10) {
		separatorIndexes = @[ @(9) ];
	}
	
	if(self.barcodeStyle == GRCBarcodeFormatterStyleEAN13) {
		separatorIndexes = @[ @(1), @(7), @(13) ];
	}
	
	if(self.barcodeStyle == GRCBarcodeFormatterStyleEAN8) {
		separatorIndexes = @[ @(4) ];
	}
	
	NSString* string = [self stringForObjectValue:object separatorIndexes:separatorIndexes separator:separator];
	return string;
}

- (BOOL)getObjectValue:(out id*)obj forString:(NSString*)string errorDescription:(out NSString**)error {
	NSCharacterSet* noneDecimalDigits = [NSCharacterSet decimalDigitCharacterSet];
	noneDecimalDigits = [noneDecimalDigits invertedSet];
	
	NSArray* digits = [string componentsSeparatedByCharactersInSet:noneDecimalDigits];
	NSString* digitString = [digits componentsJoinedByString:@""];
	
	/* NSNumber* value = [NSDecimalNumber decimalNumberWithString:digitString];
	
	if(![value isEqualToNumber:[NSDecimalNumber notANumber]]) {
		if(obj) { *obj = value; }
	} */
	
	if(digitString.length > [[self class] maximumBarcodeLength]) {
		return NO;
	}
	
	if(obj) { *obj = digitString; }
	
	return YES;
}

#pragma mark - Private

+ (NSUInteger)maximumBarcodeLength { return 19; }

- (NSString*)stringForObjectValue:(id)object separatorIndexes:(NSArray*)separatorIndexes separator:(NSString*)separator {
	if([object respondsToSelector:@selector(stringValue)]) {
		object = [object stringValue];
	}
	
	NSMutableString* string = [object mutableCopy]; // [[object stringValue] mutableCopy];
	
	NSInteger indexIndex = 0; // lolz
	
	for(NSNumber* indexValue in separatorIndexes) {
		NSInteger index = [indexValue integerValue];
		index += indexIndex * separator.length;
		
		if(index >= string.length) { break; }
		
		[string insertString:separator atIndex:index];
		++indexIndex;
	}
	
	return string;
}

@end
