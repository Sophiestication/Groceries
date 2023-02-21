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

#import "SUIFormViewController.h"

#import "SUIEditableTableViewCell.h"

#import "NSArray+Additions.h"
#import "UIColor+Interface.h"

#import <objc/runtime.h>

NSString* const SUIFormViewControllerObjectKey = @"object";
NSString* const SUIFormViewControllerPropertyKey = @"property";
NSString* const SUIFormViewControllerDisplayPropertyKey = @"display-property";
NSString* const SUIFormViewControllerPlaceholderKey = @"placeholder";
NSString* const SUIFormViewControllerMandatoryKey = @"mandatory";
NSString* const SUIFormViewControllerUserInfoKey = @"userinfo";
NSString* const SUIFormViewControllerAutoCapitalizationTypeKey = @"auto-capitalization-type";
NSString* const SUIFormViewControllerAutoCorrectionTypeKey = @"auto-correction-type";

@interface SUIFormViewController()<UITextFieldDelegate>

@property(nonatomic) CGRect keyboardRect;

@end

@implementation SUIFormViewController

#pragma mark - Construction & Destruction

+ (id)viewController {
	return [[self alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SUIFormViewController

- (void)cancel:(id)sender {
	if([[self delegate] respondsToSelector:@selector(formControllerDidCancel:)]) {
		[[self delegate] formControllerDidCancel:self];
	}
}

- (void)save:(id)sender {
	NSInteger fieldIndex = 0;

	for(NSDictionary* field in self.fields) {
		id object = [field objectForKey:SUIFormViewControllerObjectKey];
		NSString* property = [field objectForKey:SUIFormViewControllerPropertyKey];
		
		// Retrieve the new value
		UITableViewCell* cell = [[self tableView] cellForRowAtIndexPath:
			[NSIndexPath indexPathForRow:fieldIndex inSection:0]];
		UITextField* textfield = cell.contentView.subviews.firstObject;
		
		NSString* newValue = textfield.text;
		
		// Update our model object with the new value
		[object setValue:newValue forKey:property];

		// Notifiy the delegate if needed
		if([[self delegate] respondsToSelector:@selector(formController:didFinishEditingField:)]) {
			[[self delegate] formController:self didFinishEditingField:field];
		}
		
		++fieldIndex;
	}
	
	// Notifiy the delegate about the save if needed
	if([[self delegate] respondsToSelector:@selector(formControllerDidSave:)]) {
		[[self delegate] formControllerDidSave:self];
	}
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
		target:self
		action:@selector(cancel:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemSave
		target:self
		action:@selector(save:)];
		
	// set the default title if needed
	if(self.title.length <= 0) {
		self.title = NSLocalizedString(@"EDITING_NAVIGATIONITEM_TITLE", @"");
	}
	
	// table view setup
	[[self tableView]
		registerClass:[SUIEditableTableViewCell class]
		forCellReuseIdentifier:[[self class] editableCellReuseIdentifier]];
		
	// keyboard notifications
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardDidChangeFrame:)
		name:UIKeyboardDidChangeFrameNotification
		object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	[[self tableView] reloadData];
	[self makeFirstResponderIfNeeded];
	
//	[self adjustContentInsetsIfNeeded];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)table numberOfRowsInSection:(NSInteger)section {
	return self.fields.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	SUIEditableTableViewCell* cell = [tableView
		dequeueReusableCellWithIdentifier:[[self class] editableCellReuseIdentifier]
		forIndexPath:indexPath];

	cell.selectionStyle = UITableViewCellSelectionStyleNone;

	cell.textField.delegate = self;

	cell.textField.font = [UIFont systemFontOfSize:16.0];
	cell.textField.textColor = [UIColor blueTableViewCellTextColor];
	cell.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		
	cell.textField.enablesReturnKeyAutomatically = YES;
	cell.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
	NSDictionary* field = [[self fields] objectAtIndex:[indexPath row]];	
	id object = [field objectForKey:SUIFormViewControllerObjectKey];
	
	NSString* property = [field objectForKey:SUIFormViewControllerDisplayPropertyKey];
	if(!property) {
		property = [field objectForKey:SUIFormViewControllerPropertyKey];
	}

	[self setField:field forTextField:[cell textField]];

	cell.textField.text = [object valueForKey:property];
	cell.textField.placeholder = [field objectForKey:SUIFormViewControllerPlaceholderKey];
	
    property = [field objectForKey:SUIFormViewControllerAutoCapitalizationTypeKey];
    if(property) {
        cell.textField.autocapitalizationType = [[field objectForKey:SUIFormViewControllerAutoCapitalizationTypeKey] integerValue];
    }

    property = [field objectForKey:SUIFormViewControllerAutoCorrectionTypeKey];
    if(property) {
        cell.textField.autocorrectionType = [[field objectForKey:SUIFormViewControllerAutoCorrectionTypeKey] integerValue];
    }

	return cell;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	NSDictionary* field = [self fieldForTextField:textField];
	
	if([[field objectForKey:SUIFormViewControllerMandatoryKey] boolValue]) {
		NSString* newString = [[textField text] stringByReplacingCharactersInRange:range withString:string];
		self.navigationItem.rightBarButtonItem.enabled = newString.length > 0;
	}

	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
	NSDictionary* field = [self fieldForTextField:textField];
	
	if([[field objectForKey:SUIFormViewControllerMandatoryKey] boolValue]) {
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	
	return YES;
}

#pragma mark - UIKeyboardDidChangeFrameNotification

- (void)keyboardDidChangeFrame:(NSNotification*)notification {
	CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardRect = [[self tableView] convertRect:keyboardRect fromView:nil];
	self.keyboardRect = keyboardRect;
	
//	[self adjustContentInsetsIfNeeded];
}

#pragma mark - Private

+ (NSString*)editableCellReuseIdentifier {
	return @"editable";
}

- (void)makeFirstResponderIfNeeded {
	// select the first empty field
	NSIndexPath* indexPath = nil;
	NSInteger rowIndex = 0;
	
	for(NSDictionary* field in self.fields) {
		NSString* property = [field objectForKey:SUIFormViewControllerDisplayPropertyKey];
		
		if(!property) {
			property = [field objectForKey:SUIFormViewControllerPropertyKey];
		}
		
		NSString* value = [[field objectForKey:SUIFormViewControllerObjectKey] valueForKey:property];
	
		if(value.length == 0) {
			// Check if this field is mandatory
			if([[field objectForKey:SUIFormViewControllerMandatoryKey] boolValue]) {
				self.navigationItem.rightBarButtonItem.enabled = NO;
			}

			indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:0];
			break;
		}
		
		++rowIndex;
	}
	
	// Just select the first field if none are empty
	if(!indexPath) {
		indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	}

	SUIEditableTableViewCell* cell = (SUIEditableTableViewCell*)[[self tableView] cellForRowAtIndexPath:indexPath];
	[[cell textField] becomeFirstResponder];
}

- (void)adjustContentInsetsIfNeeded {
	NSInteger lastSectionIndex = [[self tableView] numberOfSections] - 1;
	if(lastSectionIndex < 0) { return; }
	
	UIEdgeInsets contentInset = UIEdgeInsetsZero;
	
	self.tableView.contentInset = contentInset; // reset for [rectForSection:]
	
	CGRect rect = [[self tableView] rectForSection:lastSectionIndex];
	CGRect contentRect = self.tableView.bounds;
	
	if(CGRectIsEmpty([self keyboardRect])) {
		contentRect.size.height -= 216.0; // TODO:
	} else {
		contentRect.size.height -= CGRectGetHeight([self keyboardRect]);
	}
	
	if(CGRectGetHeight(contentRect) > CGRectGetMaxY(rect)) {
		CGFloat padding = CGRectGetHeight(contentRect) - CGRectGetMaxY(rect);
		contentInset.top = round(padding * 0.5);
	}
	
	self.tableView.contentInset = contentInset;
}

volatile static void* const SUIFormViewControllerFieldAssocitatedObjectKey;

- (NSDictionary*)fieldForTextField:(UITextField*)textField {
	NSDictionary* field = objc_getAssociatedObject(textField, &SUIFormViewControllerFieldAssocitatedObjectKey);
	return field;
}

- (void)setField:(NSDictionary*)field forTextField:(UITextField*)textField {
	objc_setAssociatedObject(textField, &SUIFormViewControllerFieldAssocitatedObjectKey, field, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
