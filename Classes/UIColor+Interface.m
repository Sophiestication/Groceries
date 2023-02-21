//
//  UIColor+Interface.m
//  Xtrail
//
//  Created by Sophia Teutschler on 08.01.12.
//  Copyright (c) 2012 Sophiestication Software. All rights reserved.
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
	static UIColor* blueTableViewCellTextColor_;

    if(!blueTableViewCellTextColor_) {
        blueTableViewCellTextColor_ = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.00];
    }

    return blueTableViewCellTextColor_;
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