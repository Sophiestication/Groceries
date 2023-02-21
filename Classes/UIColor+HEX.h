//
//  UIColor+HEX.h
//  SophiestiKit
//
//  Created by Sophia Teutschler on 08.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor(HEX)

+ (UIColor*)colorWithHexadecimalString:(NSString*)hexadecimalString;
- (NSString*)hexadecimalString;

@end