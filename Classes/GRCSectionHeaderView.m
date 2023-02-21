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

#import "GRCSectionHeaderView.h"
#import "UIColor+Components.h"

@interface GRCSectionHeaderView()

@property(nonatomic, readwrite, strong) UIImageView* imageView;
@property(nonatomic, strong) UIView* topSeparatorView;
@property(nonatomic, strong) UIView* bottomSeparatorView;

@end

@implementation GRCSectionHeaderView

#pragma mark - Construction & Destruction

- (id)initWithReuseIdentifier:(NSString*)reuseIdentifier {
    if((self = [super initWithReuseIdentifier:reuseIdentifier])) {
		[self initContentView];
		[self initImageView];
		[self initSeparatorViews];
	}

    return self;
}

#pragma mark - GRCSectionHeaderView

+ (CGFloat)preferredHeight {
	return 25.0;
}

#pragma mark - UIView

- (void)tintColorDidChange {
	[super tintColorDidChange];

	self.imageView.tintColor = self.tintColor;
	self.textLabel.textColor = self.imageView.tintColor; // returns an adjusted tint color if needed

//	UIColor* backgroundTintColor = self.tintAdjustmentMode == UIViewTintAdjustmentModeNormal ?
//		self.backgroundTintColor : nil;
//	self.contentView.backgroundColor = backgroundTintColor;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGRect bounds = self.bounds;
	
	// separators
	CGRect topSeparatorViewRect = bounds;
	topSeparatorViewRect.size.height = 0.5;
	self.topSeparatorView.frame = CGRectOffset(topSeparatorViewRect, 0.0, -0.5);

	CGRect bottomSeparatorViewRect = CGRectOffset(bounds, 0.0, CGRectGetHeight(bounds) - 0.5);
	bottomSeparatorViewRect.size.height = CGRectGetHeight(topSeparatorViewRect);
	self.bottomSeparatorView.frame = bottomSeparatorViewRect;
	
	CGRect contentRect = self.contentView.bounds;
	
	// image
	CGSize imageSize = CGSizeMake(18.0, 18.0);
	CGRect imageViewRect = CGRectMake(
		CGRectGetMinX(contentRect) + 11.0,
		round(CGRectGetMidY(contentRect) - imageSize.height * 0.5),
		imageSize.width,
		imageSize.height);
	self.imageView.frame = imageViewRect;
	
	// text label
	CGRect textLabelRect = self.textLabel.frame;
	textLabelRect = CGRectOffset(textLabelRect, imageSize.width, 0.0);
//	textLabelRect = CGRectOffset(textLabelRect, -3.0, 0.0); // cosmetic
	
	CGFloat maxX = CGRectGetWidth(contentRect) - 10.0;
	if(maxX > 0.0 && CGRectGetMaxX(textLabelRect) > maxX) {
		textLabelRect.size.width = maxX - CGRectGetMinX(textLabelRect);
	}
	
	self.textLabel.frame = textLabelRect;

	self.imageView.tintColor = self.tintColor;
	self.textLabel.textColor = self.imageView.tintColor; // returns an adjusted tint color if needed
}

#pragma mark - Private

- (void)initContentView {
	self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.97];
}

- (void)initImageView {
	UIImageView* imageView = [[UIImageView alloc] initWithImage:nil];
	self.imageView = imageView;
	[[self contentView] insertSubview:imageView belowSubview:[self textLabel]];
}

- (void)initSeparatorViews {
	UIView* topSeparatorView = [[UIView alloc] initWithFrame:CGRectZero];
	self.topSeparatorView = topSeparatorView;
	[self insertSubview:topSeparatorView aboveSubview:[self contentView]];

	UIView* bottomSeparatorView = [[UIView alloc] initWithFrame:CGRectZero];
	self.bottomSeparatorView = bottomSeparatorView;
	[self insertSubview:bottomSeparatorView aboveSubview:[self contentView]];

	topSeparatorView.backgroundColor = bottomSeparatorView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1.0];
}

@end
