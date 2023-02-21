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

#import "GRCShoppingListViewController.h"

#import "GRCShoppingListItemDetailsViewController.h"
#import "GRCGroceryPickerViewController.h"
#import "GRCShoppingListPickerViewController.h"
#import "GRCShoppingListOrganizerViewController.h"
#import "GRCAuthorizationStatusViewController.h"

#import "GRCShoppingListItemCell.h"

#import "GRCSectionHeaderView.h"

#import "UIActionSheet+Additions.h"

#import "GRCShoppingListFormatter.h"

#import "GRCAisle.h"
#import "GRCAisleFormatter.h"

#import "GRCUnit.h"
#import "GRCUnitFormatter.h"

#import "GRCShoppingListActivityItemProvider.h"
#import "SUIGiftActivity.h"

#import "GRCAisleColorizer.h"
#import "UINavigationController+AisleTints.h"

#import "GRCShoppingListStore+Private.h"
#import "GRCShoppingList+Private.h"
#import "GRCShoppingListItem+Private.h"

#import "NSArray+Additions.h"
#import "UIColor+Tint.h"
#import "UIImage+Styles.h"
#import "UIImage+Aisle.h"
#import "UIImage+Additions.h"

@interface GRCShoppingListViewController()<GRCShoppingListItemDetailsViewDelegate, GRCShoppingListPickerViewDelegate, GRCGroceryPickerViewDelegate, GRCShoppingListOrganizerViewDelegate>

@property(nonatomic, strong) UIBarButtonItem* addButtonItem;
@property(nonatomic, strong) UIBarButtonItem* shareButtonItem;

@property(nonatomic, strong) UIButton* viewStyleControl;
@property(nonatomic, strong) UIBarButtonItem* viewStyleButtonItem;

@property(nonatomic, strong) UIBarButtonItem* organizeButtonItem;
@property(nonatomic, strong) UIBarButtonItem* trashButtonItem;
@property(nonatomic, strong) UIBarButtonItem* startOverButtonItem;

@property(nonatomic, strong) UIBarButtonItem* selectItemsButtonItem;

@property(nonatomic, strong) UIButton* pickerButton;

@property(nonatomic, strong) NSArray* defaultToolbarItems;
@property(nonatomic, strong) NSArray* editingToolbarItems;

@property(nonatomic, readonly) GRCShoppingListStore* shoppintListStore;

@property(nonatomic, strong) NSMutableSet* shoppingListItems;

@property(nonatomic, strong) NSMapTable* shoppingListItemsByGrocery;
@property(nonatomic, strong) NSMapTable* shoppingListItemsByAisle;
@property(nonatomic, strong) NSMutableSet* selectedShoppingListItems;

@property(nonatomic, strong) NSMutableSet* completedShoppingListItemsNeedingSave;

@property(nonatomic, readonly) NSArray* visibleSections;
@property(nonatomic, strong) NSArray* allSections;
@property(nonatomic, strong) NSArray* remainingSections;

@property(nonatomic) BOOL sectionsAreGroupedByAisle;

@property(nonatomic, strong) GRCUnitFormatter* unitFormatter;

@property(nonatomic) BOOL showsAllShoppingListItems;
@property(nonatomic, readonly) BOOL showsOnlyRemainingShoppingListItems;

@property(nonatomic) BOOL tableViewIsEditingSingleRow;

@property(nonatomic, strong) GRCAisleColorizer* aisleColorizer;

@property(nonatomic, strong) UIImageView* startShoppingCoachMarkView;
@property(nonatomic, strong) UILabel* doneShoppingCoachMarkView;

@end

@implementation GRCShoppingListViewController

@dynamic visibleSections;
@dynamic showsAllShoppingListItems;
@dynamic showsOnlyRemainingShoppingListItems;

#pragma mark - Construction & Destruction

+ (instancetype)viewController {
	return [[self alloc] initWithStyle:UITableViewStylePlain];
}

- (id)initWithStyle:(UITableViewStyle)style {
    if((self = [super initWithStyle:style])) {
		self.selectedShoppingListItems = [NSMutableSet set];
		
		self.unitFormatter = [[GRCUnitFormatter alloc] initWithUnitStyle:GRCUnitFormatterStyleQuantity];

		self.navigationItem.hidesBackButton = YES;
	}

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - GRCShoppingListViewController

- (void)setShoppingList:(GRCShoppingList*)shoppingList {
	if(shoppingList == self.shoppingList || [[self shoppingList] isEqual:shoppingList]) { return; }

	[self unregisterAsConsumerForShoppingList:[self shoppingList]];

	_shoppingList = shoppingList;

	[self loadAisleColorizer];

	self.title = shoppingList.title;
	
	self.shoppingListItems = nil;
	self.shoppingListItemsByAisle = nil;
	self.shoppingListItemsByGrocery = nil;
	self.allSections = self.remainingSections = nil;
	
	[self registerAsConsumerForShoppingList:shoppingList];
}

- (void)presentShoppingListPicker:(id)sender {
	[self cancelSaveCompletedShoppingListItemsIfNeeded];
	[self saveCompletedShoppingListItemsIfNeeded];

	[[self navigationController] popViewControllerAnimated:YES];
}

- (void)presentDetailsViewControllerForItem:(GRCShoppingListItem*)item animated:(BOOL)animated {
	if(!item) { return; }

	GRCShoppingListItemDetailsViewController* viewController = [[GRCShoppingListItemDetailsViewController alloc] initWithShoppingListItem:item];
	viewController.delegate = self;

	[[self navigationController] pushViewController:viewController animated:animated];
}

- (void)presentGroceryPickerAnimated:(BOOL)animated {
	GRCShoppingListStore* shoppingListStore = self.shoppingListStore;

	GRCGroceryPickerViewController* picker = [[GRCGroceryPickerViewController alloc] initWithShoppingListStore:shoppingListStore];
	picker.delegate = self;
	[[self navigationController] presentViewController:picker animated:YES completion:nil];
}

- (void)presentInvalidAuthorizationViewControllerAnimated:(BOOL)animated {
	GRCAuthorizationStatusViewController* viewController = [GRCAuthorizationStatusViewController viewController];
	
	UINavigationController* navigationController = self.navigationController;
	navigationController.viewControllers = @[ viewController ];
}

- (void)addItem:(id)sender {
	[self presentGroceryPickerAnimated:YES];
}

- (void)selectAllItems:(id)sender {
	if(!self.editing) { return; }

	NSSet* visibleShoppingListItems = [self visibleShoppingListItems];
	[[self selectedShoppingListItems] setSet:visibleShoppingListItems];

	[self selectRowsForShoppingListItemsIfNeeded:[self selectedShoppingListItems]];

	[self updateButtonItemsAnimated:NO];
}

- (void)deselectAllItems:(id)sender {
	if(!self.editing) { return; }

	[[self selectedShoppingListItems] removeAllObjects];

	for(NSIndexPath* indexPath in [self indexPathsForShoppingListItems:[self shoppingListItems]]) {
		[[self tableView] deselectRowAtIndexPath:indexPath animated:NO];
	}

	[self updateButtonItemsAnimated:NO];
}

- (void)deleteSelectedItems:(id)sender {
	[self deleteItemsInSet:[self selectedShoppingListItems]];
	[[self selectedShoppingListItems] removeAllObjects];
}

- (void)organize:(id)sender {
	GRCShoppingListOrganizerViewController* viewController = [[GRCShoppingListOrganizerViewController alloc]
		initWithItems:[self selectedShoppingListItems]
		shoppingList:[self shoppingList]];
	
	viewController.delegate = self;
	
	[self presentViewController:viewController animated:YES completion:nil];
}

- (void)startOver:(id)sender {
	UIActionSheet* sheet = [[UIActionSheet alloc]
		initWithTitle:NSLocalizedString(@"SHEETTITLE_RESTART_SHOPPING", nil)
		delegate:nil
		cancelButtonTitle:nil
		destructiveButtonTitle:nil
		otherButtonTitles:nil];

	sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;

	[sheet addButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_UNCHECK_SHOPPINGLIST_ITEMS", nil) block:^() {
		[self resetCompletedItems:sender];
	}];

	[sheet setDestructiveButtonWithTitle:NSLocalizedString(@"SHEETBUTTON_DELETE_CHECKED_SHOPPINGLIST_ITEMS", nil) block:^() {
		[self deleteCompletedItems:sender];
	}];

	[sheet setCancelButtonWithTitle:NSLocalizedString(@"CANCEL_BUTTONITEM", nil) block:^() {
	}];

	if(sender == self.startOverButtonItem) {
		[sheet showFromBarButtonItem:[self startOverButtonItem] animated:YES];
	} else {
		[sheet showInView:[[self view] window]]; // all other show methods ignore [actionSheetStyle]
	}
}

- (void)deleteCompletedItems:(id)sender {
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"completed == YES"];
	NSSet* completedItems = [[self shoppingListItems] filteredSetUsingPredicate:predicate];
	[self deleteItemsInSet:completedItems];

	[self setEditing:NO animated:YES];
}

- (void)resetCompletedItems:(id)sender {
	GRCShoppingListStore* store = self.shoppingListStore;

	[store beginUpdates];

	for(GRCShoppingListItem* item in self.shoppingListItems) {
		if(item.completed == NO) { continue; }

		item.completed = NO;
		[store saveShoppingListItem:item notify:NO error:nil];
	}

	[store endUpdatesAndCommit:YES];

	[self reloadTableViewSections:sender];
	[self updateContentViewAnimated:YES];
	[self setEditing:NO animated:YES];
}

- (void)share:(id)sender {
	// make sure any pending changes are saved
	[self cancelSaveCompletedShoppingListItemsIfNeeded];
	[self saveCompletedShoppingListItemsIfNeeded];
	[self reloadTableViewSections:sender];
	[self updateContentViewAnimated:NO];

	// activity picker
	NSMutableArray* activityItems = [NSMutableArray arrayWithCapacity:3];

	GRCShoppingListFormatter* formatter = [[GRCShoppingListFormatter alloc] init];
	NSString* string = [formatter stringForShoppingList:[self shoppingList] sections:[self remainingSections]];

	if(string) {
		[activityItems addObject:string];

		UISimpleTextPrintFormatter* printFormatter = [[UISimpleTextPrintFormatter alloc] initWithText:string];
		[activityItems addObject:printFormatter];
	}

	if(self.allSections.count > 0) {
		GRCShoppingListActivityItemProvider* shoppingListProvider = [[GRCShoppingListActivityItemProvider alloc]
			initWithShoppingList:[self shoppingList]];
		if(shoppingListProvider) { [activityItems addObject:shoppingListProvider]; }
	}

	SUIGiftActivity* giftActivity = [[SUIGiftActivity alloc] initWithApplicationIdentifier:@"307711028"];

	NSArray* customActivities = @[ giftActivity ];
	
	UIActivityViewController* viewController = [[UIActivityViewController alloc]
		initWithActivityItems:activityItems
		applicationActivities:customActivities];

	viewController.excludedActivityTypes = @[ UIActivityTypePostToTwitter, UIActivityTypePostToFacebook, UIActivityTypePostToWeibo, UIActivityTypePostToTencentWeibo ];
	
	[self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(userDefaultsDidChange:)
		name:NSUserDefaultsDidChangeNotification
		object:nil];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidEnterBackground:)
		name:UIApplicationDidEnterBackgroundNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(applicationDidEnterBackground:)
		name:UIApplicationWillTerminateNotification
		object:nil];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(statusBarFrameDidChange:)
		name:UIApplicationDidChangeStatusBarFrameNotification
		object:nil];

	[self loadPickerButton];
	[self loadButtonItems];
	[self loadToolbar];
	[self loadTableView];

	[self setTableHeaderFooterViewsVisible:YES animated:NO];

	self.title = self.shoppingList.title; // in case the shopping list was set earlier
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[[self navigationController] setToolbarHidden:NO animated:animated];
	[self updateTintColors];

	[self reloadTableViewSections:nil];
	[self updateContentViewAnimated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if(editing == self.editing) { return; }

	if(!editing) { self.tableViewIsEditingSingleRow = NO; }

	self.tableView.allowsMultipleSelectionDuringEditing = editing;
	[super setEditing:editing animated:animated];

	if(!editing) {
		[[self selectedShoppingListItems] removeAllObjects];
	}

	[self updateButtonItemsAnimated:animated];

	// register or unregister as consumers to avoid updating while in edit mode
	// also make sure not to update while animating into none edit mode
	if(editing) {
		[self saveCompletedShoppingListItemsIfNeeded];
		[self unregisterAsConsumerForShoppingList:[self shoppingList]];
	} else {
		if(animated) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.3), dispatch_get_main_queue(), ^{
				if([self isEditing]) { return; }
				[self registerAsConsumerForShoppingList:[self shoppingList]];
			});
		} else {
			[self registerAsConsumerForShoppingList:[self shoppingList]];
		}
	}
}

- (void)setTitle:(NSString*)title {
	[super setTitle:title];
	[self updatePickerButton];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	[self layoutCoachMarks];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return self.visibleSections.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* items = [self visibleSections][section][@"items"];
	return items.count;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	NSString* title = [self visibleSections][section][@"title"];
	return title;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingListItemCell* cell = [tableView
		dequeueReusableCellWithIdentifier:[[self class] shoppingListItemCellReuseIdentifier]
		forIndexPath:indexPath];
	[self configureShoppingListCell:cell forRowAtIndexPath:indexPath];

	return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
	if([self shoppingListItemForRowAtIndexPath:indexPath]) { return YES; }
	return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if(editingStyle != UITableViewCellEditingStyleDelete) { return; }

	GRCShoppingListItem* item = [self shoppingListItemForRowAtIndexPath:indexPath];
	if(!item) { return; }
	
	NSSet* itemsToDelete = [NSSet setWithObject:item];
	[self deleteItemsInSet:itemsToDelete];

/*	NSUInteger numberOfRows = [tableView numberOfRowsInSection:[indexPath section]];

	if(numberOfRows > 1) {
		[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
	} else {
		[tableView deleteSections:[NSIndexSet indexSetWithIndex:[indexPath section]] withRowAnimation:UITableViewRowAnimationAutomatic];
	} */
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
	NSString* headerText = [self tableView:tableView titleForHeaderInSection:section];
	if(!headerText) { return UITableViewAutomaticDimension; }

	return [GRCSectionHeaderView preferredHeight];
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* headerText = [self tableView:tableView titleForHeaderInSection:section];
	if(!headerText) { return nil; }

	GRCSectionHeaderView* headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:
		[[self class] shoppingListItemSectionHeaderReuseIdentifier]];

	NSString* aisleImage = [self visibleSections][section][@"image"];
	headerView.imageView.image = [UIImage
		aisleImageNamed:aisleImage
		size:18.0
		style:nil];

	NSArray* items = [self visibleSections][section][@"items"];
	GRCShoppingListItem* representativeItem = [items firstObject];

	GRCAisle* aisle = representativeItem.aisle;

	UIColor* tintColor = [[self aisleColorizer]
		tintColorForAisle:aisle];
	headerView.tintColor = tintColor;

	[headerView setNeedsLayout];

	return headerView;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	if([self shoppingListItemForRowAtIndexPath:indexPath]) { return UITableViewCellEditingStyleDelete; }
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingListItem* item = [self shoppingListItemForRowAtIndexPath:indexPath];

	if(self.editing) {
		[[self selectedShoppingListItems] addObject:item];
		[self updateButtonItemsAnimated:NO];
	} else {
		GRCShoppingListItemCell* cell = (id)[tableView cellForRowAtIndexPath:indexPath];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];

		[self toggleShoppingListItemCompleted:item];
		[cell setCompleted:[item isCompleted] animated:YES];
	}
}

- (void)tableView:(UITableView*)tableView didDeselectRowAtIndexPath:(NSIndexPath*)indexPath {
	if(self.editing) {
		GRCShoppingListItem* item = [self shoppingListItemForRowAtIndexPath:indexPath];
		[[self selectedShoppingListItems] removeObject:item];

		[self updateButtonItemsAnimated:NO];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingListItem* item = [self shoppingListItemForRowAtIndexPath:indexPath];
	[self presentDetailsViewControllerForItem:item animated:YES];
}

- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath*)indexPath {
	self.tableViewIsEditingSingleRow = YES;
	[self setEditing:YES animated:YES];
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath*)indexPath	{
	self.tableViewIsEditingSingleRow = NO;
	[self setEditing:NO animated:YES];
}

#pragma mark - UIScrollView

- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	if(self.navigationController.topViewController != self) { return; }
	[self updateTintColors];
}

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
	[self cancelSaveCompletedShoppingListItemsIfNeeded];
}

- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate	{
	if(!decelerate) {
		[self rescheduleSaveCompletedShoppingListItemsIfNeeded];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView {
	[self rescheduleSaveCompletedShoppingListItemsIfNeeded];
}

#pragma mark - GRCShoppingListItemDetailsViewDelegate

- (void)shoppingListItemDetailsViewController:(GRCShoppingListItemDetailsViewController*)viewController didCompleteWithAction:(GRCShoppingListItemDetailsViewAction)action {
	if(action == GRCShoppingListItemDetailsViewActionSaved) {
		GRCShoppingListItem* item = viewController.shoppingListItem;
		NSError* error;

		if(![[self shoppingListStore] saveShoppingListItem:item notify:YES overwriteGrocery:NO markAsRecentlyUsed:YES error:&error]) {
			NSLog(@"Could not save shopping list item: %@", error); // TODO:
		}
	}

	if(action == GRCShoppingListItemDetailsViewActionDeleted) {
		// TODO:
	}

	[self reloadTableViewSections:viewController];
	[[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - GRCShoppingListPickerViewDelegate

- (void)shoppingListPicker:(GRCShoppingListPickerViewController*)picker didFinishPickingShoppingList:(GRCShoppingList*)shoppingList {
	self.shoppingList = shoppingList;
	
	[self reloadTableViewSections:picker];
	[self setTableHeaderFooterViewsVisible:NO animated:NO];

	[[picker navigationController] pushViewController:self animated:YES];

/*	[picker dismissViewControllerAnimated:YES completion:^() {
		[self setTableHeaderFooterViewsVisible:NO animated:NO]; // workaround for some table view calculation hickups
		[[self tableView] flashScrollIndicators];
	}]; */
}

- (void)shoppingListPickerDidCancel:(GRCShoppingListPickerViewController*)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - GRCGroceryPickerViewDelegate

- (GRCShoppingListItem*)groceryPicker:(GRCGroceryPickerViewController*)picker shoppingListItemForItem:(GRCGrocery*)grocery {
	[self loadShoppingListItemsByGroceryIfNeeded];

	GRCShoppingListItem* shoppingListItem = [[self shoppingListItemsByGrocery] objectForKey:grocery];
	return shoppingListItem;
}

- (void)groceryPicker:(GRCGroceryPickerViewController*)picker didSelectItem:(GRCGrocery*)grocery {
	GRCShoppingListItem* shoppingListItem = [self groceryPicker:picker shoppingListItemForItem:grocery];
	if(shoppingListItem) { return; }

	shoppingListItem = [[self shoppingList] newItemForGrocery:grocery];

	GRCShoppingListStore* store = self.shoppingListStore;
	NSError* error;

	if(![store saveShoppingListItem:shoppingListItem notify:YES overwriteGrocery:YES markAsRecentlyUsed:YES error:&error]) {
		NSLog(@"Could not save shopping list item: %@", error);
	}
}

- (void)groceryPicker:(GRCGroceryPickerViewController*)picker didDeselectItem:(GRCGrocery*)grocery {
	GRCShoppingListItem* shoppingListItem = [self groceryPicker:picker shoppingListItemForItem:grocery];
	if(!shoppingListItem) { return; }
	
	GRCShoppingListStore* store = self.shoppingListStore;
	NSError* error;

	if(![store deleteShoppingListItem:shoppingListItem notify:YES error:&error]) {
		NSLog(@"Could not delete shopping list item: %@", error);
	}
}

- (GRCShoppingListItemDetailsViewController*)groceryPicker:(GRCGroceryPickerViewController*)picker needsViewControllerForItem:(GRCGrocery*)grocery {
	GRCShoppingListItem* shoppingListItem = [self groceryPicker:picker shoppingListItemForItem:grocery];

	if(!shoppingListItem) {
		shoppingListItem = [[self shoppingList] newItemForGrocery:grocery];
	}

	GRCShoppingListItemDetailsViewController* viewController = [[GRCShoppingListItemDetailsViewController alloc] initWithShoppingListItem:shoppingListItem];
	return viewController;
}

- (void)groceryPicker:(GRCGroceryPickerViewController*)picker didFinishPickingItems:(NSSet*)items {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - GRCShoppingListOrganizerViewDelegate

- (void)shoppingListOrganizerViewControllerDidCancel:(GRCShoppingListOrganizerViewController*)viewController {
	[viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)shoppingListOrganizerViewController:(GRCShoppingListOrganizerViewController*)viewController shouldPerformAction:(GRCShoppingListOrganizerAction)action items:(NSSet*)items shoppingList:(GRCShoppingList*)shoppingList aisle:(GRCAisle*)aisle {
	GRCShoppingListStore* store = self.shoppingListStore;
	NSError* error;

	if(action == GRCShoppingListOrganizerActionMove) {
		if(![store moveShoppingListItems:items intoShoppingList:shoppingList aisle:aisle error:&error]) {
			NSLog(@"Could not move shopping list items: %@", error);
		}
	} else if(action == GRCShoppingListOrganizerActionCopy) {
		if(![store copyShoppingListItems:items intoShoppingList:shoppingList aisle:aisle error:&error]) {
			NSLog(@"Could not copy shopping list items: %@", error);
		}
	}
	
	self.editing = NO;
	[self reloadTableViewSections:viewController];
	
	[viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - NSUserDefaultsDidChangeNotification

- (void)userDefaultsDidChange:(NSNotification*)notification {
	if(!self.shoppingList) { return; }

	if([self aisleGroupingEnabled] != self.sectionsAreGroupedByAisle) {
		[self reloadTableViewSections:nil];
	}
}

#pragma mark - UIApplicationDidChangeStatusBarFrameNotification

- (void)statusBarFrameDidChange:(NSNotification*)notification {
	[self updateCoachMarks];
}

#pragma mark - UIApplicationDidEnterBackgroundNotification

- (void)applicationDidEnterBackground:(NSNotification*)notification {
	[self saveCompletedShoppingListItemsIfNeeded];
	[[self shoppingListStore] updateRemainingItemsBadgeIfNeeded];
}

#pragma mark - Private

- (BOOL)showsAllShoppingListItems {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GRCAllShoppingListItemsShown"];
}

- (void)setShowsAllShoppingListItems:(BOOL)showsAllShoppingListItems {
	[[NSUserDefaults standardUserDefaults] setBool:showsAllShoppingListItems forKey:@"GRCAllShoppingListItemsShown"];
}

- (BOOL)showsOnlyRemainingShoppingListItems {
	return !self.showsAllShoppingListItems;
}

- (BOOL)aisleGroupingEnabled {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GRCShoppingListAisleGroupingEnabled"];
}

#pragma mark -

- (void)loadButtonItems {
	self.addButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
		target:self
		action:@selector(addItem:)];
	
	self.shareButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAction
		target:self
		action:@selector(share:)];

	self.organizeButtonItem = [[UIBarButtonItem alloc]
		initWithTitle:NSLocalizedString(@"ORGANIZE_BUTTONITEM", nil)
		style:UIBarButtonItemStyleBordered
		target:self
		action:@selector(organize:)];

	self.trashButtonItem = [[UIBarButtonItem alloc]
		initWithTitle:NSLocalizedString(@"TRASH_BUTTONITEM", nil)
		style:UIBarButtonItemStyleBordered
		target:self
		action:@selector(deleteSelectedItems:)];
//	self.trashButtonItem.tintColor = [UIColor redTintColor];

	self.startOverButtonItem = [[UIBarButtonItem alloc]
		initWithTitle:NSLocalizedString(@"STARTOVER_BUTTONITEM", nil)
		style:UIBarButtonItemStyleBordered
		target:self
		action:@selector(startOver:)];

//	self.trashButtonItem.width = self.organizeButtonItem.width = self.startOverButtonItem.width = 95.0;

	self.selectItemsButtonItem = [[UIBarButtonItem alloc]
		initWithTitle:NSLocalizedString(@"SELECTALL_BUTTONITEM", nil)
		style:UIBarButtonItemStyleBordered
		target:self
		action:@selector(selectAllItems:)];
	self.selectItemsButtonItem.possibleTitles = [NSSet setWithArray:@[ NSLocalizedString(@"SELECTALL_BUTTONITEM", nil), NSLocalizedString(@"DESELECTALL_BUTTONITEM", nil) ]];

	[self loadViewStyleButtonItem];
}

- (void)loadPickerButton {
	UIButton* pickerButton = [UIButton buttonWithType:UIButtonTypeSystem];

	pickerButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
	[pickerButton addTarget:self action:@selector(presentShoppingListPicker:) forControlEvents:UIControlEventTouchUpInside];

	[pickerButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateDisabled];

	UIImage* image = [[UIImage imageNamed:@"back-buttonitem-template"]
		imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[pickerButton setImage:image forState:UIControlStateNormal];
	pickerButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, -10.0, 0.0, 0.0);

	self.pickerButton = pickerButton;
}

- (void)loadViewStyleButtonItem {
	UIButton* viewStyleControl = [UIButton buttonWithType:UIButtonTypeSystem];

	viewStyleControl.titleLabel.font = [UIFont systemFontOfSize:17.0];
	[viewStyleControl addTarget:self action:@selector(viewStyleShouldChange:) forControlEvents:UIControlEventTouchUpInside];

	self.viewStyleControl = viewStyleControl;

	UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithCustomView:viewStyleControl];
	buttonItem.possibleTitles = [NSSet setWithObjects:
		NSLocalizedString(@"VIEWSTYLE_ALL", nil),
		NSLocalizedString(@"VIEWSTYLE_REMAINING", nil),
		nil];
	self.viewStyleButtonItem = buttonItem;

	[self updateViewStyleButtonItem];
}

- (void)loadToolbar {
	self.defaultToolbarItems = @[
		self.self.viewStyleButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		self.startOverButtonItem];

	self.editingToolbarItems = @[
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		self.trashButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		self.organizeButtonItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
}

- (void)loadTableView {
	[[self tableView]
		registerClass:[GRCShoppingListItemCell class]
		forCellReuseIdentifier:[[self class] shoppingListItemCellReuseIdentifier]];

	[[self tableView]
		registerClass:[GRCSectionHeaderView class]
		forHeaderFooterViewReuseIdentifier:[[self class] shoppingListItemSectionHeaderReuseIdentifier]];

	self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)loadAisleColorizer {
	self.aisleColorizer = [[GRCAisleColorizer alloc] initWithShoppingListStore:[self shoppingListStore]];
}

- (void)loadCoachMarksIfNeeded {
	if(self.doneShoppingCoachMarkView) { return; }

	// start shopping
//	UIImage* image = [[UIImage imageNamed:@"shoppinglist-taptostart"]
//		imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//	UIImageView* startShopping = [[UIImageView alloc] initWithImage:image];
//
//	startShopping.tintColor = [UIColor darkTextColor];
//
//	[[self tableView] addSubview:startShopping];
//	self.startShoppingCoachMarkView = startShopping;

	// done shopping
	UILabel* doneShoppingCoachMarkView = [[UILabel alloc] initWithFrame:CGRectZero];
	
	doneShoppingCoachMarkView.text = NSLocalizedString(@"PLACEHOLDERVIEW_DONESHOPPING_TEXT", @"");
	
	doneShoppingCoachMarkView.textAlignment = NSTextAlignmentCenter;
	
	doneShoppingCoachMarkView.textColor = [UIColor darkTextColor];
	
	//doneShoppingCoachMarkView.font = [UIFont fontWithName:@"Noteworthy-Bold" size:25.0];
	doneShoppingCoachMarkView.font = [UIFont systemFontOfSize:23.0];

	doneShoppingCoachMarkView.adjustsFontSizeToFitWidth = YES;
	
	doneShoppingCoachMarkView.opaque = NO;
	doneShoppingCoachMarkView.backgroundColor = [UIColor clearColor];

	[[self tableView] addSubview:doneShoppingCoachMarkView];
	self.doneShoppingCoachMarkView = doneShoppingCoachMarkView;
}

- (void)layoutCoachMarks {
	UITableView* tableView = self.tableView;
	CGRect contentRect = tableView.bounds;

	CGFloat offset = -tableView.contentOffset.y;
	CGFloat topInset = tableView.contentInset.top;

	CGRect startShoppingCoachMarkViewRect = self.startShoppingCoachMarkView.frame;

	startShoppingCoachMarkViewRect.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(startShoppingCoachMarkViewRect) - 10.0;
	startShoppingCoachMarkViewRect.origin.y = CGRectGetMinY(contentRect) + offset + 4.0;

	self.startShoppingCoachMarkView.frame = startShoppingCoachMarkViewRect;
	[tableView bringSubviewToFront:[self startShoppingCoachMarkView]];

	CGSize doneShoppingCouchMarkViewSize = [[self doneShoppingCoachMarkView]
		sizeThatFits:contentRect.size];

	CGRect doneShoppingCouchMarkViewRect = CGRectMake(
		CGRectGetMinX(contentRect) + 10.0,
		round(CGRectGetMidY(contentRect) - doneShoppingCouchMarkViewSize.height * 0.5 + offset - topInset - 22.0),
		CGRectGetWidth(contentRect) - 20.0,
		doneShoppingCouchMarkViewSize.height);

	self.doneShoppingCoachMarkView.frame = doneShoppingCouchMarkViewRect;
}

#pragma mark -

- (GRCShoppingListStore*)shoppingListStore {
	return self.shoppingList.store;
}

- (void)registerAsConsumerForShoppingList:(GRCShoppingList*)shoppingList {
	__block __weak GRCShoppingListViewController* viewController = self;
	
	[shoppingList addConsumer:viewController callback:^(NSSet* items) {
		if(self.completedShoppingListItemsNeedingSave.count > 0 ) {
			// NSLog(@"omiting update");
			return;
		}
		
		viewController.shoppingListItems = [items mutableCopy];

		self.title = viewController.shoppingList.title;
		[viewController reloadTableViewSections:nil];
		[self updateContentViewAnimated:NO];
	}];

	if(!shoppingList) {
		self.title = nil;
		[self reloadTableViewSections:nil];
		[self updateContentViewAnimated:NO];
	}
}

- (void)unregisterAsConsumerForShoppingList:(GRCShoppingList*)shoppingList {
	[shoppingList removeConsumer:self];
}

- (void)reloadSections {
	self.sectionsAreGroupedByAisle = [self aisleGroupingEnabled];

	if(self.sectionsAreGroupedByAisle) {
		self.shoppingListItemsByAisle = [self shoppingListItemsByAisle:[self shoppingListItems]];
		self.allSections = [self sectionsForShoppingListItemsByAisle:[self shoppingListItemsByAisle]];
	} else {
		self.shoppingListItemsByAisle = [self shoppingListItemsByTitle:[self shoppingListItems]];
		self.allSections = [self sectionsForShoppingListItemsByTitle:[self shoppingListItemsByAisle]];
	}

	self.remainingSections = [self remainingSectionsForSections:[self allSections]];

	self.shoppingListItemsByGrocery = nil;
}

- (void)reloadTableViewSections:(id)sender {
	[self reloadSections];
	
	[[self tableView] reloadData];
	
	[self selectRowsForShoppingListItemsIfNeeded:[self selectedShoppingListItems]];

	if(self.navigationController.topViewController == self) {
		[self updateTintColors];
	}
}

- (void)viewStyleShouldChange:(id)sender {
	[self cancelSaveCompletedShoppingListItemsIfNeeded];
	[self saveCompletedShoppingListItemsIfNeeded];

	self.showsAllShoppingListItems = !self.showsAllShoppingListItems;

	[self reloadTableViewSections:sender];
	[self updateContentViewAnimated:NO];

	[self updateViewStyleButtonItem];
}

- (NSMapTable*)shoppingListItemsByTitle:(NSSet*)shoppingLists {
	NSMutableArray* orderedShoppingLists = [[shoppingLists allObjects] mutableCopy];

	NSArray* sortDescriptors = @[
		[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES],
		[[NSSortDescriptor alloc] initWithKey:@"notes" ascending:YES]];

	[orderedShoppingLists sortUsingDescriptors:sortDescriptors];

	NSMapTable* groups = [NSMapTable strongToStrongObjectsMapTable];
	[groups setObject:orderedShoppingLists forKey:[NSNull null]];

	return groups;
}

- (NSArray*)sectionsForShoppingListItemsByTitle:(NSMapTable*)shoppingListItemsByTitle {
	NSArray* items = [shoppingListItemsByTitle objectForKey:[NSNull null]];
	if(!items) { items = @[]; }

	return @[ @{ @"items": items } ];
}

- (NSMapTable*)shoppingListItemsByAisle:(NSSet*)shoppingLists {
	NSMapTable* aisles = [NSMapTable strongToStrongObjectsMapTable];

	for(GRCShoppingListItem* item in shoppingLists) {
		NSString* aisleIdentifier = [[item aisle] aisleIdentifier];
		if(!aisleIdentifier) { aisleIdentifier = (id)[NSNull null]; }

		NSMutableArray* orderedShoppingLists = [aisles objectForKey:aisleIdentifier];

		if(!orderedShoppingLists) {
			orderedShoppingLists = [NSMutableArray arrayWithCapacity:3];
			[aisles setObject:orderedShoppingLists forKey:aisleIdentifier];
		}

		[orderedShoppingLists addObject:item];
	}

	NSArray* sortDescriptors = @[
		[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES],
		[[NSSortDescriptor alloc] initWithKey:@"notes" ascending:YES]];

	for(NSMutableArray* orderedShoppingLists in [aisles objectEnumerator]) {
		[orderedShoppingLists sortUsingDescriptors:sortDescriptors];
	}

	return aisles;
}

- (NSArray*)sectionsForShoppingListItemsByAisle:(NSMapTable*)shoppingListItemsByAisle {
	NSMutableArray* sections = [NSMutableArray arrayWithCapacity:5];

	NSArray* allAisles = [[self shoppingListStore] aisles];
	GRCAisleFormatter* aisleFormatter = [[GRCAisleFormatter alloc] init];

	for(NSArray* items in [shoppingListItemsByAisle objectEnumerator]) {
		NSMutableDictionary* section = [NSMutableDictionary dictionaryWithCapacity:2];

		GRCAisle* aisle = [(GRCShoppingListItem*)[items firstObject] aisle];
		
		if(aisle) {
			NSString* aisleTitle = [aisleFormatter stringForAisle:aisle];
			if(!aisleTitle) { aisleTitle = @""; }

			section[@"title"] = aisleTitle;
			section[@"image"] = aisle.image;
		} else {
//			section[@"title"] = NSLocalizedString(@"UNSPECIFIED_AISLE_TITLE", nil);
//			section[@"image"] = @"placeholder";
		}

		NSInteger sortOrder = aisle ?
			[allAisles indexOfObject:aisle] :
			NSIntegerMin; // NSIntegerMax;
		section[@"sortOrder"] = @(sortOrder);

		section[@"items"] = items;

		[sections addObject:section];
	}

	[sections sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
		return [obj1[@"sortOrder"] compare:obj2[@"sortOrder"]];
	}];

	return sections;
}

- (NSArray*)remainingSectionsForSections:(NSArray*)sections {
	NSMutableArray* remainingSections = [NSMutableArray arrayWithCapacity:[sections count]];

	NSPredicate* predicate;

	if(self.completedShoppingListItemsNeedingSave.count > 0) {
		predicate = [NSPredicate predicateWithFormat:@"completed == FALSE && NOT (SELF IN %@)", [self completedShoppingListItemsNeedingSave]];
	} else {
		predicate = [NSPredicate predicateWithFormat:@"completed == FALSE"];
	}

	for(NSDictionary* section in sections) {
		NSArray* remainingItems = [section[@"items"] filteredArrayUsingPredicate:predicate];
		if(remainingItems.count == 0) { continue; } // ignore

		NSMutableDictionary* remainingSection = [section mutableCopy];
		[remainingSection setObject:remainingItems forKey:@"items"];

		[remainingSections addObject:remainingSection];
	}

	return remainingSections;
}

- (NSArray*)visibleSections {
	if([self showsOnlyRemainingShoppingListItems]) { // show only remaining items
		return self.remainingSections;
	}

	return self.allSections;
}

- (NSSet*)visibleShoppingListItems {
	if([self showsAllShoppingListItems]) {
		return self.shoppingListItems;
	}
	
	NSMutableSet* visibleShoppingListItems = [NSMutableSet set];

	for(NSArray* items in [[self visibleSections] valueForKeyPath:@"items"]) {
		[visibleShoppingListItems addObjectsFromArray:items];
	}
	
	return visibleShoppingListItems;
}

- (void)loadShoppingListItemsByGroceryIfNeeded {
	if(self.shoppingListItemsByGrocery) { return; }

	NSMapTable* map = [NSMapTable strongToStrongObjectsMapTable];

	for(GRCShoppingListItem* item in self.shoppingListItems) {
		GRCGrocery* grocery = item.grocery;
		if(grocery) { [map setObject:item forKey:grocery]; }
	}

	self.shoppingListItemsByGrocery = map;
}

+ (NSString*)shoppingListItemCellReuseIdentifier { return @"shoppingListItem"; }
+ (NSString*)shoppingListItemSectionHeaderReuseIdentifier { return @"shoppingListSectionHeader"; }

- (GRCShoppingListItem*)shoppingListItemForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSInteger sectionIndex = indexPath.section;
	if(self.visibleSections.count <= sectionIndex) { return nil; }

	NSDictionary* section = [[self visibleSections] objectAtIndex:sectionIndex];

	NSArray* items = section[@"items"];

	NSInteger rowIndex = indexPath.row;
	if(items.count <= rowIndex) { return nil; }

	return items[rowIndex];
}

- (NSSet*)shoppingListItemsForRowsAtIndexPaths:(NSArray*)indexPaths {
	NSMutableSet* shoppingListItems = [NSMutableSet setWithCapacity:[indexPaths count]];
	
	for(NSIndexPath* indexPath in indexPaths) {
		[shoppingListItems addObject:[self shoppingListItemForRowAtIndexPath:indexPath]];
	}
	
	return shoppingListItems;
}

- (NSIndexPath*)indexPathForShoppingListItem:(GRCShoppingListItem*)item {
	NSInteger sectionIndex = 0;

	for(NSDictionary* section in self.visibleSections) {
		NSInteger rowIndex = [[section objectForKey:@"items"] indexOfObject:item];

		if(rowIndex != NSNotFound) {
			return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
		}

		++sectionIndex;
	}

	return nil;
}

- (NSArray*)indexPathsForShoppingListItems:(NSSet*)shoppingListItems {
	NSMutableArray* indexPaths = [NSMutableArray arrayWithCapacity:[shoppingListItems count]];

	for(GRCShoppingListItem* item in shoppingListItems) {
		NSIndexPath* indexPath = [self indexPathForShoppingListItem:item];
		if(indexPath) { [indexPaths addObject:indexPath]; }
	}

	return indexPaths;
}

- (void)configureShoppingListCell:(GRCShoppingListItemCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingListItem* item = [self shoppingListItemForRowAtIndexPath:indexPath];
	
	cell.textLabel.text = item.title;

	self.unitFormatter.quantity = item.quantity;
	cell.quantityTextLabel.text = [[self unitFormatter] stringForUnit:[item unit]];

	cell.detailTextLabel.text = item.notes;

	cell.accessoryType = UITableViewCellAccessoryDetailButton;

//	if(!cell.accessoryView) {
//		UIButton* accessoryView = [[self theme] newTableViewAccessoryView];
//		[accessoryView addTarget:self action:@selector(shoppingListCellAccessoryButtonDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
//		cell.accessoryView = accessoryView;
//	}

	cell.editingAccessoryType = UITableViewCellAccessoryNone;
	
	cell.completed = item.completed;

	UIColor* tintColor = [[self aisleColorizer]
		tintColorForAisle:[item aisle]];
	cell.tintColor = tintColor;

//	if(self.editing) {
//		BOOL isSelected = [[self selectedShoppingListItems] member:item] != nil;
//		cell.selected = isSelected;
//	}
}

- (void)shoppingListCellAccessoryButtonDidTouchUpInside:(id)sender {
	NSIndexPath* indexPath = [self indexPathForCellWithSubview:sender];
	[self tableView:[self tableView] accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (NSIndexPath*)indexPathForCellWithSubview:(UIView*)subview {
	if(!subview) { return nil; }
	
	CGRect rect = [subview convertRect:[subview bounds] toView:[self tableView]];
	CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

	NSIndexPath* indexPath = [[self tableView] indexPathForRowAtPoint:center];
	return indexPath;
}

#pragma mark -

- (void)updateButtonItemsAnimated:(BOOL)animated {
	if(self.editing && self.tableViewIsEditingSingleRow) {
		[[self navigationItem] setLeftBarButtonItem:[self editButtonItem] animated:animated];
		return;
	}

	NSArray* toolbarItems = self.editing ?
		self.editingToolbarItems :
		self.defaultToolbarItems;

	if(self.editing) {
		// workaround an issue where the last button item would move from the left when animating into edit mode
		// this will force a correct layout of the editing button items
		self.toolbarItems = self.editingToolbarItems;
		self.toolbarItems = self.defaultToolbarItems;
	}

	[self setToolbarItems:toolbarItems animated:animated];

	[[self navigationItem] setLeftBarButtonItem:[self editButtonItem] animated:animated];

	if(!self.editing) {
		NSArray* rightBarButtonItems = @[ self.addButtonItem, self.shareButtonItem ];
		[[self navigationItem] setRightBarButtonItems:rightBarButtonItems animated:animated];
	}

	if(self.editing) {
		[self updateTrashButtonItemAnimated:animated];
		[self updateOrganizeButtonItemAnimated:animated];
	}

	[self updateSelectItemsButtonItemAnimated:animated];
	
	[self updateEditButtonItem];
	[self updateShareButtonItem];
	[self updateStartOverButtonItem];

	self.addButtonItem.enabled = self.shoppingList != nil;

	[self updateViewStyleButtonItem];

	self.navigationItem.titleView = self.pickerButton;
	self.pickerButton.enabled = !self.editing;
}

- (void)updateTrashButtonItemAnimated:(BOOL)animated {
	NSInteger numberOfSelectedItems = self.selectedShoppingListItems.count;
	
	self.trashButtonItem.enabled = numberOfSelectedItems > 0;

	if(numberOfSelectedItems > 0) {
		NSString* string = [NSNumberFormatter localizedStringFromNumber:@(numberOfSelectedItems) numberStyle:NSNumberFormatterNoStyle];
		self.trashButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"TRASH_WITHCOUNT_BUTTONITEM", nil), string];
	} else {
		self.trashButtonItem.title = NSLocalizedString(@"TRASH_BUTTONITEM", nil);
	}
}

- (void)updateOrganizeButtonItemAnimated:(BOOL)animated {
	NSInteger numberOfSelectedItems = self.selectedShoppingListItems.count;
	
	self.organizeButtonItem.enabled = numberOfSelectedItems > 0;

	if(numberOfSelectedItems > 0) {
		NSString* string = [NSNumberFormatter localizedStringFromNumber:@(numberOfSelectedItems) numberStyle:NSNumberFormatterNoStyle];
		self.organizeButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"ORGANIZE_WITHCOUNT_BUTTONITEM", nil), string];
	} else {
		self.organizeButtonItem.title = NSLocalizedString(@"ORGANIZE_BUTTONITEM", nil);
	}
}

- (void)updateSelectItemsButtonItemAnimated:(BOOL)animated {
	NSInteger numberOfItems = [[self visibleShoppingListItems] count];

	if(self.selectedShoppingListItems.count == numberOfItems) {
		self.selectItemsButtonItem.title = NSLocalizedString(@"DESELECTALL_BUTTONITEM", nil);
		self.selectItemsButtonItem.action = @selector(deselectAllItems:);
	} else {
		self.selectItemsButtonItem.title = NSLocalizedString(@"SELECTALL_BUTTONITEM", nil);
		self.selectItemsButtonItem.action = @selector(selectAllItems:);
	}

	if(self.editing) {
		NSArray* rightButtonItems = numberOfItems > 0 ?
			@[ self.selectItemsButtonItem ] : nil;
		[[self navigationItem] setRightBarButtonItems:rightButtonItems animated:animated];
	}
}

- (void)updateEditButtonItem {
	self.editButtonItem.enabled = self.shoppingListItems.count > 0;
}

- (void)updateShareButtonItem {
	self.shareButtonItem.enabled = self.shoppingList != nil;
}

- (void)updateStartOverButtonItem {
	self.startOverButtonItem.enabled = self.shoppingListItems.count > 0;
}

- (void)updateViewStyleButtonItem {
	UIButton* viewStyleControl = self.viewStyleControl;
	BOOL selected = self.showsOnlyRemainingShoppingListItems;

	if(selected) {
		[viewStyleControl setTitle:NSLocalizedString(@"VIEWSTYLE_REMAINING", nil) forState:UIControlStateNormal];
	} else {
		[viewStyleControl setTitle:NSLocalizedString(@"VIEWSTYLE_ALL", nil) forState:UIControlStateNormal];
	}

	viewStyleControl.selected = selected;
	[viewStyleControl sizeToFit];

	self.viewStyleButtonItem.enabled = self.shoppingList != nil;
}

- (void)updateCoachMarks {
	BOOL emptyShoppingList =
		self.shoppingListItems && self.shoppingListItems.count == 0;
	BOOL doneShopping =
		[self showsOnlyRemainingShoppingListItems] && self.shoppingListItems && self.remainingSections.count == 0;

	[self loadCoachMarksIfNeeded];

//	self.tableView.separatorStyle = emptyShoppingList ?
//		UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;

	self.startShoppingCoachMarkView.hidden = !emptyShoppingList;
	self.doneShoppingCoachMarkView.hidden = !doneShopping || emptyShoppingList;
}

- (void)updatePickerButton {
	UIButton* pickerButton = self.pickerButton;

	[pickerButton setTitle:[self title] forState:UIControlStateNormal];
	[pickerButton sizeToFit];
}

- (void)updateContentViewAnimated:(BOOL)animated {
	if(!self.shoppingList) {
		[self setTableHeaderFooterViewsVisible:YES animated:animated];

		[[self navigationItem] setLeftBarButtonItem:nil animated:animated];
		[[self navigationItem] setRightBarButtonItem:nil animated:animated];

		[self setToolbarItems:@[] animated:animated];

		return;
	}

	[self setTableHeaderFooterViewsVisible:NO animated:NO];
	
	[self updateEditButtonItem];
	[self updateShareButtonItem];
	[self updateStartOverButtonItem];
	
	[self updateCoachMarks];
}

- (void)updateTintColors {
	UITableView* tableView = self.tableView;

	if(tableView.numberOfSections == 0 || !self.sectionsAreGroupedByAisle) {
		[[self navigationController] setTintColor:nil animated:YES];
		return;
	}

	CGRect primaryHeaderRect = tableView.bounds;
	primaryHeaderRect = UIEdgeInsetsInsetRect(primaryHeaderRect, tableView.contentInset);
	primaryHeaderRect.size.height = [GRCSectionHeaderView preferredHeight];

	NSUInteger primarySectionIndex = NSNotFound;

	for(NSInteger sectionIndex = 0; sectionIndex < tableView.numberOfSections; ++sectionIndex) {
		CGRect sectionRect = [tableView rectForSection:sectionIndex];
		CGRect intersectionRect = CGRectIntersection(primaryHeaderRect, sectionRect);

		if(CGRectGetHeight(intersectionRect) >= CGRectGetHeight(primaryHeaderRect) * 0.5) {
			primarySectionIndex = sectionIndex;
			break;
		}
	}

	if(primarySectionIndex == NSNotFound && tableView.numberOfSections > 0) {
		if(tableView.contentOffset.y <= 0.0) {
			primarySectionIndex = 0;
		} else {
			primarySectionIndex = tableView.numberOfSections - 1;
		}
	}

	GRCAisle* aisle;

	if(primarySectionIndex != NSNotFound) {
		NSArray* items = [self visibleSections][primarySectionIndex][@"items"];
		GRCShoppingListItem* representativeItem = [items firstObject];

		aisle = representativeItem.aisle;
	}

	UIColor* tintColor = [[self aisleColorizer]
		tintColorForAisle:aisle];
	[[self navigationController] setTintColor:tintColor animated:YES];
}

#pragma mark -

- (void)selectRowsForShoppingListItemsIfNeeded:(NSSet*)selectedShoppingListItems {
	if(!self.editing) { return; }
	
	NSArray* selectedIndexPaths = [self indexPathsForShoppingListItems:selectedShoppingListItems];
		
	for(NSIndexPath* indexPath in selectedIndexPaths) {
		[[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}

#pragma mark -

- (void)setTableHeaderFooterViewsVisible:(BOOL)visible animated:(BOOL)animated {
	[self updateButtonItemsAnimated:animated];
}

- (void)toggleShoppingListItemCompleted:(GRCShoppingListItem*)item {
	BOOL completed = !item.completed;

//	if(completed) {
		if(!self.completedShoppingListItemsNeedingSave) { self.completedShoppingListItemsNeedingSave = [NSMutableSet setWithCapacity:1]; }
		[[self completedShoppingListItemsNeedingSave] addObject:item];
//	} else {
//		[[self completedShoppingListItemsNeedingSave] removeObject:item];
//	}

	item.completed = completed;

	[self rescheduleSaveCompletedShoppingListItemsIfNeeded];
}

- (void)cancelSaveCompletedShoppingListItemsIfNeeded {
	if(self.completedShoppingListItemsNeedingSave.count == 0) { return; }
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveCompletedShoppingListItemsIfNeeded) object:nil];
}

- (void)rescheduleSaveCompletedShoppingListItemsIfNeeded {
	if(self.completedShoppingListItemsNeedingSave.count == 0) { return; }
	
	[self cancelSaveCompletedShoppingListItemsIfNeeded];
	[self performSelector:@selector(saveCompletedShoppingListItemsIfNeeded) withObject:nil afterDelay:1.25];
}

- (void)saveCompletedShoppingListItemsIfNeeded {
	if(self.completedShoppingListItemsNeedingSave.count == 0) { return; } // nothing to do

	[self cancelSaveCompletedShoppingListItemsIfNeeded]; // just in case…

	NSMutableArray* indexPaths = [NSMutableArray arrayWithCapacity:[[self completedShoppingListItemsNeedingSave] count]];
	NSCountedSet* sections = [NSCountedSet set];

	[[self shoppingListStore] beginUpdates];

	for(GRCShoppingListItem* item in self.completedShoppingListItemsNeedingSave) {
		NSError* error;

		if(![[self shoppingListStore] saveShoppingListItem:item notify:NO error:&error]) {
			NSLog(@"Could not save shopping list item: %@", error);
		}

		if([self showsAllShoppingListItems] || !item.completed) { continue; }

		NSIndexPath* indexPath = [self indexPathForShoppingListItem:item];

		if(indexPath) {
			[sections addObject:@(indexPath.section)];
			[indexPaths addObject:indexPath];
		}
	}

	[[self shoppingListStore] endUpdatesAndCommit:YES];
	
	[[self completedShoppingListItemsNeedingSave] removeAllObjects];

	if([self showsOnlyRemainingShoppingListItems]) {
		[self deleteItemsAtIndexPaths:indexPaths sections:sections animated:YES];
	}
}

- (void)deleteItemsInSet:(NSSet*)items {
	GRCShoppingListStore* store = self.shoppingListStore;
	NSError* error;

	[store beginUpdates];

	for(GRCShoppingListItem* item in items) {
		if(![store deleteShoppingListItem:item notify:NO error:&error]) {
			NSLog(@"Could not delete shopping list item: %@", error);
		}
	}

	[store endUpdatesAndCommit:YES];

	[self deleteItems:items animated:YES];
	[self setEditing:NO animated:YES];
}

- (void)deleteItemsAtIndexPaths:(NSArray*)indexPaths sections:(NSCountedSet*)sections animated:(BOOL)animated {
	UITableView* tableView = self.tableView;

//	if(animated) {
//		CATransition* transition = [CATransition animation];
//		[[tableView layer] addAnimation:transition forKey:@"updateTransition"];
//	}

	void (^animations)() = ^() {
		if(animated) { // to fade the content view
			CATransition* transition = [CATransition animation];
			[[tableView layer] addAnimation:transition forKey:@"updateTransition"];
		}

		[self reloadSections];
		[tableView reloadData];
		[self updateContentViewAnimated:animated];
		[self updateTintColors];
	};

	if(animated) {
		[UIView transitionWithView:tableView duration:0.3 options:0 animations:animations completion:nil];
	} else {
		animations();
	}
}

- (void)deleteItemsAtIndexPaths2:(NSArray*)indexPaths sections:(NSCountedSet*)sections animated:(BOOL)animated {
	UITableView* tableView = self.tableView;

	[tableView beginUpdates]; {

		NSMutableIndexSet* sectionsToDelete = [NSMutableIndexSet indexSet];

		for(NSNumber* section in sections) {
			NSUInteger numberOfVisibleRows = [tableView numberOfRowsInSection:[section unsignedIntegerValue]];
			NSUInteger numberOfRowsToDelete = [sections countForObject:section];

			if(numberOfRowsToDelete >= numberOfVisibleRows) {
				[sectionsToDelete addIndex:[section unsignedIntegerValue]];
			}
		}

		NSMutableArray* rowsToDelete = [NSMutableArray array];

		for(NSIndexPath* indexPath in indexPaths) {
			if([sectionsToDelete containsIndex:[indexPath section]]) { continue; }
			[rowsToDelete addObject:indexPath];
		}

		UITableViewRowAnimation rowAnimation = animated ?
			UITableViewRowAnimationNone : UITableViewRowAnimationFade;

		if(rowsToDelete.count > 0) { [tableView deleteRowsAtIndexPaths:rowsToDelete withRowAnimation:rowAnimation]; }
		if(sectionsToDelete.count > 0) { [tableView deleteSections:sectionsToDelete withRowAnimation:rowAnimation]; }

		[self reloadSections];

	} [tableView endUpdates];

	[self updateContentViewAnimated:animated];
}

- (void)deleteItems:(NSSet*)items animated:(BOOL)animated {
	NSMutableArray* indexPaths = [NSMutableArray arrayWithCapacity:[items count]];
	NSCountedSet* sections = [NSCountedSet set];

	for(GRCShoppingListItem* item in items) {
		NSIndexPath* indexPath = [self indexPathForShoppingListItem:item];

		if(indexPath) {
			[sections addObject:@(indexPath.section)];
			[indexPaths addObject:indexPath];
		}
	}

	NSMutableSet* newItems = [NSMutableSet setWithSet:[self shoppingListItems]];
	[newItems minusSet:items];
	self.shoppingListItems = newItems;

	[self deleteItemsAtIndexPaths:indexPaths sections:sections animated:animated];
}

@end
