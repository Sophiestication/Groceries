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
