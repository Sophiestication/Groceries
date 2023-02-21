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

#import "GRCShoppingListItemDetailsViewController.h"

#import "GRCShoppingList+Private.h"
#import "GRCShoppingListItem+Private.h"

#import "GRCAislePickerViewController.h"
#import "GRCUnitPickerViewController.h"
#import "SUINumericInputViewController.h"
#import "GRCBarcodeReaderViewController.h"

#import "SUIEditableTableViewCell.h"

#import "GRCAisleFormatter.h"
#import "GRCUnitFormatter.h"
#import "GRCBarcodeFormatter.h"

#import "NSString+Additions.h"
#import "UIActionSheet+Additions.h"
#import "UIColor+Interface.h"
#import "UIColor+Tint.h"

#import "UINavigationController+AisleTints.h"

@interface GRCShoppingListItemDetailsViewController()<SUINumericInputViewDelegate, GRCUnitPickerViewDelegate, GRCAislePickerViewDelegate, GRCBarcodeReaderViewDelegate>

@property(nonatomic, readwrite, strong) GRCShoppingListItem* shoppingListItem;

@property(nonatomic, strong) SUINumericInputViewController* quantityInputViewController;
@property(nonatomic, strong) SUINumericInputViewController* barcodeInputViewController;

@property(nonatomic, strong) UIBarButtonItem* cancelButtonItem;
@property(nonatomic, strong) UIBarButtonItem* saveButtonItem;

@property(nonatomic, weak) UITextField* editingTextField;

@property(nonatomic, copy) NSString* groceryName;
@property(nonatomic, copy) NSString* notes;
@property(nonatomic, copy) NSNumber* quantity;
@property(nonatomic, strong) GRCUnit* unit;
@property(nonatomic, strong) GRCAisle* aisle;
@property(nonatomic, copy) NSDictionary* barcodeSymbol;

@property(nonatomic, strong) GRCAisleFormatter* aisleFormatter;
@property(nonatomic, strong) GRCUnitFormatter* unitFormatter;

@property(nonatomic) BOOL allowsDeletion;
@property(nonatomic, strong) UIButton* deleteButton;

@end

@implementation GRCShoppingListItemDetailsViewController

#pragma mark - Construction & Destruction

- (id)initWithShoppingListItem:(GRCShoppingListItem*)shoppingListItem {
    if((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.shoppingListItem = shoppingListItem;

		self.groceryName = shoppingListItem.title;
		self.notes = shoppingListItem.notes;
		self.quantity = shoppingListItem.quantity;
		self.unit = shoppingListItem.unit;
		self.aisle = shoppingListItem.aisle;

		self.title = NSLocalizedString(@"EDITING_NAVIGATIONITEM_TITLE", nil);
		self.hidesBottomBarWhenPushed = YES;

		self.aisleFormatter = [[GRCAisleFormatter alloc] init];
		self.unitFormatter = [[GRCUnitFormatter alloc] initWithUnitStyle:GRCUnitFormatterStyleTitleForDisplaying];
	}

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GRCShoppingListStoreLocaleDidChangeNotification object:nil];
}

#pragma mark - GRCShoppingListItemDetailsViewController

- (void)cancel:(id)sender {
	[self dismissViewControllerWithAction:GRCShoppingListItemDetailsViewActionCanceled];
}

- (void)saveItem:(id)sender {
	GRCShoppingListItem* item = self.shoppingListItem;

	item.title = self.groceryName;
	item.notes = self.notes;

	NSNumber* quantity = self.quantity;
	if([quantity doubleValue] == 0.0) { quantity = nil; }
	item.quantity = quantity;

	item.unit = self.unit;
	item.aisle = self.aisle;

	[self dismissViewControllerWithAction:GRCShoppingListItemDetailsViewActionSaved];
}

- (void)deleteItem:(id)sender {
	[self dismissViewControllerWithAction:GRCShoppingListItemDetailsViewActionDeleted];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	[self loadButtonItems];
	[self loadTableView];
	[self loadQuantityInputViewController];
	// [self loadBarcodeInputViewController];

	[self updateButtonItems];

	if([[self delegate] respondsToSelector:@selector(shoppingListItemDetailsViewControllerShouldAllowDeletion:)]) {
		self.allowsDeletion = [[self delegate] shoppingListItemDetailsViewControllerShouldAllowDeletion:self];
	}

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(shoppingListStoreLocaleDidChange:)
		name:GRCShoppingListStoreLocaleDidChangeNotification
		object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[[self navigationController] setToolbarHidden:YES animated:animated];
	[[self navigationController] setTintColor:nil animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return self.allowsDeletion ? 4 : 3;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == [self contentSectionIndex]) { return 2; }
	if(section == [self quantitySectionIndex]) { return 2; }
	if(section == [self barcodeSectionIndex]) { return 1; }
	if(section == [self aisleSectionIndex]) { return 1; }
	if(section == [self acccessorySectionIndex]) { return 1; }
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == [self contentSectionIndex]) {
		SUIEditableTableViewCell* cell = [tableView
			dequeueReusableCellWithIdentifier:[[self class] textfieldCellIdentifier]
			forIndexPath:indexPath];

		cell.textField.delegate = self;

		if([self isGroceryNameIndexPath:indexPath]) { [self configureGroceryNameCell:cell forRowAtIndexPath:indexPath]; }
		if([self isNotesIndexPath:indexPath]) { [self configureNotesCell:cell forRowAtIndexPath:indexPath]; }

		return cell;
	}

	if([self isQuantityIndexPath:indexPath]) {
		UITableViewCell* cell = [tableView
			dequeueReusableCellWithIdentifier:[[self class] quantityCellIdentifier]
			forIndexPath:indexPath];

		[self configureQuantityCell:cell forRowAtIndexPath:indexPath];

		return cell;
	}

	if([self isUnitIndexPath:indexPath]) {
		UITableViewCell* cell = [tableView
			dequeueReusableCellWithIdentifier:[[self class] regularCellIdentifier]];
		if(!cell) { cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:[[self class] regularCellIdentifier]]; }

		[self configureUnitCell:cell forRowAtIndexPath:indexPath];

		return cell;
	}
	
	if([self isBarcodeIndexPath:indexPath]) {
		UITableViewCell* cell = [tableView
			dequeueReusableCellWithIdentifier:[[self class] barcodeCellIdentifier]
			forIndexPath:indexPath];

		[self configureBarcodeCell:cell forRowAtIndexPath:indexPath];

		return cell;
	}

	if([self isAisleIndexPath:indexPath]) {
		UITableViewCell* cell = [tableView
			dequeueReusableCellWithIdentifier:[[self class] regularCellIdentifier]];
		if(!cell) { cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:[[self class] regularCellIdentifier]]; }

		[self configureAisleCell:cell forRowAtIndexPath:indexPath];

		return cell;
	}
	
	if([self isAccessoryIndexPath:indexPath]) {
		UITableViewCell* cell = [tableView
			dequeueReusableCellWithIdentifier:[[self class] accessoryCellIdentifier]];
		if(!cell) { cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[[self class] accessoryCellIdentifier]]; }

		[self configureAccessoryCell:cell forRowAtIndexPath:indexPath];

		return cell;
	}

    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if([self isUnitIndexPath:indexPath]) {
		[self presentUnitPickerAnimated:YES];
	}

	if([self isAisleIndexPath:indexPath]) {
		[self presentAislePickerAnimated:YES];
	}
	
	if([self isAccessoryIndexPath:indexPath]) {
		[self presentDeleteConfirmationSheet:tableView];
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
	if([self isQuantityIndexPath:indexPath]) { return 49.0; }
	return tableView.rowHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView*)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath*)indexPath {
	return NO;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField*)textField {
	self.editingTextField = textField;

	NSIndexPath* indexPath = [self indexPathForCellWithTextField:textField];

	if(indexPath) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.0), dispatch_get_main_queue(), ^ {
			[[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
		});
	}

	// [[self tableView] setEditing:YES animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField*)textField	{
	if(textField == self.editingTextField) {
		self.editingTextField = nil;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
	[self editNextTextFieldIfNeeded];
	return NO;
}

- (BOOL)textFieldShouldClear:(UITextField*)textField {
	NSIndexPath* indexPath = [self indexPathForCellWithTextField:textField];
	if(!indexPath || indexPath.section != [self contentSectionIndex]) { return YES; }

	if([self isGroceryNameIndexPath:indexPath]) { self.groceryName = nil; }
	if([self isNotesIndexPath:indexPath]) { self.notes = nil; }

	[self updateButtonItems];

	return YES;
}

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	NSIndexPath* indexPath = [self indexPathForCellWithTextField:textField];
	if(!indexPath || indexPath.section != [self contentSectionIndex]) { return YES; }

	NSString* newValue = [[textField text] stringByReplacingCharactersInRange:range withString:string];

	if([self isGroceryNameIndexPath:indexPath]) { self.groceryName = newValue; }
	if([self isNotesIndexPath:indexPath]) { self.notes = newValue; }

	[self updateButtonItems];

	return YES;
}

#pragma mark - SUINumericInputViewController

- (void)numericInputView:(SUINumericInputViewController*)viewController changedValue:(id)value presentationValue:(NSString*)displayValue {
	if(self.quantityInputViewController == viewController) {
		self.quantity = value;
	}
	
	if(self.barcodeInputViewController == viewController) {
		// TODO: Store barcode value
	}
}

#pragma mark - UnitPickerViewControllerDelegate

- (void)unitPickerController:(GRCUnitPickerViewController*)picker didFinishPickingUnit:(GRCUnit*)unit {
	self.unit = unit;
	[[self tableView] reloadData];

	[[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - AislePickerControllerDelegate

- (void)aislePicker:(GRCAislePickerViewController*)picker didFinishPickingAisle:(GRCAisle*)aisle {
	self.aisle = aisle;
	[[self tableView] reloadData];

	[[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - GRCShoppingListStoreLocaleDidChangeNotification

- (void)shoppingListStoreLocaleDidChange:(NSNotification*)notification {
	self.unitFormatter.locale = self.aisleFormatter.locale = [[notification userInfo] objectForKey:GRCShoppingListStoreLocaleKey];

	[[self tableView] reloadData];
}

#pragma mark - GRCBarcodeReaderViewDelegate

- (BOOL)barcodeReaderView:(GRCBarcodeReaderViewController*)viewController didRecognizeSymbols:(NSArray*)symbols {
	self.barcodeSymbol = symbols.count > 0 ? [symbols objectAtIndex:0] : nil;

	NSNumber* value = [[self barcodeSymbol] objectForKey:@"string"];

	GRCBarcodeFormatter* formatter = (id)self.barcodeInputViewController.formatter;
	self.barcodeInputViewController.numericTextField.text = [formatter stringForObjectValue:value];

	self.barcodeInputViewController.value = value;
	
	viewController.delegate = nil; // to prevent updates during the following delay
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5), dispatch_get_main_queue(), ^{
		[self dismissBarcodeReader:viewController];
	});

	return YES;
}

#pragma mark - Private

- (void)loadButtonItems {
	self.cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = self.cancelButtonItem;

	self.saveButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveItem:)];
	self.navigationItem.rightBarButtonItem = self.saveButtonItem;

	self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
		initWithTitle:[self groceryName]
		style:UIBarButtonItemStyleBordered
		target:nil
		action:NULL];
}

- (void)loadTableView {
	[[self tableView]
		registerClass:[SUIEditableTableViewCell class]
		forCellReuseIdentifier:[[self class] textfieldCellIdentifier]];
	[[self tableView]
		registerClass:[UITableViewCell class]
		forCellReuseIdentifier:[[self class] quantityCellIdentifier]];
	[[self tableView]
		registerClass:[UITableViewCell class]
		forCellReuseIdentifier:[[self class] barcodeCellIdentifier]];
	[[self tableView]
		registerClass:[UITableViewCell class]
		forCellReuseIdentifier:[[self class] accessoryCellIdentifier]];

	self.tableView.showsVerticalScrollIndicator	= NO;
	self.tableView.allowsSelectionDuringEditing = YES;
	
	self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

- (void)loadQuantityInputViewController {
	SUINumericInputViewController* quantityInputViewController = [SUINumericInputViewController viewController];
	
	quantityInputViewController.value = self.quantity;
	quantityInputViewController.delegate = self;
		
	UITextField* textfield = quantityInputViewController.numericTextField;
	
	textfield.font = [UIFont systemFontOfSize:21.0];
	textfield.textColor = [UIColor blueTableViewCellTextColor];

	textfield.placeholder = NSLocalizedString(@"PROPERTY_LABEL_QUANTITY", @"");
	
	NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
	
	formatter.locale = [NSLocale autoupdatingCurrentLocale];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	[formatter setMaximumIntegerDigits:5];
	[formatter setMaximumFractionDigits:3];
	
	[formatter setUsesSignificantDigits:YES];
	[formatter setMaximumSignificantDigits:3];
	
	[formatter setPartialStringValidationEnabled:YES];
	
	quantityInputViewController.formatter = formatter;

	self.quantityInputViewController = quantityInputViewController;
}

- (void)loadBarcodeInputViewController {
	SUINumericInputViewController* barcodeInputViewController = [SUINumericInputViewController viewController];

	barcodeInputViewController.showsDecimalSeparator = NO;
	// barcodeInputViewController.value = self.quantity;
	barcodeInputViewController.delegate = self;

	GRCBarcodeFormatter* barcodeFormatter = [[GRCBarcodeFormatter alloc] init]; // TODO: Set the default barcode style
	barcodeInputViewController.formatter = barcodeFormatter;
		
	UITextField* textfield = barcodeInputViewController.numericTextField;
	
	textfield.font = [UIFont systemFontOfSize:17.0];
	textfield.textColor = [UIColor blueTableViewCellTextColor];

	textfield.placeholder = NSLocalizedString(@"Barcode", @"");

	textfield.clearButtonMode = UITextFieldViewModeNever;

	self.barcodeInputViewController = barcodeInputViewController;
}

- (void)updateButtonItems {
	self.saveButtonItem.enabled = self.groceryName.length > 0;
	self.navigationItem.backBarButtonItem.title = self.groceryName;
}

+ (NSString*)textfieldCellIdentifier { return @"textfield"; }
+ (NSString*)quantityCellIdentifier { return @"quantity"; }
+ (NSString*)barcodeCellIdentifier { return @"barcode"; }
+ (NSString*)regularCellIdentifier { return @"regular"; }
+ (NSString*)accessoryCellIdentifier { return @"accessory"; }

- (NSInteger)contentSectionIndex { return 0; }
- (NSInteger)quantitySectionIndex { return 1; }
- (NSInteger)barcodeSectionIndex { return -1; }
- (NSInteger)aisleSectionIndex { return 2; }
- (NSInteger)acccessorySectionIndex { return 3; }

- (BOOL)isGroceryNameIndexPath:(NSIndexPath*)indexPath { return indexPath.section == [self contentSectionIndex] && indexPath.row == 0; }
- (BOOL)isNotesIndexPath:(NSIndexPath*)indexPath { return indexPath.section == [self contentSectionIndex] && indexPath.row == 1; }

- (BOOL)isQuantityIndexPath:(NSIndexPath*)indexPath { return indexPath.section == [self quantitySectionIndex] && indexPath.row == 0; }
- (BOOL)isUnitIndexPath:(NSIndexPath*)indexPath { return indexPath.section == [self quantitySectionIndex] && indexPath.row == 1; }

- (BOOL)isBarcodeIndexPath:(NSIndexPath*)indexPath { return indexPath.section == [self barcodeSectionIndex] && indexPath.row == 0; }

- (BOOL)isAisleIndexPath:(NSIndexPath*)indexPath { return indexPath.section == [self aisleSectionIndex] && indexPath.row == 0; }

- (BOOL)isAccessoryIndexPath:(NSIndexPath*)indexPath { return indexPath.section == [self acccessorySectionIndex] && indexPath.row == 0; }

- (NSIndexPath*)groceryNameIndexPath { return [NSIndexPath indexPathForRow:0 inSection:[self contentSectionIndex]]; } // TODO
- (NSIndexPath*)notesIndexPath { return [NSIndexPath indexPathForRow:1 inSection:[self contentSectionIndex]]; } // TODO
- (NSIndexPath*)quantityIndexPath { return [NSIndexPath indexPathForRow:0 inSection:[self quantitySectionIndex]]; } // TODO
- (NSIndexPath*)barcodeIndexPath { return [NSIndexPath indexPathForRow:0 inSection:[self barcodeSectionIndex]]; } // TODO
- (NSIndexPath*)accessoryIndexPath { return [NSIndexPath indexPathForRow:0 inSection:[self acccessorySectionIndex]]; } // TODO

#pragma mark -

- (void)configureGroceryNameCell:(SUIEditableTableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.textField.spellCheckingType = YES;
	cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	cell.textField.returnKeyType = UIReturnKeyNext;
	cell.textField.text = self.groceryName;
	cell.textField.placeholder = NSLocalizedString(@"PROPERTY_LABEL_NAME", nil);
}

- (void)configureNotesCell:(SUIEditableTableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.textField.spellCheckingType = YES;
	cell.textField.returnKeyType = UIReturnKeyNext;
	cell.textField.text = self.notes;
	cell.textField.placeholder = NSLocalizedString(@"PROPERTY_LABEL_NOTE", nil);
}

- (void)configureQuantityCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	UITextField* textfield = self.quantityInputViewController.numericTextField;
	UIView* contentView = cell.contentView;

	// adjust the textfield frame
	CGRect textFieldRect = contentView.bounds;
	textFieldRect = CGRectInset(textFieldRect, 15.0, 0.0);
		
	CGSize textFieldSize = [textfield sizeThatFits:textFieldRect.size];
	textFieldRect = CGRectMake(
		CGRectGetMinX(textFieldRect),
		round(CGRectGetMidY(textFieldRect) - textFieldSize.height * 0.5) + 3.0, // lazy tweaks
		CGRectGetWidth(textFieldRect) + 10.0, // the 10pt make the clear button align better with other accessory views
		textFieldSize.height);
	textfield.frame = textFieldRect;

	// attach if needed
	[contentView addSubview:textfield];
		
	// And set the display text
	textfield.text = self.quantityInputViewController.presentationValue;

	cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)configureUnitCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;

	GRCUnit* unit = self.unit;

	if(unit) {
		cell.detailTextLabel.text = [[self unitFormatter] stringForUnit:unit];
		cell.detailTextLabel.textColor = [UIColor blueTableViewCellTextColor];
	} else {
		cell.detailTextLabel.text = NSLocalizedString(@"PROPERTY_LABEL_UNIT", @"");
		cell.detailTextLabel.textColor = [UIColor grayTableViewCellTextColor];
	}

	cell.textLabel.text = NSLocalizedString(@"PROPERTY_LABEL_UNIT", nil);
}

- (void)configureBarcodeCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	UITextField* textfield = self.barcodeInputViewController.numericTextField;
	UIView* contentView = cell.contentView;

	// adjust the textfield frame
	CGRect textfieldRect = contentView.bounds;
		
	textfieldRect = CGRectInset(textfieldRect, 0.0, 2.0);
	textfieldRect.origin.x += 10.0;
	textfieldRect.size.width -= 15.0;
		
	textfield.frame = textfieldRect;

	// attach if needed
	[contentView addSubview:textfield];
		
	// And set the display text
	textfield.text = self.barcodeInputViewController.presentationValue;
	
	// accessory view
/*	SUIAccessoryButton* accessoryView = (id)cell.accessoryView;
	
	if(!accessoryView && [GRCBarcodeReaderViewController isBarcodeReaderAvailable]) {
		CGRect accessoryViewRect = CGRectMake(0.0, 0.0, 44.0, 46.0);
		accessoryView = [[SUIAccessoryButton alloc] initWithFrame:accessoryViewRect];
		
		accessoryView.contentEdgeInsets = UIEdgeInsetsMake(4.0, 5.0, 0.0, 10.0);
		
		accessoryView.accessoryType = SUIAddAccessoryButtonType;
		accessoryView.selected = YES;

		[accessoryView addTarget:self action:@selector(presentBarcodeReader:event:) forControlEvents:UIControlEventTouchUpInside];
		
		cell.accessoryView = accessoryView;
	} */

	cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)configureAisleCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;

	GRCAisle* aisle = self.aisle;

	if(aisle) {
		cell.detailTextLabel.text = [[self aisleFormatter] stringForAisle:aisle];
		cell.detailTextLabel.textColor = [UIColor blueTableViewCellTextColor];
	} else {
		cell.detailTextLabel.text = NSLocalizedString(@"UNSPECIFIED_AISLE_TITLE", @"");
		cell.detailTextLabel.textColor = [UIColor grayTableViewCellTextColor];
	}

	cell.textLabel.text = NSLocalizedString(@"PROPERTY_LABEL_AISLE", nil);
}

- (void)configureAccessoryCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = NSLocalizedString(@"DELETE_GROCERY_BUTTONITEM", nil);
	cell.textLabel.textColor = [UIColor colorWithRed:1.000 green:0.231 blue:0.188 alpha:1.000];
}

#pragma mark -

- (NSIndexPath*)indexPathForCellWithTextField:(UITextField*)textField {
	if(!textField) { return nil; }

	CGRect rect = [textField convertRect:[textField bounds] toView:[self tableView]];
	NSIndexPath* indexPath = [[self tableView] indexPathForRowAtPoint:rect.origin];

	return indexPath;
}

- (void)editNextTextFieldIfNeeded {
	NSIndexPath* indexPath = [self indexPathForCellWithTextField:[self editingTextField]];

	if(!indexPath) {
		if(self.groceryName.length == 0) {
			indexPath = [self groceryNameIndexPath];
		} else if(self.notes.length == 0) {
			indexPath = [self notesIndexPath];
		} else if(!self.quantity) {
			indexPath = [self quantityIndexPath];
		}
	} else {
		if([self isGroceryNameIndexPath:indexPath]) {
			indexPath = [self notesIndexPath];
		} else if([self isNotesIndexPath:indexPath]) {
			indexPath = [self quantityIndexPath];
		} else if([self isQuantityIndexPath:indexPath]) {
			indexPath = nil;
		}
	}

	if(indexPath) {
		if([self isQuantityIndexPath:indexPath]) {
			[[[self quantityInputViewController] numericTextField] becomeFirstResponder];
		} else {
			SUIEditableTableViewCell* cell = (id)[[self tableView] cellForRowAtIndexPath:[self notesIndexPath]];
			[[cell textField] becomeFirstResponder];
		}
	} else {
		[[self editingTextField] resignFirstResponder];
	}
}

- (void)presentDeleteConfirmationSheet:(id)sender {
	NSLocale* locale = [NSLocale currentLocale];
	NSString* groceryTitle = [[[self shoppingListItem] title] quotedStringWithLocale:locale];
		
	NSString* sheetTitle = [NSString stringWithFormat:
		NSLocalizedString(@"DELETE_GROCERY_PROMPT", nil),
		groceryTitle,
		[[UIDevice currentDevice] localizedModel]];
	
	UIActionSheet* sheet = [[UIActionSheet alloc]
		initWithTitle:sheetTitle
		delegate:nil
		cancelButtonTitle:nil
		destructiveButtonTitle:nil
		otherButtonTitles:nil];

	[sheet setDestructiveButtonWithTitle:NSLocalizedString(@"TRASH_BUTTONITEM", nil) block:^() {
		[self deleteItem:sender];
	}];

	[sheet setCancelButtonWithTitle:NSLocalizedString(@"CANCEL_BUTTONITEM", nil) block:^() {
	}];

	[sheet showInView:[self view]];
}

- (void)presentUnitPickerAnimated:(BOOL)animated {
	[[self editingTextField] resignFirstResponder];

	GRCShoppingListStore* shoppingListStore = self.shoppingListItem.shoppingList.store;
	GRCUnitPickerViewController* unitPicker = [[GRCUnitPickerViewController alloc]
		initWithShoppingListStore:shoppingListStore];

	unitPicker.delegate = self;
	unitPicker.selectedUnit = self.unit;

	[[self navigationController] pushViewController:unitPicker animated:animated];
}

- (void)presentAislePickerAnimated:(BOOL)animated {
	GRCShoppingListStore* shoppingListStore = self.shoppingListItem.shoppingList.store;

	GRCAislePickerViewController* aislePicker = [[GRCAislePickerViewController alloc]
		initWithShoppingListStore:shoppingListStore
		style:UITableViewStyleGrouped];

	aislePicker.allowsModifications = YES;
	aislePicker.delegate = self;
	aislePicker.selectedAisle = self.aisle;

	[[self navigationController] pushViewController:aislePicker animated:animated];
}

- (void)dismissViewControllerWithAction:(GRCShoppingListItemDetailsViewAction)action {
	if([[self delegate] respondsToSelector:@selector(shoppingListItemDetailsViewController:didCompleteWithAction:)]) {
		[[self delegate] shoppingListItemDetailsViewController:self didCompleteWithAction:action];
	}
}

#pragma mark -

- (void)presentBarcodeReader:(id)sender event:(UIEvent*)event {
	[[self editingTextField] resignFirstResponder];
	
	GRCBarcodeReaderViewController* barcodeReader = [[GRCBarcodeReaderViewController alloc] init];
	
	NSString* prompt = [NSString stringWithFormat:
		NSLocalizedString(@"LINKWITHBARCODE_NAVIGATIONITEM_PROMPT", nil),
		[[self groceryName] quotedStringWithLocale:nil]];
	barcodeReader.navigationItem.prompt = prompt;
	
	barcodeReader.title = NSLocalizedString(@"LINKWITHBARCODE_NAVIGATIONITEM_TITLE", nil);
	
	barcodeReader.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemDone
		target:self
		action:@selector(dismissBarcodeReader:)];

	barcodeReader.delegate = self;

	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:barcodeReader];

	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	navigationController.navigationBar.translucent = YES;

	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)dismissBarcodeReader:(id)sender {
	UIViewController* viewController = [self presentedViewController];
	[viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
