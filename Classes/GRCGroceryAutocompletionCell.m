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

#import "GRCGroceryAutocompletionCell.h"

#import "GRCTextStrokeRenderer.h"

#import "UIColor+Tint.h"
#import "UIColor+Interface.h"

@interface GRCGroceryAutocompletionCell()

@property(nonatomic, readwrite, strong) UIButton* checkmarkAccessoryButton;
@property(nonatomic, readwrite, strong) UIButton* aisleAccessoryButton;
@property(nonatomic, readwrite, strong) UILabel* quantityTextLabel;
@property(nonatomic, strong) UIImageView* textStrokeView;

@end

@implementation GRCGroceryAutocompletionCell

#pragma mark - Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
    if ((self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier])) {
		[self initSelectedBackgroundView];
		// [self initAisleAccessoryButton];
		[self initQuantityTextLabel];
		[self initTextStrokeView];
	}

    return self;
}

#pragma mark - GRCGroceryAutocompletionCell

- (void)setCompleted:(BOOL)completed {
	if(self.completed == completed) { return; }
	
	_completed = completed;
	[self setNeedsLayout];
}

#pragma mark - UIView

- (void)setTintColor:(UIColor*)tintColor {
	[super setTintColor:tintColor];
	self.quantityTextLabel.tintColor = tintColor;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.checkmarkAccessoryButton.selected = self.selected | self.highlighted;
	self.checkmarkAccessoryButton.highlighted = self.highlighted;

	self.aisleAccessoryButton.selected = self.checkmarkAccessoryButton.selected;
	self.aisleAccessoryButton.highlighted = self.checkmarkAccessoryButton.highlighted;
	
	self.textLabel.highlightedTextColor = self.textLabel.textColor;
	self.detailTextLabel.highlightedTextColor = self.detailTextLabel.textColor;
	
	CGRect contentRect = self.contentView.bounds;

	// checkmark accessory button
	CGFloat const accessoryMargin = 5.0;

//	CGSize checkmarkAccessoryButtonSize = [[self checkmarkAccessoryButton]
//		sizeThatFits:contentRect.size];
//	CGRect checkmarkAccessoryButtonRect = CGRectMake(
//		accessoryMargin,
//		round(CGRectGetMidY(contentRect) - checkmarkAccessoryButtonSize.height * 0.5 + 0.5),
//		checkmarkAccessoryButtonSize.width,
//		checkmarkAccessoryButtonSize.height);
//	self.checkmarkAccessoryButton.frame = checkmarkAccessoryButtonRect;
//
//	checkmarkAccessoryButtonRect = [[self contentView]
//		convertRect:checkmarkAccessoryButtonRect
//		fromView:[[self checkmarkAccessoryButton] superview]];
//
//	// content view
//	CGFloat contentRectMaxX = CGRectGetMaxX(contentRect);
//	contentRect.origin.x = CGRectGetMaxX(checkmarkAccessoryButtonRect) + accessoryMargin;
//	contentRect.size.width = contentRectMaxX - CGRectGetMinX(contentRect);

	// text label
	CGRect textLabelRect = self.textLabel.frame;
//	textLabelRect.origin.x = 0.0;

	// detail text label
	CGRect detailTextLabelRect = self.detailTextLabel.frame;
//	detailTextLabelRect.origin.x = 0.0;

	// aisle accessory button
	CGSize aisleAccessoryButtonSize = CGSizeZero; // CGSizeMake(24.0, 24.0);

	CGRect aisleAccessoryButtonRect = CGRectMake(
		CGRectGetMaxX(contentRect) - accessoryMargin * 2.0 - aisleAccessoryButtonSize.width,
		round(CGRectGetMidY(contentRect) - aisleAccessoryButtonSize.height * 0.5),
		aisleAccessoryButtonSize.width,
		aisleAccessoryButtonSize.height);
	self.aisleAccessoryButton.frame = aisleAccessoryButtonRect;
	
	// quantity label
	BOOL hasQuantity = self.quantityTextLabel.text.length > 0;

	self.quantityTextLabel.hidden = !hasQuantity;
	self.quantityTextLabel.font = self.textLabel.font;
	
	CGFloat const margin = 20.0;

	CGRect quantityTextLabelRect = CGRectZero;

	if(hasQuantity) {
		CGSize quantityTextLabelSize = [[self quantityTextLabel]
			sizeThatFits:contentRect.size];
		quantityTextLabelSize.width = MIN(quantityTextLabelSize.width, 110.0);

		quantityTextLabelRect = CGRectMake(
			CGRectGetWidth(contentRect) - CGRectGetWidth(aisleAccessoryButtonRect) - quantityTextLabelSize.width - margin,
			round(CGRectGetMidY(contentRect) - quantityTextLabelSize.height * 0.5),
			quantityTextLabelSize.width,
			quantityTextLabelSize.height);

		if(CGRectGetMaxX(textLabelRect) >= CGRectGetMinX(quantityTextLabelRect)) {
			textLabelRect.size.width = CGRectGetMinX(quantityTextLabelRect) - margin;
		}

		if(CGRectGetMaxX(detailTextLabelRect) >= CGRectGetMinX(quantityTextLabelRect)) {
			detailTextLabelRect.size.width = CGRectGetMinX(quantityTextLabelRect) - margin;
		}
	}

	if((CGRectGetMaxX(textLabelRect) + margin) >= CGRectGetWidth(contentRect)) {
		textLabelRect.size.width = (CGRectGetWidth(contentRect) - margin) - CGRectGetMinX(textLabelRect);
	}

	if((CGRectGetMaxX(detailTextLabelRect) + margin) >= CGRectGetWidth(contentRect)) {
		detailTextLabelRect.size.width = (CGRectGetWidth(contentRect) - margin) - CGRectGetMinX(detailTextLabelRect);
	}

//	self.contentView.frame = contentRect;
	self.textLabel.frame = textLabelRect;
	self.detailTextLabel.frame = detailTextLabelRect;
	self.quantityTextLabel.frame = quantityTextLabelRect;

	[self layoutTextStrokeView];
}

- (void)layoutTextStrokeView {
	CGRect textLabelRect = self.textLabel.frame;

	CGSize textStrokeSize = [[self textStrokeView] sizeThatFits:textLabelRect.size];
	textStrokeSize.width = CGRectGetWidth(textLabelRect);
	
	CGRect textStrokeRect = CGRectMake(
		CGRectGetMinX(textLabelRect) - 2.0,
		round(CGRectGetMidY(textLabelRect) - textStrokeSize.height * 0.5),
		textStrokeSize.width + 4.0,
		textStrokeSize.height);
	
	if(!self.completed) {
		textStrokeRect.size.width = 0.0;
	}

	self.textStrokeView.alpha = 0.9;
		
	self.textStrokeView.frame = textStrokeRect;
	[[self contentView] insertSubview:[self textStrokeView] aboveSubview:[self textLabel]];
}

#pragma mark - Private

- (void)initSelectedBackgroundView {
	UIView* selectedBackgroundView = [[UIView alloc] initWithFrame:[self bounds]];
	selectedBackgroundView.backgroundColor = [[UIColor alloc] initWithRed:(233.0 / 0xff) green:(240.0 / 0xff) blue:(250.0 / 0xff) alpha:1.0];
	self.selectedBackgroundView = selectedBackgroundView;
}

- (void)initAisleAccessoryButton {
	UIButton* aisleAccessoryButton = [UIButton buttonWithType:UIButtonTypeCustom];

	// aisleAccessoryButton.showsTouchWhenHighlighted = YES;

	self.aisleAccessoryButton = aisleAccessoryButton;
	[self addSubview:aisleAccessoryButton];
}

- (void)initQuantityTextLabel {
	UILabel* quantityTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];

	quantityTextLabel.font = [UIFont boldSystemFontOfSize:16.0];
	quantityTextLabel.textAlignment = NSTextAlignmentRight;
	// quantityTextLabel.adjustsLetterSpacingToFitWidth = YES;
	quantityTextLabel.minimumScaleFactor = 1.0;

	quantityTextLabel.textColor = [UIColor colorWithRed:0.557 green:0.557 blue:0.557 alpha:1.000];
	quantityTextLabel.highlightedTextColor = [UIColor darkTextColor];
	
	quantityTextLabel.backgroundColor = [UIColor clearColor];

	quantityTextLabel.translatesAutoresizingMaskIntoConstraints = NO;

	self.quantityTextLabel = quantityTextLabel;
	[[self contentView] addSubview:quantityTextLabel];
}

- (void)initTextStrokeView {
	UIImage* image = [GRCTextStrokeRenderer textStrokeImage];
	UIImageView* textStrokeView = [[UIImageView alloc] initWithImage:image];
	
	self.textStrokeView = textStrokeView;
	[[self contentView] insertSubview:textStrokeView aboveSubview:[self textLabel]];
}

@end
