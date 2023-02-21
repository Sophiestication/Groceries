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

#import "SUINumericInputViewController.h"
#import "SUINumericKeypadView.h"

@interface SUINumericInputViewController()<SUINumericKeypadViewDelegate, UITextFieldDelegate>

@property(nonatomic, readwrite, copy) NSString* presentationValue;
@property(nonatomic, strong) SUINumericKeypadView* numericKeypadView;

@end

@implementation SUINumericInputViewController

@dynamic numericTextField;

#pragma mark - Construction & Destruction

+ (instancetype)viewController {
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		self.showsDecimalSeparator = YES;
	}

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SUINumericInputViewController

- (UITextField*)numericTextField { return (id)self.view; }

- (void)setValue:(NSNumber*)value {
	if([[self value] isEqual:value]) { return; }
	
	_value = [value copy];
	
	[self updateTextFieldForValueIfNeeded];
}

- (void)setFormatter:(NSFormatter*)formatter {
	if(self.formatter == formatter) { return; }
	
	_formatter = formatter;
	[self updateTextFieldForValueIfNeeded];
}

#pragma mark - UIViewController

- (void)loadView {
	UITextField* textfield = [[UITextField alloc] initWithFrame:CGRectZero];
	
	textfield.delegate = self;
	
	textfield.keyboardType = UIKeyboardTypeDecimalPad;
	textfield.autocorrectionType = UITextAutocorrectionTypeNo;
	textfield.autocapitalizationType = UITextAutocapitalizationTypeNone;
	
	textfield.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	textfield.backgroundColor = [UIColor clearColor];
	textfield.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	
	self.view = textfield;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self loadNumericKeypadView];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(textFieldDidChangeText:)
		name:UITextFieldTextDidChangeNotification
		object:[self numericTextField]];
}

#pragma mark - SUINumericKeypadViewDelegate

- (void)numericKeypadView:(SUINumericKeypadView*)keypadView didInsertString:(NSString*)string {
	[[self numericTextField] insertText:string];
}

- (void)numericKeypadViewDidClear:(SUINumericKeypadView*)keypadView {
	[self valueShouldChangeWithString:@""];
}

- (void)numericKeypadViewDidDeleteBackward:(SUINumericKeypadView*)keypadView {
	[[self numericTextField] deleteBackward];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField*)textField {
	if([[self delegate] respondsToSelector:_cmd]) {
		[[self delegate] textFieldDidBeginEditing:textField];
	}
}

- (BOOL)textFieldShouldEndEditing:(UITextField*)textField {
	if(![[self delegate] respondsToSelector:_cmd]) { return YES; }
	return [[self delegate] textFieldShouldEndEditing:textField];
}

- (void)textFieldDidEndEditing:(UITextField*)textField {
	if([[self delegate] respondsToSelector:_cmd]) {
		[[self delegate] textFieldDidEndEditing:textField];
	}
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	if([[self delegate] respondsToSelector:_cmd]) {
		if(![[self delegate] textField:textField shouldChangeCharactersInRange:range replacementString:string]) {
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
	if(![[self delegate] respondsToSelector:_cmd]) { return YES; }
	return [[self delegate] textFieldShouldClear:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
	if(![[self delegate] respondsToSelector:_cmd]) { return YES; }
	return [[self delegate] textFieldShouldReturn:textField];
}

#pragma mark - Private

- (void)loadNumericKeypadView {
	SUINumericKeypadType keypadType = self.showsDecimalSeparator ?
		SUINumericKeypadTypeFractional :
		SUINumericKeypadTypeDecimal;

	SUINumericKeypadView* numericKeypadView = [[SUINumericKeypadView alloc] initWithKeypadType:keypadType];
	
	numericKeypadView.keyInputView = self.numericTextField;
	numericKeypadView.delegate = self;
	
	self.numericKeypadView = numericKeypadView;
	self.numericTextField.inputView = self.numericKeypadView;
}

- (void)textFieldDidChangeText:(NSNotification*)notification {
	UITextField* textfield = self.numericTextField;
	[self valueShouldChangeWithString:[textfield text]];
}

- (void)valueShouldChangeWithString:(NSString*)presentationValue {
	NSNumber* value;

	// TODO: Find a better workaround for the NSNumberFormatter limitations
	if([[self formatter] isKindOfClass:[NSNumberFormatter class]]) {
		CGFloat const maximumStringLength = 10;
		
		if(presentationValue.length >= maximumStringLength) {
			presentationValue = [presentationValue substringToIndex:maximumStringLength];
		}
	}

	if([[self formatter] getObjectValue:&value forString:presentationValue errorDescription:nil]) {
		if([[self formatter] isKindOfClass:[NSNumberFormatter class]]) {
			self.numericTextField.text = self.presentationValue = presentationValue;
		} else {
			self.numericTextField.text = self.presentationValue = [[self formatter] editingStringForObjectValue:value];
		}

		_value = [value copy];
		
		if([[self delegate] respondsToSelector:@selector(numericInputView:changedValue:presentationValue:)]) {
			[[self delegate] numericInputView:self changedValue:value presentationValue:[self presentationValue]];
		}
	} else {
		self.numericTextField.text = self.presentationValue;
	}
}

- (void)updateTextFieldForValueIfNeeded {
	if(![self isViewLoaded]) { return; }
	if(!self.formatter) { return; }

	NSString* string = [[self formatter] stringForObjectValue:[self value]];
	self.numericTextField.text = self.presentationValue = string;
}

@end
