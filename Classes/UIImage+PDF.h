//
//  UIImage+PDF.h
//  Xtrail
//
//  Created by Sophia Teutschler on 06.03.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(PDF)

+ (UIImage*)PDFImageNamed:(NSString*)imageName size:(CGSize)size scale:(CGFloat)scale;
+ (UIImage*)PDFImageNamed:(NSString*)imageName size:(CGSize)size scale:(CGFloat)scale style:(NSString*)styleName;

@end
