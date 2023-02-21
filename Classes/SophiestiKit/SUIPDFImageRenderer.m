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

#import "SUIPDFImageRenderer.h"

@implementation SUIPDFImageRenderer

#pragma mark - Construction & Destruction

- (id)initWithContentsOfURL:(NSURL*)URL {
	if((self = [super init])) {
		self.URL = URL;

		self.size = CGSizeZero;
		self.scale = 1.0;
	}
	
	return self;
}

#pragma mark - SUIPDFImageRenderer

- (UIImage*)renderedImage {
	UIImage* image = nil;

	UIGraphicsBeginImageContextWithOptions([self size], NO, [self scale]); {
		CGContextRef context = UIGraphicsGetCurrentContext();
	
		[self renderInContext:context];

		image = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();
	
	return image;
}

- (void)renderInContext:(CGContextRef)context {
	// flip our context
	CGContextGetCTM(context);
	CGContextScaleCTM(context, 1, -1);
	CGContextTranslateCTM(context, 0, -self.size.height);
	
	// create a new PDF document
	CGPDFDocumentRef document = CGPDFDocumentCreateWithURL((__bridge CFURLRef)[self URL]);
	
	NSAssert1(document != NULL, @"Could not open PDF document: %@", [self URL]);
	NSAssert1(CGPDFDocumentGetNumberOfPages(document) >= 1, @"PDF document is empty: %@", [self URL]);
	
	CGPDFPageRef firstPage = CGPDFDocumentGetPage(document, 1);
	
	// get the rectangle of the cropped inside
	CGRect contentRect = CGPDFPageGetBoxRect(firstPage, kCGPDFCropBox);
	
	CGFloat scaleX = self.size.width / CGRectGetWidth(contentRect);
	CGFloat scaleY = self.size.height / CGRectGetHeight(contentRect);
	
	CGContextScaleCTM(context, scaleX, scaleY);
	CGContextTranslateCTM(context, -CGRectGetMinX(contentRect), -CGRectGetMinY(contentRect));
 
	// render
	CGContextDrawPDFPage(context, firstPage);
	CGPDFDocumentRelease(document);
}

@end
