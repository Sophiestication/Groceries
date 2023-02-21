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

#import "UIImage+PDF.h"

#import "SUIPDFImageRenderer.h"
#import "SUIImageCache.h"
#import "SUIImageStyles.h"
#import "UIImage+Styles.h"

@implementation UIImage (PDF)

+ (UIImage*)PDFImageNamed:(NSString*)imageName size:(CGSize)size scale:(CGFloat)scale {
	return [self PDFImageNamed:imageName size:size scale:scale style:nil];
}

+ (UIImage*)PDFImageNamed:(NSString*)imageName size:(CGSize)size scale:(CGFloat)scale style:(NSString*)styleName {
	// use the main screen scale if necessary
	if(scale <= 0) {
		scale = [[UIScreen mainScreen] scale];
	}
	
	// render and cache
	NSString* imageCacheName = [imageName stringByAppendingFormat:@"-%0.0f,%0.0f@%0.0fx", size.width, size.height, scale];
	
	UIImage* image = nil;
	NSString* styledImageCacheName = nil;

	if(styleName) {
		styledImageCacheName = [imageCacheName stringByAppendingFormat:@"-%@", styleName];

		image = [SUIGetImageCache() objectForKey:styledImageCacheName];
		if(image) { return image; } 
	}
	
	image = [SUIGetImageCache() objectForKey:imageCacheName];
	if(image && !styleName) { return image; }
	
	NSURL* imageURL = [[NSBundle mainBundle] URLForResource:imageName withExtension:@"pdf"];
	if(!imageURL) { return nil; }
	
	SUIPDFImageRenderer* renderer = [[SUIPDFImageRenderer alloc] initWithContentsOfURL:imageURL];
	
	renderer.size = size;
	renderer.scale = MAX(scale, 1);
	
	image = [renderer renderedImage];

	if(image) {
		NSUInteger imageCost = image.size.width * image.size.height * image.scale * 4.0; // accurate enough for caching purpose
		[SUIGetImageCache() setObject:image forKey:imageCacheName cost:imageCost];
		
//		NSString* dumpPath = [[[@"~" stringByExpandingTildeInPath] stringByAppendingPathComponent:imageCacheName] stringByAppendingPathExtension:@"png"];
//		[UIImagePNGRepresentation(image) writeToFile:dumpPath atomically:YES];
//		NSLog(@"%@", dumpPath);
	}
	
	if(styleName) {
		NSDictionary* imageStyles = [SUIGetImageStyles() objectForKey:styleName];
		if(!imageStyles) { return image; }
		
		image = [image imageByApplyingStyles:imageStyles];
		
		if(image) {
			NSUInteger imageCost = image.size.width * image.size.height * image.scale * 4.0; // accurate enough for caching purpose
			[SUIGetImageCache() setObject:image forKey:styledImageCacheName cost:imageCost];
			
//			NSString* dumpPath = [[[@"~" stringByExpandingTildeInPath] stringByAppendingPathComponent:styledImageCacheName] stringByAppendingPathExtension:@"png"];
//			[UIImagePNGRepresentation(image) writeToFile:dumpPath atomically:YES];
//			NSLog(@"%@", dumpPath);
		}
	}

	return image;
}

@end
