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

#import "UIColor+Interface.h"

@implementation UIColor(Interface)

+ (UIColor*)groupTableViewHeaderTextColor {
	static UIColor* groupTableViewHeaderTextColor_;

    if(!groupTableViewHeaderTextColor_) {
        groupTableViewHeaderTextColor_ = [UIColor colorWithRed:0.300 green:0.340 blue:0.420 alpha:1.000];
    }

    return groupTableViewHeaderTextColor_;
}

+ (UIColor*)tableViewCellTextColor {
	return [self darkTextColor];
}

+ (UIColor*)selectedTableViewCellTextColor {
	return [self whiteColor];
}

+ (UIColor*)grayTableViewCellTextColor {
	static UIColor* grayTableViewCellTextColor_;

    if(!grayTableViewCellTextColor_) {
        grayTableViewCellTextColor_ = [UIColor colorWithRed:0.50 green:0.50 blue:0.50 alpha:1.00];
    }

    return grayTableViewCellTextColor_;
}

+ (UIColor*)blueTableViewCellTextColor {
//	static UIColor* blueTableViewCellTextColor_;
//
//	if(!blueTableViewCellTextColor_) {
//		blueTableViewCellTextColor_ = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.00];
//	}
//
//	return blueTableViewCellTextColor_;
	return nil;
}

+ (UIColor*)blue2TableViewCellTextColor {
	static UIColor* blue2TableViewCellTextColor_;

    if(!blue2TableViewCellTextColor_) {
        blue2TableViewCellTextColor_ = [UIColor colorWithRed:0.16 green:0.43 blue:0.83 alpha:1.00];
    }

    return blue2TableViewCellTextColor_;
}

+ (UIColor*)tableViewCellSeparatorColor {
	static UIColor* tableViewCellSeparatorColor_;

    if(!tableViewCellSeparatorColor_) {
        tableViewCellSeparatorColor_ = [UIColor colorWithRed:0.880 green:0.880 blue:0.880 alpha:1.000];
    }

    return tableViewCellSeparatorColor_;
}

+ (UIColor*)selectedTableViewCellSeparatorColor {
	static UIColor* selectedTableViewCellSeparatorColor_;

    if(!selectedTableViewCellSeparatorColor_) {
        selectedTableViewCellSeparatorColor_ = [UIColor colorWithWhite:1.0 alpha:0.5];
    }

    return selectedTableViewCellSeparatorColor_;
}

+ (UIColor*)groupTableViewCellBackgroundColor {
	static UIColor* groupTableViewCellBackgroundColor_;

    if(!groupTableViewCellBackgroundColor_) {
        groupTableViewCellBackgroundColor_ = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.00];
    }

    return groupTableViewCellBackgroundColor_;
}

+ (UIColor*)groupdTableViewCellSeparatorColor {
	static UIColor* groupdTableViewCellSeparatorColor_;

    if(!groupdTableViewCellSeparatorColor_) {
        groupdTableViewCellSeparatorColor_ = [UIColor colorWithWhite:0.79 alpha:1.0]; // [UIColor colorWithWhite:0.0 alpha:0.18];
    }

    return groupdTableViewCellSeparatorColor_;
}

+ (UIColor*)groupdTableViewCellSeparatorHighlightColor {
	static UIColor* groupdTableViewCellSeparatorHighlightColor_;

    if(!groupdTableViewCellSeparatorHighlightColor_) {
        groupdTableViewCellSeparatorHighlightColor_ = [UIColor colorWithWhite:1.0 alpha:0.6];
    }

    return groupdTableViewCellSeparatorHighlightColor_;
}

@end
