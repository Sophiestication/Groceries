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

#import "SUIEditableTableViewCell.h"

@interface SUIEditableTableViewCell()

@property(nonatomic, readwrite, strong) UITextField* textField;

@end

@implementation SUIEditableTableViewCell

#pragma mark - Construction & Destruction

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier {
	// We don't just init, we initWithStyle!
    if((self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		[self initTextField];
	}

    return self;
}

#pragma mark - UIView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
	UIView* view = [super hitTest:point withEvent:event];

	if(!view && CGRectContainsPoint([[self contentView] frame], point)) { return self.textField; }
	if(view == self.contentView) { return self.textField; }

	return view;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGFloat const margin = 15.0;
	
	CGRect contentRect = self.bounds;
	contentRect = CGRectInset(contentRect, margin, 0.0);
	
	CGSize textFieldSize = [[self textField]
		sizeThatFits:contentRect.size];
	
	CGRect textFieldRect = CGRectMake(
		CGRectGetMinX(contentRect),
		round(CGRectGetMidY(contentRect) - textFieldSize.height * 0.5),
		CGRectGetWidth(contentRect) + 10.0, // the 10pt make the clear button align better with other accessory views
		textFieldSize.height);
	self.textField.frame = textFieldRect;
}

#pragma mark - Private

- (void)initTextField {
	UITextField* textField = [[UITextField alloc] initWithFrame:CGRectZero];
		
	textField.borderStyle = UITextBorderStyleNone;
	textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		
	self.textField = textField;
	[[self contentView] addSubview:textField];
}

@end
