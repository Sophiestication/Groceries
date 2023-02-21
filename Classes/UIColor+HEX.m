//
//  UIColor+HEX.m
//  SophiestiKit
//
//  Created by Sophia Teutschler on 08.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
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
		 
	return [NSString stringWithFormat:@"#%0.6lX", hexValue];
}

@end