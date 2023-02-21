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

#import "UIColor+HEX.h"

@implementation UIColor(HEX)

+ (UIColor*)colorWithHexadecimalString:(NSString*)hexadecimalString {
	NSString* string = [hexadecimalString stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	string = [string uppercaseString];

	if([string length] < 6) { return nil; }
	if ([string hasPrefix:@"0X"]) { string = [string substringFromIndex:2]; }
	if ([string hasPrefix:@"#"]) { string = [string substringFromIndex:1]; }
	if ([string length] != 6) { return nil; }

	// Separate into r, g, b substrings
	NSRange range = NSMakeRange(0, 2);
	
	NSString* redString = [string substringWithRange:range];

	range.location = 2;
	NSString* greenString = [string substringWithRange:range];

	range.location = 4;
	NSString* blueString = [string substringWithRange:range];

	// Scan values
	unsigned int r, g, b;
	[[NSScanner scannerWithString:redString] scanHexInt:&r];
	[[NSScanner scannerWithString:greenString] scanHexInt:&g];
	[[NSScanner scannerWithString:blueString] scanHexInt:&b];

	return [UIColor
		colorWithRed:((CGFloat) r / 255.0)
		green:((CGFloat) g / 255.0)
		blue:((CGFloat) b / 255.0)
		alpha:1.0];
}

- (NSString*)hexadecimalString {
	CGFloat red, green, blue, alpha;
	
	if(![self getRed:&red green:&green blue:&blue alpha:&alpha]) {
		return 0;
	}
	
	UInt32 hexValue = (((int)roundf(red * 255.0)) << 16)
	     | (((int)roundf(green * 255.0)) << 8)
	     | (((int)roundf(blue * 255.0)));
		 
	return [NSString stringWithFormat:@"#%0.6X", (unsigned int)hexValue];
}

@end
