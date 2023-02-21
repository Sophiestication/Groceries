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

#import "SUIStyledImageRenderer.h"

@implementation SUIStyledImageRenderer

#pragma mark - Construction & Destruction

#pragma mark - SUIStyledImageRenderer

- (UIImage*)renderedImage {
	UIImage* maskImage = self.maskImage;
	UIImage* image = nil;
	
	UIGraphicsBeginImageContextWithOptions([maskImage size], NO, [maskImage scale]); {
		CGContextRef context = UIGraphicsGetCurrentContext();
	
		[self renderInContext:context];

		image = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	return image;
}

- (void)renderInContext:(CGContextRef)context {
	// content rect
	CGSize imageSize = self.maskImage.size;
	CGRect contentRect = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
		
	// flip our context
	CGAffineTransform flipTransform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, CGRectGetHeight(contentRect));
	CGContextConcatCTM(context, flipTransform);
		
	// prepare our content mask image
	CGImageRef maskImage = [[self maskImage] CGImage];
	NSDictionary* imageStyles = self.imageStyles;
		
	// shadow
	UIColor* shadowColor = [imageStyles objectForKey:SUIImageStyleShadowColor];
	NSValue* shadowOffset = [imageStyles objectForKey:SUIImageStyleShadowOffset];
		
	if(shadowColor) {
		CGContextSaveGState(context); {
		
			[shadowColor set];
				
			CGPoint offset = shadowOffset ?
				[shadowOffset CGPointValue] :
				CGPointMake(0.0, -1.0);
			
			CGContextClipToMask(context, CGRectOffset(contentRect, offset.x, offset.y), maskImage);
				
			UIRectFill(contentRect);
		
		} CGContextRestoreGState(context);
	}
		
	// mask the following gradient or solid color fill
	CGContextClipToMask(context, contentRect, maskImage);
		
	// fill using gradient if needed
	UIColor* fillStartColor = [imageStyles objectForKey:SUIImageStyleFillStartColor];
	UIColor* fillEndColor = [imageStyles objectForKey:SUIImageStyleFillEndColor];
		
	if(fillStartColor && fillEndColor) {
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGFloat locations[2] = { 0.0, 1.0 };
    		
		// the context is flipped so switch start and end color
		NSArray* colors = [NSArray arrayWithObjects:
			(id)[fillEndColor CGColor],
			(id)[fillStartColor CGColor],
			nil];
				
		CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
		CGColorSpaceRelease(colorSpace);  // release owned Core Foundation object

		CGContextDrawLinearGradient(
			context,
			gradient,
			CGPointZero,
			CGPointMake(0.0, CGRectGetHeight(contentRect)),
			kCGGradientDrawsBeforeStartLocation|kCGGradientDrawsAfterEndLocation);
    		
		CGGradientRelease(gradient);  // release owned Core Foundation object
	} else { // solid fill color
		UIColor* solidFillColor = [imageStyles objectForKey:SUIImageStyleFillColor];
		
		if(solidFillColor) {
			[solidFillColor set];
		}
			
		UIRectFill(contentRect);
	}
}

@end
