//
//  UIColor+Tint.m
//  SophiestiKit
//
//  Created by Sophia Teutschler on 06.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
//

#import "UIColor+Tint.h"

@implementation UIColor(Tint)

+ (UIColor*)redTintColor {
	static UIColor* redTintColor_;

    if(!redTintColor_) {
        redTintColor_ = [UIColor colorWithRed:0.718 green:0.153 blue:0.243 alpha:1.000];
    }

    return redTintColor_;
}

+ (UIColor*)orangeTintColor {
	static UIColor* orangeTintColor_;

    if(!orangeTintColor_) {
        orangeTintColor_ = [UIColor colorWithRed:0.980 green:0.435 blue:0.106 alpha:1.000];
    }

    return orangeTintColor_;
}

+ (UIColor*)yellowTintColor {
	static UIColor* yellowTintColor_;

    if(!yellowTintColor_) {
        yellowTintColor_ = [UIColor colorWithRed:0.894 green:0.812 blue:0.247 alpha:1.000];
    }

    return yellowTintColor_;
}

+ (UIColor*)greenTintColor {
	static UIColor* greenTintColor_;

    if(!greenTintColor_) {
        greenTintColor_ = [UIColor colorWithRed:0.502 green:0.769 blue:0.322 alpha:1.000];
    }

    return greenTintColor_;
}

+ (UIColor*)blueTintColor {
	static UIColor* blueTintColor_;

    if(!blueTintColor_) {
        blueTintColor_ = [UIColor colorWithRed:0.294 green:0.541 blue:1.000 alpha:1.000];
    }

    return blueTintColor_;
}

+ (UIColor*)purpleTintColor {
	static UIColor* purpleTintColor_;

    if(!purpleTintColor_) {
        purpleTintColor_ = [UIColor colorWithRed:0.675 green:0.396 blue:0.702 alpha:1.000];
    }

    return purpleTintColor_;
}

+ (UIColor*)brownTintColor {
	static UIColor* brownTintColor_;

    if(!brownTintColor_) {
        brownTintColor_ = [UIColor colorWithRed:0.765 green:0.486 blue:0.337 alpha:1.000];
    }

    return brownTintColor_;
}

@end