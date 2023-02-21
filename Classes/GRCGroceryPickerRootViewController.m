//
//  GRCGroceryPickerViewController.m
//  Groceries
//
//  Created by Sophia Teutschler on 29.09.12.
//  Copyright (c) 2012 Sophia Teutschler. All rights reserved.
//

#import "GRCGroceryPickerRootViewController.h"

#import "GRCGroceryPickerHeaderView.h"
#import "GRCGroceryAutocompletionCell.h"

#import "GRCGroceryAutocompletion.h"
#import "GRCUnitFormatter.h"

#import "GRCShoppingListItemDetailsViewController.h"

#import "GRCBarcodeReaderViewController.h"

#import "GRCAisleColorizer.h"

#import "GRCShoppingListStore.h"
#import "GRCShoppingListStore+Private.h"

#import "GRCShoppingList.h"
#import "GRCShoppingListItem.h"
#import "GRCAisle.h"

#import "NSArray+Additions.h"
#import "UIColor+Interface.h"
#import "UIImage+Aisle.h"
#import "UIImage+Styles.h"

@interface GRCGroceryPickerRootViewController()<UISearchBarDelegate, GRCShoppingListItemDetailsViewDelegate, GRCBarcodeReaderViewDelegate>

@property(nonatomic, readonly, weak) GRCGroceryPickerViewController* groceryPickerViewController;
@property(nonatomic, readonly, weak) id<GRCGroceryPickerViewDelegate> delegate;

@property(nonatomic, readonly) UISearchBar* searchBar;

@property(nonatomic) UIBarButtonItem* barcodeReaderDoneButtonItem;

@property(nonatomic, copy) NSDictionary* currentBarcodeSymbol;

@property(nonatomic, strong) GRCGroceryAutocompletion* autocompletion;

@property(nonatomic, strong) GRCDetectorValue* autocompletionDetectorValue;
@property(nonatomic, strong) NSArray* autocompletionResults;

@property(nonatomic, strong) GRCUnitFormatter* unitFormatter;

@property(nonatomic, strong) NSArray* recentItems;

@property(nonatomic, strong) NSArray* sections;

@property(nonatomic, strong) UILabel* noAutocompletionResultsLabel;

@property(nonatomic) BOOL needsToPresentAutocompletionInputView;

@property(nonatomic, strong) GRCAisleColorizer* aisleColorizer;

@end

@implementation GRCGroceryPickerRootViewController

@dynamic groceryPickerViewController;
@dynamic delegate;
@dynamic searchBar;

#pragma mark - Construction & Destruction

- (id)initWithStyle:(UITableViewStyle)style {
    if((self = [super initWithStyle:style])) {
		self.hidesBottomBarWhenPushed = YES;
		self.needsToPresentAutocompletionInputView = YES;
    }

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - GRCGroceryPickerRootViewController

- (void)insertNewItem:(id)sender {
	GRCDetectorValue* detectorValue = self.autocompletionDetectorValue;
	if(detectorValue.string.length == 0) { return; }

	GRCGrocery* newItem = [[GRCGrocery alloc] initWithDetectorValue:detectorValue];
	
	GRCGroceryStore* groceryStore = [[self shoppingListStore] groceryStore];
	NSLocale* locale = [[self shoppingListStore] locale];
	
	GRCGrocery* existingItem = [groceryStore groceryForTitle:[newItem title] locale:locale];
	NSIndexPath* existingIndexPath = [self indexPathForItem:existingItem];
	
	if(existingIndexPath) {
		[[self tableView] selectRowAtIndexPath:existingIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
		[self tableView:[self tableView] didSelectRowAtIndexPath:existingIndexPath];
		
		[self updateInsertItemAccessoryButton];
		[[self headerView] selectSearchText:self showMenu:NO];
		
		return;
	}

	if(existingItem) {
		newItem = existingItem;
	}
	
	NSMutableArray* newAutocompletionResults = [NSMutableArray arrayWithArray:[self autocompletionResults]];
	[newAutocompletionResults insertObject:newItem atIndex:0];
	self.autocompletionResults = newAutocompletionResults;

	if([[self delegate] respondsToSelector:@selector(groceryPicker:didSelectItem:)]) {
		[[self delegate] groceryPicker:[self groceryPickerViewController] didSelectItem:newItem];
	}
	
	self.sections = [self newAutocompletionSections];

	UIButton* accessoryButton = [self insertItemAccessoryButton];
	accessoryButton.userInteractionEnabled = NO;

	NSIndexPath* indexPath = [self indexPathForItem:newItem];
	
	if([[self tableView] numberOfSections] <= indexPath.section) {
		NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[indexPath section]];
		[[self tableView] insertSections:indexSet withRowAnimation:UITableViewRowAnimationTop];
	} else {
		[[self tableView] insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationTop];
	}
	
	[[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];

	// workaround for missing table view animation completion
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.2), dispatch_get_main_queue(), ^{
		[self reloadSections];
		[self updateInsertItemAccessoryButton];
		[[self headerView] selectSearchText:self showMenu:NO];
	});
}

- (void)presentBarcodeReaderAnimated:(BOOL)animated {
	GRCBarcodeReaderViewController* barcodeReaderViewController = [[GRCBarcodeReaderViewController alloc] init];
	
	barcodeReaderViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemDone
		target:self
		action:@selector(dismissBarcodeReaderViewController:)];
			
	barcodeReaderViewController.delegate = self;
	
	id completion = ^(BOOL finished) {
		UITableView* tableView = self.tableView;
	
		[tableView beginUpdates]; {
		
			NSRange range = NSMakeRange(0, [tableView numberOfSections]);
			NSIndexSet* sections = [NSIndexSet indexSetWithIndexesInRange:range];
			[tableView deleteSections:sections withRowAnimation:UITableViewRowAnimationNone];
		
			self.sections = [self newSectionsForBarcodeReaderSymbols:nil];
			[tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
		
		} [tableView endUpdates];
	};

	GRCGroceryPickerViewController* groceryPicker = self.groceryPickerViewController;
	[groceryPicker presentBarcodeReaderViewController:barcodeReaderViewController animated:animated completion:completion];
}

- (void)dismissBarcodeReaderViewController:(id)sender {
	GRCGroceryPickerViewController* groceryPicker = self.groceryPickerViewController;
	
	id completion = ^(BOOL finished) {
		[self reloadSections];
	};
	
	[groceryPicker dismissBarcodeReaderViewControllerAnimated:YES completion:completion];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[self tableView]
		registerClass:[GRCGroceryAutocompletionCell class]
		forCellReuseIdentifier:[[self class] autocompletionCellIdentifier]];
	[[self tableView]
		registerClass:[UITableViewCell class]
		forCellReuseIdentifier:[[self class] barcodeReaderCellIdentifier]];
	[[self tableView]
		registerClass:[UITableViewCell class]
		forCellReuseIdentifier:[[self class] barcodeReaderSymbolCellIdentifier]];
	[[self tableView]
		registerClass:[GRCGroceryAutocompletionCell class]
		forCellReuseIdentifier:[[self class] recentItemsCellIdentifier]];
	
	self.tableView.allowsMultipleSelection = YES;
	self.tableView.allowsMultipleSelectionDuringEditing = YES;
	
	self.tableView.editing = YES;
	
	self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

	GRCGroceryPickerHeaderView* headerView = [[GRCGroceryPickerHeaderView alloc] initWithFrame:CGRectZero];
	self.navigationItem.titleView = headerView;
	
	self.searchBar.delegate = self;
	self.searchBar.placeholder = NSLocalizedString(@"GROCERYSEARCH_SEARCHFIELD_PLACEHOLDER", nil);

	self.unitFormatter = [[GRCUnitFormatter alloc] initWithUnitStyle:GRCUnitFormatterStyleQuantity];

	[[self insertItemAccessoryButton]
		addTarget:self
		action:@selector(insertNewItem:)
		forControlEvents:UIControlEventTouchUpInside];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(localeDidChange:)
		name:GRCShoppingListStoreLocaleDidChangeNotification
		object:[self shoppingListStore]];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(unitDidChange:)
		name:GRCShoppingListStoreUnitDidChangeNotification
		object:[self shoppingListStore]];

	[self reloadSections];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Prevent automatic scroll indicator flashing
	self.tableView.showsVerticalScrollIndicator = NO;

	if(self.needsToPresentAutocompletionInputView) {
		[[self searchBar] becomeFirstResponder];
		self.needsToPresentAutocompletionInputView = NO;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	// Flash the scroll indicator after a delay. The default implemenation is messed up somehow.
	self.tableView.showsVerticalScrollIndicator = YES;

	if(animated) {
		[[self tableView] performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.0];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return self.sections.count;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
	NSDictionary* section = self.sections[sectionIndex];
	if(!section) { return nil; }
	
	NSString* title = section[@"title"];
	return title;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* items = [[[self sections] objectAtIndex:section] objectForKey:@"items"];
	return items.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSDictionary* section = [[self sections] objectAtIndex:[indexPath section]];
	
	NSDictionary* row = section[@"items"][indexPath.row];
	
	NSString* type = section[@"type"];
	id cell = [tableView dequeueReusableCellWithIdentifier:type forIndexPath:indexPath];
	
	if([type isEqualToString:[[self class] autocompletionCellIdentifier]]) {
		[self configureGroceryItemCell:cell forRowAtIndexPath:indexPath];
	} else if([type isEqualToString:[[self class] barcodeReaderCellIdentifier]]) {
		[self configureBarcodeReaderCell:cell forRowAtIndexPath:indexPath];
	} else if([type isEqualToString:[[self class] barcodeReaderSymbolCellIdentifier]]) {
		[self configureBarcodeReaderSymbolCell:cell forRow:row atIndexPath:indexPath];
	} else if([type isEqualToString:[[self class] recentItemsCellIdentifier]]) {
		[self configureRecentItemCell:cell forRowAtIndexPath:indexPath];
	}

	return cell;
}

#pragma mark -

- (void)configureGroceryItemCell:(GRCGroceryAutocompletionCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCGrocery* grocery = [self itemForRowAtIndexPath:indexPath];
	[self configureCell:cell forRowAtIndexPath:indexPath grocery:grocery];
}

- (void)configureBarcodeReaderCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.imageView.image = [UIImage imageNamed:@"camera" style:SUITableViewCellImageStyle];
	cell.imageView.highlightedImage = [UIImage imageNamed:@"camera" style:SUITableViewCellSelectedImageStyle];
	
	cell.textLabel.text = NSLocalizedString(@"FINDBYBARCODE_NAVIGATIONITEM_TITLE", nil);
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureBarcodeReaderSymbolCell:(UITableViewCell*)cell forRow:(NSDictionary*)row atIndexPath:(NSIndexPath*)indexPath {
	cell.textLabel.text = row[@"text"];
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureRecentItemCell:(GRCGroceryAutocompletionCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCGrocery* grocery = self.sections[indexPath.section][@"items"][indexPath.row];
	[self configureCell:cell forRowAtIndexPath:indexPath grocery:grocery];
}

- (void)configureCell:(GRCGroceryAutocompletionCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath grocery:(GRCGrocery*)grocery {
	cell.textLabel.text = grocery.title;
	cell.detailTextLabel.text = grocery.notes;

	self.unitFormatter.quantity = grocery.quantity;
	cell.quantityTextLabel.text = [[self unitFormatter] stringForUnit:[grocery unit]];

	cell.accessoryType = UITableViewCellAccessoryDetailButton;
	cell.editingAccessoryType = UITableViewCellAccessoryDetailButton;

	cell.completed = NO;

	GRCShoppingListItem* shoppingListItem = [self shoppingListItemForItem:grocery];
	GRCAisle* aisle;
	
	// update from shopping list item
	if(shoppingListItem) {
		cell.detailTextLabel.text = shoppingListItem.notes;
		
		self.unitFormatter.quantity = shoppingListItem.quantity;
		cell.quantityTextLabel.text = [[self unitFormatter] stringForUnit:[shoppingListItem unit]];

		cell.completed = shoppingListItem.completed;

		aisle = shoppingListItem.aisle;
	} else {
		NSUInteger aisleDatabaseIdentifier = grocery.aisleDatabaseIdentifier;
		aisle = [[self shoppingListStore] aisleForDatabaseIdentifier:aisleDatabaseIdentifier];
	}

	if(aisle) {
		[self initAisleColorizerIfNeeded];
		cell.tintColor = [[self aisleColorizer] tintColorForAisle:aisle];
	} else {
		cell.tintColor = nil;
	}
}

#pragma mark -

- (NSString*)aisleImageNameForItem:(GRCShoppingListItem*)item orGrocery:(GRCGrocery*)grocery {
	NSUInteger aisleDatabaseIdentifier = grocery.aisleDatabaseIdentifier;
	GRCAisle* aisle = [[self shoppingListStore] aisleForDatabaseIdentifier:aisleDatabaseIdentifier];

	if(!aisle) {
		aisle = item.aisle;
	}

	NSString* aisleImageName = aisle.image;
	if(!aisleImageName) { aisleImageName = GRCAisleImageNameGeneric; }

	return aisleImageName;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	NSDictionary* section = [[self sections] objectAtIndex:[indexPath section]];
	NSString* type = section[@"type"];
	
	if([type isEqualToString:[[self class] barcodeReaderCellIdentifier]]) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self presentBarcodeReaderAnimated:YES];
		
		return;
	}
	
	if([[self delegate] respondsToSelector:@selector(groceryPicker:didSelectItem:)]) {
		GRCGrocery* item = [self itemForRowAtIndexPath:indexPath];
		[[self delegate] groceryPicker:[self groceryPickerViewController] didSelectItem:item];
		
		if(![[self searchBar] isFirstResponder]) { return; }
		[[self headerView] selectSearchText:self showMenu:NO];
	}
}

- (void)tableView:(UITableView*)tableView didDeselectRowAtIndexPath:(NSIndexPath*)indexPath {
	if([[self delegate] respondsToSelector:@selector(groceryPicker:didDeselectItem:)]) {
		GRCGrocery* item = [self itemForRowAtIndexPath:indexPath];
		[[self delegate] groceryPicker:[self groceryPickerViewController] didDeselectItem:item];

		[tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
	if(![[self delegate] respondsToSelector:@selector(groceryPicker:needsViewControllerForItem:)]) { return; }

	[[self searchBar] resignFirstResponder];

	GRCGrocery* item = [self itemForRowAtIndexPath:indexPath];

	GRCShoppingListItemDetailsViewController* viewController = [[self delegate] groceryPicker:[self groceryPickerViewController] needsViewControllerForItem:item];
	viewController.delegate = self;
	[[self navigationController] pushViewController:viewController animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText {
	[self autocompleteWithStringIfNeeded:searchText];
	[self updateInsertItemAccessoryButton];
}

- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar {
	[searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar {
	if([[self delegate] respondsToSelector:@selector(groceryPicker:didFinishPickingItems:)]) {
		[[self delegate] groceryPicker:[self groceryPickerViewController] didFinishPickingItems:nil];
	}
}

#pragma mark - GRCShoppingListItemDetailsViewDelegate

- (void)shoppingListItemDetailsViewController:(GRCShoppingListItemDetailsViewController*)viewController didCompleteWithAction:(GRCShoppingListItemDetailsViewAction)action {
	GRCShoppingListItem* item = viewController.shoppingListItem;
	NSError* error;

	if(action == GRCShoppingListItemDetailsViewActionSaved) {
		if(![[self shoppingListStore] saveShoppingListItem:item notify:YES overwriteGrocery:YES markAsRecentlyUsed:YES error:&error]) {
			NSLog(@"Could not save shopping list item: %@", error); // TODO:
		}
	}

	if(action == GRCShoppingListItemDetailsViewActionDeleted) {
		NSMutableArray* newAutocompletionResults = [[self autocompletionResults] mutableCopy];
		[newAutocompletionResults removeObject:[item grocery]];
		self.autocompletionResults = newAutocompletionResults;
		
		if(![[self shoppingListStore] deleteShoppingListItemIncludingGrocery:item error:&error]) {
			NSLog(@"Could not delete shopping list item: %@", error); // TODO:
		}
	}
	
	[self reloadSections];

	[[self navigationController] popToViewController:self animated:YES];
}

- (BOOL)shoppingListItemDetailsViewControllerShouldAllowDeletion:(GRCShoppingListItemDetailsViewController*)viewController {
	return YES;
}

#pragma mark - GRCShoppingListStoreLocaleDidChangeNotification

- (void)localeDidChange:(NSNotification*)notification {
	[self updateAutocompletionIfNeeded];
}

#pragma mark - GRCShoppingListStoreUnitDidChangeNotification

- (void)unitDidChange:(NSNotification*)notification {
	[self updateAutocompletionIfNeeded];
}

#pragma mark - GRCBarcodeReaderViewDelegate

- (BOOL)barcodeReaderView:(GRCBarcodeReaderViewController*)viewController didRecognizeSymbols:(NSArray*)symbols {
	NSDictionary* barcodeSymbol = symbols.firstObject;
	if([[[self currentBarcodeSymbol] objectForKey:@"string"] isEqualToString:[barcodeSymbol objectForKey:@"string"]]) { return NO; }
	
	self.currentBarcodeSymbol = barcodeSymbol;
	
	self.sections = [self newSectionsForBarcodeReaderSymbols:symbols];
	[[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];

	return YES;
}

#pragma mark - Private

+ (NSString*)autocompletionCellIdentifier { return @"autocompletion"; }
+ (NSString*)barcodeReaderCellIdentifier { return @"barcodeReader"; }
+ (NSString*)barcodeReaderSymbolCellIdentifier { return @"barcodeReaderSymbol"; }
+ (NSString*)recentItemsCellIdentifier { return @"recentItems"; }

#pragma mark -

- (BOOL)autocompletionResultsShown {
	return self.searchBar.text.length > 0;
}

- (void)reloadSections {
	if([self autocompletionResultsShown]) {
		self.sections = [self newAutocompletionSections];
	} else {
		self.recentItems = [[self shoppingListStore] recentItems];
		self.sections = [self newStandardSections];
	}
	
	[[self tableView] reloadData];

	[self updateItemSelections];
	[self updateInsertItemAccessoryButton];

	[self updateAutocompletionResultsLabel];
}

- (NSIndexPath*)indexPathForItem:(GRCGrocery*)grocery {
	if(!grocery) { return nil; }
	if(![self autocompletionResultsShown]) { return nil; }
	if(self.autocompletionResults.count == 0) { return nil; }
	
	NSUInteger itemIndex = [[self autocompletionResults] indexOfObject:grocery];
	if(itemIndex == NSNotFound) { return nil; }

	return [NSIndexPath indexPathForRow:itemIndex inSection:0];
}

- (GRCGrocery*)itemForRowAtIndexPath:(NSIndexPath*)indexPath {
	if([self autocompletionResultsShown]) {
		GRCGrocery* item = [[self autocompletionResults] objectAtIndex:[indexPath row]];
		return item;
	}
	
	return [self recentItemForRowAtIndexPath:indexPath];
}

- (GRCGrocery*)recentItemForRowAtIndexPath:(NSIndexPath*)indexPath {
	if([self autocompletionResultsShown]) { return nil; }
	
	GRCGrocery* item = [[self recentItems] objectAtIndex:[indexPath row]];
	return item;
}

- (GRCShoppingListItem*)shoppingListItemForItem:(GRCGrocery*)item {
	return [[self delegate] groceryPicker:[self groceryPickerViewController] shoppingListItemForItem:item];
}

- (GRCGroceryPickerViewController*)groceryPickerViewController { return (id)self.parentViewController; }
- (id<GRCGroceryPickerViewDelegate>)delegate { return (id)self.groceryPickerViewController.delegate; }

- (GRCGroceryPickerHeaderView*)headerView { return (GRCGroceryPickerHeaderView*)[[self navigationItem] titleView]; }
- (UIButton*)insertItemAccessoryButton { return [[self headerView] insertAccessoryView]; }
- (UISearchBar*)searchBar { return [[self headerView] searchBar]; }

- (void)autocompleteWithStringIfNeeded:(NSString*)string {
	if(!self.autocompletion) {
		self.autocompletion = [[GRCGroceryAutocompletion alloc] init];
		
		self.autocompletion.locale = self.shoppingListStore.locale;
		self.autocompletion.units = self.shoppingListStore.units;
	}
	
	GRCGroceryAutocompletionScope scope = GRCGroceryAutocompletionScopeGenerics/*|GRCGroceryAutocompletionScopeBrands*/;
	[[self autocompletion] autocompleteForString:string scope:scope completion:^(GRCDetectorValue* detectorValue, NSArray* items, NSError* error) {
		[self loadUnitsForGroceryItemsIfNeeded:items];

		if(detectorValue.groceryTitle.length == 0) {
			detectorValue = nil;
		}

		self.autocompletionDetectorValue = detectorValue;
		self.autocompletionResults = items;

		[self reloadSections];
		
		CGFloat topInset = self.tableView.contentInset.top;
		[[self tableView] setContentOffset:CGPointMake(0.0, -topInset) animated:NO];
	}];
}

- (void)updateAutocompletionIfNeeded {
	if(!self.autocompletion) { return; }
	
	self.autocompletion.locale = self.shoppingListStore.locale;
	self.autocompletion.units = self.shoppingListStore.units;
	
	NSString* string = self.searchBar.text;
	[self autocompleteWithStringIfNeeded:string];
}

- (void)updateItemSelections {
	if(self.autocompletionResultsShown) {
		for(GRCGrocery* item in self.autocompletionResults) {
			GRCShoppingListItem* shoppingListItem = [self shoppingListItemForItem:item];

			if(shoppingListItem) {
				NSIndexPath* indexPath = [self indexPathForItem:item];
				[[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			}
		}
	} else {
		NSString* identifier = [[self class] recentItemsCellIdentifier];
		
		[[self sections] enumerateObjectsUsingBlock:^(NSDictionary* section, NSUInteger sectionIndex, BOOL* stop) {
			if(![[section objectForKey:@"type"] isEqualToString:identifier]) { return; }
			
			NSArray* items = section[@"items"];
			[items enumerateObjectsUsingBlock:^(GRCGrocery* item, NSUInteger itemIndex, BOOL* stop) {
				GRCShoppingListItem* shoppingListItem = [self shoppingListItemForItem:item];
				if(!shoppingListItem) { return; }
				
				NSIndexPath* indexPath = [NSIndexPath indexPathForRow:itemIndex inSection:sectionIndex];
				[[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
			}];
		}];
	}
}

- (void)updateInsertItemAccessoryButton {
	UIButton* accessoryButton = [self insertItemAccessoryButton];

	accessoryButton.enabled = self.autocompletionDetectorValue != nil;
	accessoryButton.userInteractionEnabled = !self.autocompletion.running;
}

- (void)updateAutocompletionResultsLabel {
	if([self autocompletionResultsShown] && self.sections.count == 0) {
		[self initNoAutocompletionResultsLabelIfNeeded];
		self.noAutocompletionResultsLabel.hidden = NO;
	} else {
		self.noAutocompletionResultsLabel.hidden = YES;
	}
}

#pragma mark -

- (NSArray*)newStandardSections {
	NSMutableArray* sections = [NSMutableArray arrayWithCapacity:2];
	
	if([GRCBarcodeReaderViewController isBarcodeReaderAvailable]) {
		NSDictionary* barcodeReaderSection = @{
			@"type": [[self class] barcodeReaderCellIdentifier],
			@"items": @[ @{ } ] }; // This ain't no ASCII art
		[sections addObject:barcodeReaderSection];
	}
	
	if(self.recentItems.count > 0) {
		NSDictionary* recentItemsSection = @{
			@"type": [[self class] recentItemsCellIdentifier],
			@"title": NSLocalizedString(@"RECENTLYADDED_SECTIONHEADER_TITLE", nil),
			@"items": [self recentItems] };
		[sections addObject:recentItemsSection];
	}
	
	return sections;
}

- (NSArray*)newAutocompletionSections {
	if(self.autocompletionResults.count == 0) { return nil; }

	NSDictionary* section = @{
		@"type": [[self class] autocompletionCellIdentifier],
		@"items": self.autocompletionResults };
	return @[ section ];
}

- (NSArray*)newSectionsForBarcodeReaderSymbols:(NSArray*)symbols {
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:[symbols count]];
	
	for(NSDictionary* symbol in symbols) {
		NSDictionary* item = @{
			@"text": symbol[@"string"] };
		[items addObject:item];
	}

	NSDictionary* section = @{
		@"type": [[self class] barcodeReaderSymbolCellIdentifier],
		@"items": items };
	return @[ section ];
}

#pragma mark -

- (void)initNoAutocompletionResultsLabelIfNeeded {
	if(self.noAutocompletionResultsLabel) { return; }

	UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectZero];

	textLabel.text = NSLocalizedString(@"GROCERYSEARCH_NOSEARCHRESULTS_PLACEHOLDER", nil);

	textLabel.font = [UIFont boldSystemFontOfSize:19.0];
	textLabel.textColor = [UIColor grayTableViewCellTextColor];

	textLabel.backgroundColor = [UIColor clearColor];

	[textLabel sizeToFit];

	CGFloat offsetFactor = CGRectGetHeight([[self tableView] bounds]) > 480.0 ? 3.5 : 2.5;

	CGRect textLabelRect = textLabel.frame;
	textLabelRect.origin.x = round(CGRectGetMidX([[self tableView] bounds]) - CGRectGetWidth(textLabelRect) * 0.5);
	textLabelRect.origin.y = round(self.tableView.rowHeight * offsetFactor - CGRectGetHeight(textLabelRect) * 0.5);
	textLabel.frame = textLabelRect;

	self.noAutocompletionResultsLabel = textLabel;
	[[self tableView] addSubview:textLabel];
}

#pragma mark -

- (void)storeUserDefaults {
	// TODO: 
}

- (void)restoreFromUserDefaults {
	// TODO:
}

#pragma mark - 

- (void)loadUnitsForGroceryItemsIfNeeded:(NSArray*)items {
	for(GRCGrocery* grocery in items) {
		if(grocery.unit) { continue; }
		if(grocery.unitDatabaseIdentifier == GRCUnitInvalidDatabaseIdentifier) { continue; }

		NSUInteger unitIdentifier = grocery.unitDatabaseIdentifier;
		GRCUnit* unit = [[self shoppingListStore] unitForDatabaseIdentifier:unitIdentifier];
		grocery.unit = unit;
	}
}

#pragma mark - 

- (void)initAisleColorizerIfNeeded {
	if(self.aisleColorizer) { return; }
	if(!self.shoppingListStore) { return; }

	GRCShoppingListStore* store = self.shoppingListStore;
	self.aisleColorizer = [[GRCAisleColorizer alloc] initWithShoppingListStore:store];
}

@end