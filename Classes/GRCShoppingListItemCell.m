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

#import "GRCShoppingListItemCell.h"
#import "GRCTextStrokeRenderer.h"

#import "UIColor+Interface.h"
#import "UIColor+Components.h"
#import "UIColor+Tint.h"

@interface GRCShoppingListItemCell()

@property(nonatomic, readwrite, strong) UILabel* quantityTextLabel;
@property(nonatomic, strong) UIImageView* textStrokeView;

@property(nonatomic, strong) UIView* separatorHighlightView;
@property(nonatomic, strong) UIView* backgroundBottomSeparatorView;

@property(nonatomic, strong) UIView* selectedBackgroundTopSeparatorView;
@property(nonatomic, strong) UIView* selectedBackgroundBottomSeparatorView;

@end

@implementation GRCShoppingListItemCell

#pragma mark - Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
		[self initQuantityTextLabel];
		[self initTextStrokeView];
//		[self initSelectedBackgroundView];
//		[self initBackgroundBottomSeparatorView];
//		[self initSeparatorHighlightView];

		self.backgroundColor = [UIColor clearColor];
	}

    return self;
}

#pragma mark - GRCShoppingListItemCell

- (void)setCompleted:(BOOL)completed {
	[self setCompleted:completed animated:NO];
}

- (void)setCompleted:(BOOL)completed animated:(BOOL)animated {
	if(self.completed == completed) { return; }
	
	_completed = completed;

	if(animated) {
		id animations = ^() {
			[self layoutTextStrokeView];
		};

		[UIView
			animateWithDuration:0.3
			animations:animations
			completion:nil];
	} else {
		[self setNeedsLayout];
	}
}

#pragma mark - UIView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	BOOL hasQuantity = self.quantityTextLabel.text.length > 0;

	self.quantityTextLabel.hidden = !hasQuantity;
	self.quantityTextLabel.font = self.textLabel.font;

	CGFloat const margin = 10.0;

	CGRect contentRect = self.contentView.bounds;

	CGSize quantityTextLabelSize = [[self quantityTextLabel]
		sizeThatFits:contentRect.size];
	CGRect quantityTextLabelRect = CGRectMake(
		CGRectGetMaxX(contentRect) - quantityTextLabelSize.width - margin,
		round(CGRectGetMidY(contentRect) - quantityTextLabelSize.height * 0.5),
		quantityTextLabelSize.width,
		quantityTextLabelSize.height);
	self.quantityTextLabel.frame = quantityTextLabelRect;
	
	CGRect textLabelRect = self.textLabel.frame;
	
	if(CGRectGetMaxX(textLabelRect) >= CGRectGetMinX(quantityTextLabelRect)) {
		textLabelRect.size.width = CGRectGetMinX(quantityTextLabelRect) - margin;
		self.textLabel.frame = textLabelRect;
	}
	
	CGRect detailTextLabelRect = self.detailTextLabel.frame;
	
	if(CGRectGetMaxX(detailTextLabelRect) >= CGRectGetMinX(quantityTextLabelRect)) {
		detailTextLabelRect.size.width = CGRectGetMinX(quantityTextLabelRect) - margin;
	}
	
	detailTextLabelRect = CGRectOffset(detailTextLabelRect, 0.0, -1.0);
	
	self.detailTextLabel.frame = detailTextLabelRect;

	[self layoutTextStrokeView];

	// some workarounds
/*	self.backgroundBottomSeparatorView.backgroundColor = self.theme.tableViewCellSeparatorColor;

	self.selectedBackgroundTopSeparatorView.backgroundColor = [UIColor colorWithRed:0.902 green:0.926 blue:0.936 alpha:1.000];
	self.selectedBackgroundBottomSeparatorView.backgroundColor = [UIColor colorWithRed:0.839 green:0.873 blue:0.888 alpha:1.000];

	[self insertSubview:[self separatorHighlightView] belowSubview:[self selectedBackgroundView]];
	[self insertSubview:[self backgroundBottomSeparatorView] belowSubview:[self selectedBackgroundView]]; */
}

- (void)layoutTextStrokeView {
	CGRect textLabelRect = self.textLabel.frame;

	CGSize textStrokeSize = [[self textStrokeView] sizeThatFits:textLabelRect.size];
	textStrokeSize.width = CGRectGetWidth(textLabelRect);
	
	CGRect textStrokeRect = CGRectMake(
		CGRectGetMinX(textLabelRect) - 3.0,
		round(CGRectGetMidY(textLabelRect) - textStrokeSize.height * 0.5 + 1.0),
		textStrokeSize.width + 6.0,
		textStrokeSize.height);
	
	if(!self.completed) {
		textStrokeRect.size.width = 0.0;
	}
		
	self.textStrokeView.frame = textStrokeRect;
	[[self contentView] insertSubview:[self textStrokeView] aboveSubview:[self textLabel]];
	
//	self.textLabel.textColor = self.completed ?
//		self.theme.tableViewCellDetailTextColor :
//		self.theme.tableViewCellTextColor;
}

#pragma mark - Private

- (void)initQuantityTextLabel {
	UILabel* quantityTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];

	quantityTextLabel.font = [UIFont boldSystemFontOfSize:16.0];
	quantityTextLabel.textAlignment = NSTextAlignmentRight;
	// quantityTextLabel.adjustsLetterSpacingToFitWidth = YES;
	quantityTextLabel.minimumScaleFactor = 1.0;

	quantityTextLabel.textColor = [UIColor colorWithRed:0.557 green:0.557 blue:0.557 alpha:1.000];
//	quantityTextLabel.highlightedTextColor = [UIColor whiteColor];
	
	quantityTextLabel.backgroundColor = [UIColor clearColor];

	quantityTextLabel.translatesAutoresizingMaskIntoConstraints = NO;

	self.quantityTextLabel = quantityTextLabel;
	[[self contentView] addSubview:quantityTextLabel];
}

- (void)initTextStrokeView {
	UIImage* image = [GRCTextStrokeRenderer textStrokeImage];
	UIImageView* textStrokeView = [[UIImageView alloc] initWithImage:image];

//	textStrokeView.tintColor = [[UIColor redTintColor] colorWithAlphaComponent:0.9];

	self.textStrokeView = textStrokeView;
	[[self contentView] insertSubview:textStrokeView aboveSubview:[self textLabel]];
}

- (void)initBackgroundBottomSeparatorView {
	CGRect separatorRect = self.bounds;
	separatorRect = CGRectOffset(separatorRect, 0.0, CGRectGetHeight(separatorRect) - 1.0);
	separatorRect.size.height = 1.0;

	UIView* backgroundBottomSeparatorView = [[UIView alloc] initWithFrame:separatorRect];
	backgroundBottomSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;

	self.backgroundBottomSeparatorView = backgroundBottomSeparatorView;
	[self insertSubview:backgroundBottomSeparatorView belowSubview:[self selectedBackgroundView]];
}

- (void)initSelectedBackgroundView {
	UIView* selectedBackgroundView = [[UIView alloc] initWithFrame:[self bounds]];
	selectedBackgroundView.clipsToBounds = NO;
	self.selectedBackgroundView = selectedBackgroundView;

	CGRect separatorRect = selectedBackgroundView.bounds;
	separatorRect.size.height = 1.0;
	separatorRect.origin.y += 0.0;

	UIView* topSeparatorView = [[UIView alloc] initWithFrame:separatorRect];
	topSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	self.selectedBackgroundTopSeparatorView = topSeparatorView;
	[selectedBackgroundView addSubview:topSeparatorView];

	separatorRect.origin.y = CGRectGetMaxY(selectedBackgroundView.bounds) - 1.0;

	UIView* bottomSeparatorView = [[UIView alloc] initWithFrame:separatorRect];
	bottomSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	self.selectedBackgroundBottomSeparatorView = bottomSeparatorView;
	[selectedBackgroundView addSubview:bottomSeparatorView];
}

- (void)initSeparatorHighlightView {
	CGRect frame = self.bounds;
	frame.size.height = 1.0;

	UIView* separatorHighlightView = [[UIView alloc] initWithFrame:frame];

	separatorHighlightView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;

	self.separatorHighlightView = separatorHighlightView;
	[self insertSubview:separatorHighlightView belowSubview:[self selectedBackgroundView]];
}

@end
