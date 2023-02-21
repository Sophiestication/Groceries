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

#import "SUINumericKeypadView.h"
#import "SUINumericKeypadButton.h"

@interface SUINumericKeypadView()<UIInputViewAudioFeedback>

@property(nonatomic) SUINumericKeypadType keypadType;

@property(nonatomic, strong) UIButton* clearButton;
@property(nonatomic, strong) UIButton* deleteBackwardButton;
@property(nonatomic, strong) UIButton* decimalSeparatorButton;

@property(nonatomic, weak) NSTimer* deleteBackwardButtonTimer;

@property(nonatomic, strong) UIImage* keypadBackgroundImage;
@property(nonatomic, strong) UIImage* keypadHighlightedBackgroundImage;

@end

@implementation SUINumericKeypadView

#pragma mark - Construction & Destruction

- (id)initWithKeypadType:(SUINumericKeypadType)keypadType {
	CGRect frame = CGRectMake(0.0, 0.0, 320.0, 216.0);

	if((self = [self initWithFrame:frame inputViewStyle:UIInputViewStyleDefault])) {
		self.keypadType = keypadType;

		[self initKeypadBackgroundImages];
		[self initKeypadButtons];
		[self initKeypadGridView];
	}
	
	return self;
}

#pragma mark - UIInputViewAudioFeedback

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

#pragma mark - Private

- (void)initKeypadBackgroundImages {
	self.keypadBackgroundImage = [self newImageWithColor:
		[UIColor colorWithRed:0.692 green:0.705 blue:0.728 alpha:1.000]];
	self.keypadHighlightedBackgroundImage = [self newImageWithColor:
		[UIColor clearColor]];
}

- (void)initKeypadButtons {
	NSInteger numberOfButtons = 9;

	NSInteger buttonIndex = 0;
	if(self.keypadType == SUINumericKeypadTypeDecimal) {  buttonIndex = 1; } // skip the zero if needed

	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	formatter.maximumFractionDigits = 0;
	
	for(; buttonIndex <= numberOfButtons; ++buttonIndex) {
		UIButton* button = [self newKeypadButtonWithTag:buttonIndex];
		
		NSString* title = [formatter stringFromNumber:@(buttonIndex)];
		[button setTitle:title forState:UIControlStateNormal];
		
		[button addTarget:self action:@selector(buttonTappedDown:event:) forControlEvents:UIControlEventTouchDown];
		[button addTarget:self action:@selector(decimalButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
		
		[self addSubview:button];
	}
	
	// extra wide zero keypad button
	if(self.keypadType == SUINumericKeypadTypeDecimal) {
		UIButton* zeroButton = [self newZeroKeypadButton];
	
		NSString* zero = [formatter stringFromNumber:@(0)];
		[zeroButton setTitle:zero forState:UIControlStateNormal];
	
		[zeroButton addTarget:self action:@selector(buttonTappedDown:event:) forControlEvents:UIControlEventTouchDown];
		[zeroButton addTarget:self action:@selector(decimalButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];

		[self addSubview:zeroButton];
	}

	// clear button
	if(NO) {
		UIButton* clearButton = [self newClearKeypadButton];
	
		[clearButton addTarget:self action:@selector(buttonTappedDown:event:) forControlEvents:UIControlEventTouchDown];
		[clearButton addTarget:self action:@selector(clearButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
	
		self.clearButton = clearButton;
		[self addSubview:clearButton];
	}
	
	// delete backward button
	if(YES) {
		UIButton* deleteBackwardButton = [self newDeleteBackwardKeypadButton];
	
		[deleteBackwardButton
			addTarget:self
			action:@selector(buttonTappedDown:event:)
			forControlEvents:UIControlEventTouchDown];
		[deleteBackwardButton
			addTarget:self
			action:@selector(deleteBackwardButtonTapped:event:)
			forControlEvents:UIControlEventTouchDown];
		[deleteBackwardButton
			addTarget:self
			action:@selector(deleteBackwardButtonTouchCancelled:event:)
			forControlEvents:UIControlEventTouchCancel];
		[deleteBackwardButton
			addTarget:self
			action:@selector(deleteBackwardButtonTouchUpOrExit:event:)
			forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchDragOutside|UIControlEventTouchDragExit|UIControlEventEditingDidEndOnExit];
	
		self.deleteBackwardButton = deleteBackwardButton;
		[self addSubview:deleteBackwardButton];
	}

	// decimal separator button
	if(self.keypadType == SUINumericKeypadTypeFractional) {
		UIButton* decimalSeparatorButton = [self newDecimalSeparatorButton];

		[decimalSeparatorButton addTarget:self action:@selector(buttonTappedDown:event:) forControlEvents:UIControlEventTouchDown];
		[decimalSeparatorButton addTarget:self action:@selector(decimalSeparatorButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
	
		self.decimalSeparatorButton = decimalSeparatorButton;
		[self addSubview:decimalSeparatorButton];
	}
}

- (void)initKeypadGridView {
	NSInteger const numberOfRows = 4;
	NSInteger const numberOfColumns = 3;

	CGFloat gridHeight = 0.5;
	UIColor* gridColor = [UIColor colorWithRed:0.692 green:0.705 blue:0.728 alpha:1.000];

	for(NSInteger rowIndex = 0; rowIndex < numberOfRows - 1; ++rowIndex) {
		CGRect rowRect = CGRectUnion(
			[self rectForKeypadButtonAtRow:rowIndex column:0],
			[self rectForKeypadButtonAtRow:rowIndex column:numberOfColumns - 1]);

		rowRect = CGRectOffset(rowRect, 0.0, CGRectGetHeight(rowRect) - 0.0);
		rowRect.size.height = gridHeight;

		UIView* gridLineView = [[UIView alloc] initWithFrame:rowRect];
		gridLineView.backgroundColor = gridColor;
		[self addSubview:gridLineView];
	}

	for(NSInteger columnIndx = 0; columnIndx < numberOfColumns; ++columnIndx) {
		CGRect columnRect = CGRectUnion(
			[self rectForKeypadButtonAtRow:0 column:columnIndx],
			[self rectForKeypadButtonAtRow:numberOfRows - 1 column:columnIndx]);

		columnRect = CGRectOffset(columnRect, CGRectGetWidth(columnRect) - 0.0, 0.0);
		columnRect.size.width = gridHeight;

		UIView* gridLineView = [[UIView alloc] initWithFrame:columnRect];
		gridLineView.backgroundColor = gridColor;
		[self addSubview:gridLineView];
	}
}

#pragma mark -

- (UIButton*)newKeypadButtonWithFrame:(CGRect)frame {
	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];

	button.frame = frame;

	button.opaque = NO;
	button.backgroundColor = [UIColor clearColor];

	button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0];

	UIColor* titleLabelColor = [UIColor darkTextColor];
	[button setTitleColor:titleLabelColor forState:UIControlStateNormal];

	UIImage* backgroundImage = self.keypadBackgroundImage;
	[button setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];

	button.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitKeyboardKey;

	return button;
}

- (UIButton*)newAlternateKeypadButtonWithFrame:(CGRect)frame {
	UIButton* button = [self newKeypadButtonWithFrame:frame];

	[button setBackgroundImage:[self keypadBackgroundImage] forState:UIControlStateNormal];
	[button setBackgroundImage:[self keypadHighlightedBackgroundImage] forState:UIControlStateHighlighted];

	return button;
}

- (UIButton*)newKeypadButtonWithTag:(NSInteger)tag {
	CGRect rect = [self rectForKeypadButtonWithTag:tag];
	UIButton* button = [self newKeypadButtonWithFrame:rect];

	button.tag = tag;
	button.translatesAutoresizingMaskIntoConstraints = NO;
	
	return button;
}

- (UIButton*)newZeroKeypadButton {
	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	button.tag = 0;
	button.frame = [self zeroButtonRect];
	
	UIImage* backgroundImage = [UIImage imageNamed:@"keypad-button-background"];
	backgroundImage = [backgroundImage
		resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)
		resizingMode:UIImageResizingModeTile];
	[button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
	
	backgroundImage = [UIImage imageNamed:@"keypad-button-background-highlighted"];
	backgroundImage = [backgroundImage
		resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)
		resizingMode:UIImageResizingModeTile];
	[button setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
	
	button.titleLabel.font = [UIFont boldSystemFontOfSize:23.0];
	
	UIColor* textColor = [UIColor colorWithRed:(51.0 / 0xff) green:(55.0 / 0xff) blue:(72.0 / 0xff) alpha:1.0];
	[button setTitleColor:textColor forState:UIControlStateNormal];

	UIColor* highlightedTextColor = [UIColor whiteColor];
	[button setTitleColor:highlightedTextColor forState:UIControlStateHighlighted];
	
	[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[button setTitleShadowColor:textColor forState:UIControlStateHighlighted];

	button.titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	button.reversesTitleShadowWhenHighlighted = YES;

	button.titleEdgeInsets = UIEdgeInsetsMake(0.0, 39.0, 0.0, 0.0);

	button.titleLabel.textAlignment = NSTextAlignmentLeft;
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	
	button.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitKeyboardKey;

	return button;
}

- (UIButton*)newClearKeypadButton {
	UIButton* button = [self newAlternateKeypadButton];

	[button setTitle:@"C" forState:UIControlStateNormal];
	button.frame = CGRectMake(215.0, 163.0, 91.0, 43.0);
	
	button.accessibilityLabel = NSLocalizedString(@"accessibility.label.clear", nil);

	return button;
}

- (UIButton*)newDeleteBackwardKeypadButton {
	CGRect frame = [self rectForKeypadButtonAtRow:3 column:2];
	UIButton* button = [self newAlternateKeypadButtonWithFrame:frame];

	UIImage* image = [[UIImage imageNamed:@"keypad-image-deletebackwards-template"]
		imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[button setImage:image forState:UIControlStateNormal];

	button.tintColor = [UIColor darkTextColor];
	
	button.accessibilityLabel = NSLocalizedString(@"accessibility.label.deleteBackward", nil);

	return button;
}

- (UIButton*)newDecimalSeparatorButton {
	CGRect frame = [self rectForKeypadButtonAtRow:3 column:0];
	UIButton* button = [self newAlternateKeypadButtonWithFrame:frame];

	NSString* title = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleDecimalSeparator];
	[button setTitle:title forState:UIControlStateNormal];
	
	button.accessibilityLabel = NSLocalizedString(@"accessibility.label.decimalSeparator", nil);

	return button;
}

- (UIButton*)newAlternateKeypadButton {
	UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	UIImage* backgroundImage = [UIImage imageNamed:@"keypad-button-background-highlighted"];
	backgroundImage = [backgroundImage
		resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)
		resizingMode:UIImageResizingModeTile];
	[button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
	
	backgroundImage = [UIImage imageNamed:@"keypad-button-background"];
	backgroundImage = [backgroundImage
		resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0)
		resizingMode:UIImageResizingModeTile];
	[button setBackgroundImage:backgroundImage forState:UIControlStateHighlighted];
	
	button.titleLabel.font = [UIFont boldSystemFontOfSize:23.0];
	
	UIColor* textColor = [UIColor whiteColor];
	[button setTitleColor:textColor forState:UIControlStateNormal];

	UIColor* highlightedTextColor =[UIColor colorWithRed:(51.0 / 0xff) green:(55.0 / 0xff) blue:(72.0 / 0xff) alpha:1.0];
	[button setTitleColor:highlightedTextColor forState:UIControlStateHighlighted];
	
	[button setTitleShadowColor:highlightedTextColor forState:UIControlStateNormal];
	[button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

	button.titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	button.reversesTitleShadowWhenHighlighted = YES;
	
	button.titleLabel.textAlignment = NSTextAlignmentCenter;
	
	button.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitKeyboardKey;

	return button;
}

#pragma mark -

- (UIImage*)newImageWithColor:(UIColor*)color {
	UIImage* image = nil;

	CGSize imageSize = CGSizeMake(4.0, 4.0);
	CGFloat scale = 0.0;

	UIGraphicsBeginImageContextWithOptions(imageSize, NO, scale); {
		[color set];
		UIRectFill(CGRectMake(0.0, 0.0, imageSize.width, imageSize.height));

		image = UIGraphicsGetImageFromCurrentImageContext();
	} UIGraphicsEndImageContext();

	image = [image
		resizableImageWithCapInsets:UIEdgeInsetsMake(1.0, 1.0, 1.0, 1.0)
		resizingMode:UIImageResizingModeStretch];
	
	return image;
}

#pragma mark -

- (CGRect)rectForKeypadButtonAtRow:(NSInteger)rowIndex column:(NSInteger)columnIndex {
	CGFloat const numberOfColumns = 3;
	CGFloat const numberOfRows = 4;

	CGRect contentRect = self.bounds;

	CGFloat buttonWidth = CGRectGetWidth(contentRect) / numberOfColumns;
	CGFloat buttonHeight = CGRectGetHeight(contentRect) / numberOfRows;

	CGRect buttonRect = CGRectMake(
		buttonWidth * columnIndex,
		buttonHeight * rowIndex,
		buttonWidth,
		buttonHeight);

	return buttonRect;
}

- (CGRect)rectForKeypadButtonWithTag:(NSInteger)tag {
	CGRect rect = CGRectZero;

	if(tag == 0) { rect = [self rectForKeypadButtonAtRow:3 column:1]; }

	if(tag == 1) { rect = [self rectForKeypadButtonAtRow:2 column:0]; }
	if(tag == 2) { rect = [self rectForKeypadButtonAtRow:2 column:1]; }
	if(tag == 3) { rect = [self rectForKeypadButtonAtRow:2 column:2]; }
	
	if(tag == 4) { rect = [self rectForKeypadButtonAtRow:1 column:0]; }
	if(tag == 5) { rect = [self rectForKeypadButtonAtRow:1 column:1]; }
	if(tag == 6) { rect = [self rectForKeypadButtonAtRow:1 column:2]; }
	
	if(tag == 7) { rect = [self rectForKeypadButtonAtRow:0 column:0]; }
	if(tag == 8) { rect = [self rectForKeypadButtonAtRow:0 column:1]; }
	if(tag == 9) { rect = [self rectForKeypadButtonAtRow:0 column:2]; }

	return rect;
}

- (CGRect)zeroButtonRect {
	if(self.keypadType == SUINumericKeypadTypeDecimal) {
		return CGRectMake(14.0, 163.0, 191.0, 43.0);
	}

	if(self.keypadType == SUINumericKeypadTypeFractional) {
		[self rectForKeypadButtonWithTag:0];
	}

	return CGRectZero;
}

- (void)buttonTappedDown:(id)sender event:(UIEvent*)event {
	[[UIDevice currentDevice] playInputClick];
}

- (void)decimalButtonTapped:(id)sender event:(UIEvent*)event {
	id<SUINumericKeypadViewDelegate> delegate = self.delegate;

	if([delegate respondsToSelector:@selector(numericKeypadView:didInsertString:)]) {
		// NSString* string = [@([(UIButton*)sender tag]) stringValue];
		NSString* string = [(UIButton*)sender currentTitle];
		[delegate numericKeypadView:self didInsertString:string];
	}
}

- (void)clearButtonTapped:(id)sender event:(UIEvent*)event {
	id<SUINumericKeypadViewDelegate> delegate = self.delegate;

	if([delegate respondsToSelector:@selector(numericKeypadViewDidClear:)]) {
		[delegate numericKeypadViewDidClear:self];
	}
}

- (void)decimalSeparatorButtonTapped:(id)sender event:(UIEvent*)event {
	[self decimalButtonTapped:sender event:event];
}

#pragma mark -

- (void)deleteBackwardButtonTapped:(id)sender event:(UIEvent*)event {
	[self shouldDeleteBackward:sender];
	
	[self performSelector:@selector(scheduleDeleteLastCharacterTimer:)
		withObject:sender
		afterDelay:0.5];
}

- (void)deleteBackwardButtonTouchUpOrExit:(id)sender event:(UIEvent*)event {
	[[self class] cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(scheduleDeleteLastCharacterTimer:)
		object:sender];
	[sender cancelTrackingWithEvent:event];
}

- (void)deleteBackwardButtonTouchCancelled:(id)sender event:(UIEvent*)event {
	[[self class] cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(scheduleDeleteLastCharacterTimer:)
		object:sender];
	[[self deleteBackwardButtonTimer] invalidate], self.deleteBackwardButtonTimer = nil;
}

- (void)scheduleDeleteLastCharacterTimer:(id)sender {
	if(!self.deleteBackwardButtonTimer) {
		self.deleteBackwardButtonTimer = [NSTimer
			scheduledTimerWithTimeInterval:1.0 / 8.0
			target:self
			selector:@selector(shouldDeleteBackward:)
			userInfo:sender
			repeats:YES];
	}
}

- (void)shouldDeleteBackward:(id)sender {
	BOOL hasText = YES;
	
	if(self.keyInputView) {
		hasText = [[self keyInputView] hasText];
	}
	
	if(sender == self.deleteBackwardButtonTimer) {
		if(hasText) {
			[[UIDevice currentDevice] playInputClick];
		} else {
			[[self deleteBackwardButton] cancelTrackingWithEvent:nil];
		}
	}
	
	if(hasText) {
		if([[self delegate] respondsToSelector:@selector(numericKeypadViewDidDeleteBackward:)]) {
			[[self delegate] numericKeypadViewDidDeleteBackward:self];
		}
	}
}

@end
