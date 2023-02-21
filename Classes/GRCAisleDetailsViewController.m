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

#import "GRCAisleDetailsViewController.h"

#import "GRCAisleImagePickerViewController.h"
#import "GRCAisleFormatter.h"

#import "GRCShoppingListStore.h"
#import "GRCAisle.h"

#import "UIColor+Interface.h"
#import "UIImage+Aisle.h"

@interface GRCAisleDetailsViewController()

@property(nonatomic, readwrite, strong) GRCShoppingListStore* shoppingListStore;
@property(nonatomic, strong) GRCAisleFormatter* aisleFormatter;
@property(nonatomic) CGRect keyboardRect;

@end

@implementation GRCAisleDetailsViewController

#pragma mark - Construction & Destruction

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore {
	if((self = [super initWithNibName:@"AisleDetailsView" bundle:nil])) {
		self.shoppingListStore = shoppingListStore;

		self.hidesBottomBarWhenPushed = YES;
		self.aisleFormatter = [[GRCAisleFormatter alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AisleDetailsViewController

- (IBAction)cancel:(id)sender {
	if([[self delegate] respondsToSelector:@selector(aisleDetailsViewControllerDidCancel:)]) {
		[[self delegate] aisleDetailsViewControllerDidCancel:self];
	}
}

- (IBAction)save:(id)sender {
	GRCAisle* aisle = self.aisle;

	aisle.image = self.selectedImage;

	NSString* newTitle = self.titleTextField.text;

	if(aisle.customTitle.length == 0) {
		if([[[self aisleFormatter] stringForAisle:aisle] isEqualToString:newTitle]) {
			newTitle = nil; // don't customize default titles
		}
	}

	aisle.customTitle = newTitle;

	[[self shoppingListStore] saveAisle:aisle error:nil];

	// Notify our delegate
	if([[self delegate] respondsToSelector:@selector(aisleDetailsViewController:didSaveAisle:)]) {
		[[self delegate] aisleDetailsViewController:self didSaveAisle:aisle];
	}
}

- (IBAction)selectAisleImage:(id)sender {
	GRCAisleImagePickerViewController* aisleImagePicker = [GRCAisleImagePickerViewController viewController];

	aisleImagePicker.title = self.titleTextField.text;
	
	if(aisleImagePicker.title.length <= 0) {
		aisleImagePicker.title = NSLocalizedString(@"PROPERTY_LABEL_AISLE", nil);
	}
	
	aisleImagePicker.selectedImage = self.selectedImage;
	aisleImagePicker.delegate = self;
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:aisleImagePicker];
		[self presentViewController:navigationController animated:YES completion:nil];
	} else {
		[[self navigationController] pushViewController:aisleImagePicker animated:YES];
	}
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	self.contentCell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
	self.contentCell.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];

	GRCAisle* aisle = self.aisle;

	self.title = aisle.aisleDatabaseIdentifier == GRCAisleInvalidDatabaseIdentifier ?
		 NSLocalizedString(@"NEW_AISLE_NAVIGATIONITEM_TITLE", @"") :
		 NSLocalizedString(@"EDITING_NAVIGATIONITEM_TITLE", @"");
	
	self.navigationItem.leftBarButtonItem = self.cancelButtonItem;
	self.navigationItem.rightBarButtonItem = self.saveButtonItem;
	
	// Customize our back bar button item
	UIImage* backImage = [UIImage imageNamed:@"back-buttonitem"];
	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
		initWithImage:backImage
		style:UIBarButtonItemStylePlain
		target:nil
		action:NULL];
	
	// Init the aisle image button
	self.selectedImage = self.aisle.image;
	if(!self.selectedImage) { self.selectedImage = GRCAisleImageNameGeneric; }

	[self updateAisleImageButton];
	
	// Init the title textfield
	self.titleTextField.text = [[self aisleFormatter] stringForAisle:aisle];

	self.titleTextField.placeholder = NSLocalizedString(@"PROPERTY_LABEL_AISLE", nil);
	
	self.titleTextField.textColor = [UIColor blueTableViewCellTextColor];
	
	self.titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	// Update the save button item
	[self updateSaveButtonItem];

	// keyboard notifications
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(keyboardDidChangeFrame:)
		name:UIKeyboardDidChangeFrameNotification
		object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self adjustContentInsetsIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[self titleTextField] becomeFirstResponder];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	return self.contentCell;
}

#pragma mark - AisleImagePickerViewControllerDelegate

- (void)aisleImagePicker:(GRCAisleImagePickerViewController*)picker didFinishPickingImage:(NSString*)imageName {
	self.selectedImage = imageName;
	
	[self updateAisleImageButton];
	[self updateSaveButtonItem];

	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)aisleImagePickerDidCancel:(GRCAisleImagePickerViewController*)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	[self performSelector:@selector(updateSaveButtonItem)
		withObject:nil
		afterDelay:0.0];

	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
	[self performSelector:@selector(updateSaveButtonItem)
		withObject:nil
		afterDelay:0.0];

	return YES;
}

#pragma mark - UIKeyboardDidChangeFrameNotification

- (void)keyboardDidChangeFrame:(NSNotification*)notification {
	CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardRect = [[self tableView] convertRect:keyboardRect fromView:nil];
	self.keyboardRect = keyboardRect;
	
	[self adjustContentInsetsIfNeeded];
}

#pragma mark - Private

- (void)updateAisleImageButton {
	NSString* selectedImage = self.selectedImage;

	[[self aisleImageButton]
		setImage:[UIImage aisleImageNamed:selectedImage size:32 style:SUITableViewCellBlueImageStyle]
		forState:UIControlStateNormal];
	[[self aisleImageButton]
		setImage:[UIImage aisleImageNamed:selectedImage size:32 style:SUITableViewCellSelectedImageStyle]
		forState:UIControlStateHighlighted];
}

- (void)updateSaveButtonItem {
	self.saveButtonItem.enabled =
		self.titleTextField.text.length > 0 &&
		self.selectedImage.length > 0;
}

- (void)adjustContentInsetsIfNeeded {
/*	NSInteger lastSectionIndex = [[self tableView] numberOfSections] - 1;
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
	
	self.tableView.contentInset = contentInset; */
}

@end
