//
//  UIColor+Components.m
//  SophiestiKit
//
//  Created by Sophia Teutschler on 08.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
//

#import "UIColor+Components.h"

@implementation UIColor(Components)

- (UIColor*)colorByAddingRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue {
	CGFloat redValue, greenValue, blueValue, alphaValue;
	
	if(![self getRed:&redValue green:&greenValue blue:&blueValue alpha:&alphaValue]) {
		return self;
	}
	
	redValue = MAX(MIN(redValue + red, 1.0), 0.0);
	greenValue = MAX(MIN(greenValue + green, 1.0), 0.0);
	blueValue = MAX(MIN(blueValue + blue, 1.0), 0.0);
	
	return [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:alphaValue];
}

- (UIColor*)colorByAddingHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness {
	CGFloat hueValue, saturationValue, brightnessValue, alphaValue;
	
	if(![self getHue:&hueValue saturation:&saturationValue brightness:&brightnessValue alpha:&alphaValue]) {
		return self;
	}
	
	hueValue = MAX(MIN(hueValue + hue, 1.0), 0.0);
	saturationValue = MAX(MIN(saturationValue + saturation, 1.0), 0.0);
	brightnessValue = MAX(MIN(brightnessValue + brightness, 1.0), 0.0);
	
	return [UIColor colorWithHue:hueValue saturation:saturationValue brightness:brightnessValue alpha:alphaValue];
}

@end