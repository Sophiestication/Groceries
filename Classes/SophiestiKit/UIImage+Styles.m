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

#import "UIImage+Styles.h"

#import "SUIStyledImageRenderer.h"
#import "SUIImageCache.h"
#import	"SUIImageStyles.h"

#import "UIImage+PDF.h"

NSString* const SUIGroupedTableViewHeaderImageStyle = @"SUIGroupedTableViewHeaderImageStyle";
NSString* const SUITableViewCellImageStyle = @"SUITableViewCellImageStyle";
NSString* const SUITableViewCellDarkImageStyle = @"SUITableViewCellDarkImageStyle";
NSString* const SUITableViewCellSelectedImageStyle = @"SUITableViewCellSelectedImageStyle";
NSString* const SUITableViewCellGrayImageStyle = @"SUITableViewCellGrayImageStyle";
NSString* const SUITableViewCellBlueImageStyle = @"SUITableViewCellBlueImageStyle";

NSString* const SUIToolbarItemImageStyle = @"SUIToolbarItemImageStyle";

NSString* const SUIImageStyleFillColor = @"SUIImageStyleFillColor";

NSString* const SUIImageStyleShadowColor = @"SUIImageStyleShadowColor";
NSString* const SUIImageStyleShadowOffset = @"SUIImageStyleShadowOffset";

NSString* const SUIImageStyleFillStartColor = @"SUIImageStyleFillStartColor";
NSString* const SUIImageStyleFillEndColor = @"SUIImageStyleFillEndColor";

@implementation UIImage(Styles)

+ (UIImage*)imageNamed:(NSString*)imageName style:(NSString*)styleName {
	if(styleName.length == 0) { // always use a template image if there's no style specified
		return [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	}
	
	NSString* cacheKey = [[imageName stringByAppendingString:@"-"] stringByAppendingString:styleName];
	NSCache* cache = SUIGetImageCache();
	
	UIImage* styledImage = [cache objectForKey:cacheKey];
	
	if(!styledImage) {
		NSDictionary* styles = [SUIGetImageStyles() objectForKey:styleName];
		UIImage* image = [UIImage imageNamed:imageName];
		
		if(styles) {
			image = [image imageByApplyingStyles:styles];
			
			if(image) {
				NSUInteger imageCost = image.size.width * image.size.height * image.scale * 4.0; // accurate enough for caching purpose
				[cache setObject:image forKey:cacheKey cost:imageCost];
			}
		}
		
		styledImage = image;
	}
	
	return styledImage;
}

- (UIImage*)imageByApplyingStyles:(NSDictionary*)imageStyles {
	SUIStyledImageRenderer* renderer = [[SUIStyledImageRenderer alloc] init];
	
	renderer.maskImage = self;
	renderer.imageStyles = imageStyles;
	
	return [renderer renderedImage];
}

+ (void)registerImageStyle:(NSDictionary*)imageStyle forKey:(NSString*)styleKey {
	[SUIGetImageStyles() setObject:imageStyle forKey:styleKey];
}

+ (void)unregisterImageStyleForKey:(NSString*)styleKey {
	[SUIGetImageStyles() removeObjectForKey:styleKey];
}

@end
