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

#import "GRCTextStrokeRenderer.h"

#import "SUIImageCache.h"

#import "UIImage+Styles.h"
#import "UIColor+Tint.h"

@interface GRCTextStrokeRenderer()
@end

@implementation GRCTextStrokeRenderer

#pragma mark - GRCTextStrokeRenderer

+ (UIImage*)textStrokeImage {
	CGFloat scale = [[UIScreen mainScreen] scale];
	
	NSString* cacheKey = [NSString stringWithFormat:@"GRCTextStrokeImage@%0.0fx", scale];
	NSCache* cache = SUIGetImageCache();
	
	UIImage* image = [cache objectForKey:cacheKey];
	if(image) { return image; }
	
	GRCTextStrokeRenderer* renderer = [[self alloc] init];
	image = [renderer renderedImage];
	
	NSUInteger imageCost = image.size.width * image.size.height * image.scale * 4.0; // accurate enough for caching purpose
	[cache setObject:image forKey:cacheKey cost:imageCost];
	
	return image;
}

- (UIImage*)renderedImage {
	UIImage* image = nil;
	
	CGSize imageSize = CGSizeMake(4.0, 3.0);
	CGFloat imageScale = 0.0;
	
	UIGraphicsBeginImageContextWithOptions(imageSize, NO, imageScale); {
//		UIColor* fillColor = [[UIColor redTintColor] colorWithAlphaComponent:0.75];
//		[fillColor set];

		CGRect rect = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
	
		UIBezierPath* path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:4.0];
		[path fill];
		
		image = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	image = [image
		resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 1.0, 0.0, 1.0)
		resizingMode:UIImageResizingModeStretch];

	image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	return image;
}

@end
