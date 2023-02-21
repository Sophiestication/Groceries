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

#import "GRCAisleFormatter.h"

#import "GRCAisle.h"

#import "NSBundle+Localization.h"
#import "NSLocale+Additions.h"

@implementation GRCAisleFormatter

#pragma mark - Construction & Destruction

- (id)init {
	return [self initWithAisleStyle:GRCAisleFormatterStyleTitle];
}

- (id)initWithAisleStyle:(GRCAisleFormatterStyle)aisleStyle {
	if((self = [super init])) {
		self.aisleStyle = aisleStyle;
		self.locale = [NSLocale localeWithPreferredLanguageCode];
	}

	return self;
}

#pragma mark - GRCAisleFormatter

- (NSString*)stringForAisle:(GRCAisle*)aisle {
	return [self stringForObjectValue:aisle];
}

#pragma mark - NSFormatter

- (NSString*)stringForObjectValue:(id)object {
	GRCAisle* aisle = object;

	// check for a custom title first
	NSString* customTitle = aisle.customTitle;
	if(customTitle.length > 0) { return customTitle; }

	// determine the title by looking up the aisle.strings file
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	NSLocale* locale = self.locale;

	NSString* aisleIdentifier = [aisle aisleIdentifier];

	NSString* string = [bundle localizedStringForKey:aisleIdentifier value:nil table:@"aisle" locale:locale];
	
	if([string isEqualToString:aisleIdentifier]) { return nil; }

	return string;
}

@end
