//
//  UIColor+Components.h
//  SophiestiKit
//
//  Created by Sophia Teutschler on 08.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor(Components)

- (UIColor*)colorByAddingRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;
- (UIColor*)colorByAddingHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness;

@end