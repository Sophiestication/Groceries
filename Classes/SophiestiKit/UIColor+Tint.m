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
