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

#import "GRCShoppingListPickerViewController.h"

#import "SUIFormViewController.h"

#import "GRCShoppingListStore+Private.h"
#import "GRCShoppingList+Private.h"

#import "UIColor+Tint.h"
#import "UINavigationController+AisleTints.h"

@interface GRCShoppingListPickerViewController()<SUIFormViewControllerDelegate>

@property(nonatomic, strong) UIBarButtonItem* cancelButtonItem;

@property(nonatomic, readwrite, strong) GRCShoppingListStore* shoppingListStore;
@property(nonatomic, strong) NSArray* sections;
@property(nonatomic, strong) NSSet* shoppingLists;

@property(nonatomic) BOOL registeredAsConsumer;

@end

@implementation GRCShoppingListPickerViewController

#pragma mark - Construction & Destruction

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore {
	return [self initWithShoppingListStore:shoppingListStore style:UITableViewStyleGrouped];
}

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore style:(UITableViewStyle)style {
    if((self = [super initWithStyle:style])) {
		self.shoppingListStore = shoppingListStore;
		self.allowsModifications = YES;

		self.hidesBottomBarWhenPushed = YES;
		
		self.title = NSLocalizedString(@"LISTS_NAVIGATIONITEM_TITLE", nil);
    }

    return self;
}

- (void)dealloc {
	[self unregisterAsConsumer];
}

#pragma mark - GRCShoppingListPickerViewController

- (void)cancel:(id)sender {
	if([[self delegate] respondsToSelector:@selector(shoppingListPickerDidCancel:)]) {
		[[self delegate] shoppingListPickerDidCancel:self];
	}
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if(self.allowsModifications) {
		self.navigationItem.leftBarButtonItem = [self editButtonItem];
	
//		self.cancelButtonItem = [[UIBarButtonItem alloc]
//			initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//			target:self
//			action:@selector(cancel:)];
//		self.navigationItem.rightBarButtonItem = self.cancelButtonItem;
	}
	
	self.navigationItem.backBarButtonItem.possibleTitles = [NSSet setWithObjects:
		NSLocalizedString(@"LISTS_NAVIGATIONITEM_TITLE", nil),
		NSLocalizedString(@"LISTS_NAVIGATIONITEM_SHORTTITLE", nil),
		nil];

	self.tableView.allowsSelectionDuringEditing = YES;
		
	[self registerAsConsumerIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[[self navigationController] setTintColor:nil animated:animated];
	[[self navigationController] setToolbarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self registerAsConsumerIfNeeded]; // we might have unregistered after pushing a view controller
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	if(!self.allowsModifications) { editing = NO; }
	
	[super setEditing:editing animated:animated];

	if(!self.allowsModifications) { return; } // leave the button items as is if needed
	
	UIBarButtonItem* rightButtonItem = editing ?
		nil :
		self.cancelButtonItem;
	[[self navigationItem] setRightBarButtonItem:rightButtonItem animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return self.sections.count;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	return self.sections[section][@"title"];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray* shoppingLists = self.sections[section][@"shoppingLists"];
	return [shoppingLists count] + 1;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:
		[[self class] regularCellReuseIdentifier]];

	if(!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:[[self class] regularCellReuseIdentifier]];
	}

	[self configureShoppingListCell:cell forRowAtIndexPath:indexPath];

	return cell;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if(editingStyle == UITableViewCellEditingStyleInsert) {
		[self editShoppingListAtIndexPath:indexPath animated:YES];
	}

	if(editingStyle == UITableViewCellEditingStyleDelete) {
		GRCShoppingList* shoppingList = [self shoppingListForRowAtIndexPath:indexPath];
		if(!shoppingList) { return; }

		if([[self selectedShoppingList] isEqual:shoppingList]) {
			self.selectedShoppingList = nil;
		}
	
		NSError* error;
	
		if(![[self shoppingListStore] deleteShoppingList:shoppingList error:&error]) {
			NSLog(@"Could not delete shopping list: %@", error);
		}

		NSMutableSet* newShoppingLists = [NSMutableSet setWithSet:[self shoppingLists]];
		[newShoppingLists removeObject:shoppingList];
	
		[self updateSectionsIfNeeded:newShoppingLists animated:YES];
	}
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingList* shoppingList = [self shoppingListForRowAtIndexPath:indexPath];
	return shoppingList != nil;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
	NSArray* sections = self.sections;
	if(sourceIndexPath.section >= sections.count) { return; }

	NSDictionary* section = [sections objectAtIndex:[sourceIndexPath section]];

	NSArray* shoppingLists = [section objectForKey:@"shoppingLists"];
	if(sourceIndexPath.row >= shoppingLists.count) { return; }

	__autoreleasing GRCShoppingList* shoppingList = [shoppingLists objectAtIndex:[sourceIndexPath row]];

	NSMutableArray* newShoppingLists = [NSMutableArray arrayWithArray:shoppingLists];

	[newShoppingLists removeObjectAtIndex:[sourceIndexPath row]];
	[newShoppingLists insertObject:shoppingList atIndex:[destinationIndexPath row]];

	NSMutableDictionary* newSection = [section mutableCopy];
	newSection[@"shoppingLists"] = newShoppingLists;

	NSMutableArray* newSections = [sections mutableCopy];
	newSections[sourceIndexPath.section] = newSection;

	self.sections = newSections;

	[self updateShoppingListSortOrders:newShoppingLists];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingList* shoppingList = [self shoppingListForRowAtIndexPath:indexPath];
	
	if(self.editing || !shoppingList) {
		[self editShoppingListAtIndexPath:indexPath animated:YES];
	} else {
		[self pickShoppingListAtIndexPath:indexPath];
	}
}

- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingList* shoppingList = [self shoppingListForRowAtIndexPath:indexPath];
	
	if([[self delegate] respondsToSelector:@selector(shoppingListPicker:accessoryButtonTappedForShoppingList:)]) {
		[(id<GRCShoppingListPickerViewDelegateAccessory>)[self delegate] shoppingListPicker:self accessoryButtonTappedForShoppingList:shoppingList];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(!self.allowsModifications) { return UITableViewCellEditingStyleNone; }

	NSArray* shoppingLists = self.sections[indexPath.section][@"shoppingLists"];
	return indexPath.row < shoppingLists.count ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleInsert;
}

- (NSIndexPath*)tableView:(UITableView*)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath {
	NSUInteger numberOfRowsInSourceSection = [tableView numberOfRowsInSection:[sourceIndexPath section]];

	if(sourceIndexPath.section < proposedDestinationIndexPath.section) {
		return [NSIndexPath indexPathForRow:numberOfRowsInSourceSection - 1 inSection:[sourceIndexPath section]];
	}

	if(sourceIndexPath.section > proposedDestinationIndexPath.section) {
		return [NSIndexPath indexPathForRow:0 inSection:[sourceIndexPath section]];
	}

	// prevent dragging beyond the "New Shopping List…" cell
	if(proposedDestinationIndexPath.row + 1 >= numberOfRowsInSourceSection) {
		return [NSIndexPath indexPathForRow:numberOfRowsInSourceSection - 2 inSection:[sourceIndexPath section]];
	}

	return proposedDestinationIndexPath;
}

#pragma mark - SUIFormViewControllerDelegate

- (void)formControllerDidSave:(SUIFormViewController*)controller {
	NSDictionary* fieldObject = controller.fields[0][@"object"];

	GRCShoppingList* shoppingList = fieldObject[@"shoppingList"];
	NSString* title = fieldObject[@"title"];
	
	BOOL shouldPickShoppingList = NO;
	NSSet* newShoppingLists = nil;
	
	if(!shoppingList) {
		shoppingList = [[self shoppingListStore] newShoppingList];
		// shoppingList.calendar.source = fieldObject[@"source"];
		
		newShoppingLists = [[self shoppingLists] setByAddingObject:shoppingList];
		
		if(self.allowsModifications) {
			shouldPickShoppingList = YES;
		}
	}
	
	shoppingList.title = title;
	
	NSError* error;
	if(![[self shoppingListStore] saveShoppingList:shoppingList error:&error]) {
		NSLog(@"Could not save shopping list: %@", error);
	}
	
	self.editing = NO;

	if(newShoppingLists) {
		[self updateSectionsIfNeeded:newShoppingLists animated:NO];
	}

	NSIndexPath* selectedIndexPath = [self indexPathForShoppingList:shoppingList];
	if(selectedIndexPath) {
		[[self tableView] selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	}
	
	if(shouldPickShoppingList) {
		[self pickShoppingListAtIndexPath:selectedIndexPath];
	} else {
		[[self navigationController] popToViewController:self animated:YES];
	}
}

- (void)formControllerDidCancel:(SUIFormViewController*)controller {
	[[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - Private

+ (NSString*)regularCellReuseIdentifier { return @"regular"; }

- (void)registerAsConsumerIfNeeded {
	if(self.registeredAsConsumer) { return; }

	__block __weak GRCShoppingListPickerViewController* picker = self;

	[[picker shoppingListStore] addConsumer:self callback:^(NSSet* shoppingLists, NSArray* changes) {
		if(self.editing) { return; }
		[picker updateSectionsIfNeeded:shoppingLists animated:YES];
	}];

	self.registeredAsConsumer = YES;
}

- (void)unregisterAsConsumer {
	[[self shoppingListStore] removeConsumer:self];
	self.registeredAsConsumer = NO;
}

- (GRCShoppingList*)shoppingListForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSArray* shoppingLists = self.sections[indexPath.section][@"shoppingLists"];
	return indexPath.row < shoppingLists.count ? [shoppingLists objectAtIndex:[indexPath row]] : nil;
}

- (NSIndexPath*)indexPathForShoppingList:(GRCShoppingList*)shoppingList {
	return [self indexPathForShoppingList:shoppingList sections:[self sections]];
}

- (NSIndexPath*)indexPathForShoppingList:(GRCShoppingList*)shoppingList sections:(NSArray*)sections {
	for(NSDictionary* section in sections) {
		NSInteger rowIndex = [[section objectForKey:@"shoppingLists"] indexOfObject:shoppingList];
		if(rowIndex == NSNotFound) { continue; }
		
		NSInteger sectionIndex = [sections indexOfObject:section];
		return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
	}
	
	return nil;
}

- (void)configureShoppingListCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingList* shoppingList = [self shoppingListForRowAtIndexPath:indexPath];
	
	if(shoppingList) {
//		cell.imageView.image = [UIImage imageNamed:@"shoppinglist"];
		cell.textLabel.text = shoppingList.title;
		
//		cell.accessoryType = [[self selectedShoppingList] isEqual:shoppingList] ?
//			UITableViewCellAccessoryCheckmark :
//			UITableViewCellAccessoryNone;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;

		NSUInteger numberOfItems = shoppingList.numberOfRemainingItems;
		NSString* badgeText = numberOfItems > 0 ?
			[NSNumberFormatter localizedStringFromNumber:@(numberOfItems) numberStyle:NSNumberFormatterDecimalStyle] :
			nil;
		cell.detailTextLabel.text = badgeText;
		cell.textLabel.textColor = nil;
	} else {
//		cell.imageView.image = [UIImage imageNamed:@"shoppinglist-new"];
		cell.textLabel.text = NSLocalizedString(@"SHOPPINGLIST_ORGANIZER_NEW_SHOPPINGLIST", nil);
		cell.accessoryType = cell.editingAccessoryType = UITableViewCellAccessoryNone;
	
		cell.detailTextLabel.text = nil;
		cell.textLabel.textColor = self.view.tintColor;
	}
	
	if([[self delegate] respondsToSelector:@selector(shoppingListPicker:shouldShowAccessoryButtonForShoppingList:)]) {
		BOOL shouldShowAccessoryButton = [(id<GRCShoppingListPickerViewDelegateAccessory>)[self delegate] shoppingListPicker:self shouldShowAccessoryButtonForShoppingList:shoppingList];
		
		if(shouldShowAccessoryButton) {
			if(shoppingList) {
				cell.accessoryView = nil;
				cell.accessoryType = UITableViewCellAccessoryDetailButton;
			} else {
				UIButton* accessoryButton = (id)cell.accessoryView;
				
				if(!accessoryButton) {
					accessoryButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
					// accessoryButton.tintColor = [UIColor greenTintColor];
					accessoryButton.userInteractionEnabled = NO;
					
					[accessoryButton sizeToFit];
					
					cell.accessoryView = accessoryButton;
				}
			}
		} else {
			cell.accessoryView = nil;
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}

		// no badge in this configuration
		cell.detailTextLabel.text = nil;
	}
}

- (void)updateSectionsIfNeeded:(NSSet*)shoppingLists animated:(BOOL)animated {
	NSArray* newSections = [self sectionsForShoppingLists:shoppingLists];
	NSMutableSet* newShoppingLists = [NSMutableSet setWithSet:shoppingLists];

	if(self.sections && animated) {
		[[self tableView] beginUpdates]; {

			[self deleteRowsForNewShoppingLists:newShoppingLists oldShoppingLists:[self shoppingLists]];
			[self insertRowsForNewShoppingLists:newShoppingLists newSections:newSections oldShoppingLists:[self shoppingLists]];
			[self updateOrMoveRowsForNewShoppingLists:newShoppingLists newSections:newSections oldShoppingLists:[self shoppingLists] oldSections:[self sections]];

			self.sections = newSections;
			self.shoppingLists = newShoppingLists;

		} [[self tableView] endUpdates];
	} else {
		self.sections = newSections;
		self.shoppingLists = newShoppingLists;

		[[self tableView] reloadData];
	}

	[self updateButtonItems];
}

- (void)deleteRowsForNewShoppingLists:(NSSet*)newShoppingLists oldShoppingLists:(NSSet*)oldShoppingLists {
	NSMutableSet* shoppingListsToDelete = [NSMutableSet setWithSet:oldShoppingLists];
	[shoppingListsToDelete minusSet:newShoppingLists];

	NSMutableArray* rowsToDelete = [NSMutableArray arrayWithCapacity:[shoppingListsToDelete count]];

	for(GRCShoppingList* shoppingList in shoppingListsToDelete) {
		NSIndexPath* indexPath = [self indexPathForShoppingList:shoppingList];
		if(!indexPath) { continue; }

		[rowsToDelete addObject:indexPath];
	}

	if(rowsToDelete.count > 0) {
		[[self tableView] deleteRowsAtIndexPaths:rowsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (void)insertRowsForNewShoppingLists:(NSSet*)newShoppingLists newSections:(NSArray*)newSections oldShoppingLists:(NSSet*)oldShoppingLists {
	NSMutableSet* shoppingListsToInsert = [NSMutableSet setWithSet:newShoppingLists];
	[shoppingListsToInsert minusSet:oldShoppingLists];

	NSMutableArray* rowsToInsert = [NSMutableArray arrayWithCapacity:[shoppingListsToInsert count]];

	for(GRCShoppingList* shoppingList in shoppingListsToInsert) {
		NSIndexPath* indexPath = [self indexPathForShoppingList:shoppingList sections:newSections];
		if(!indexPath) { continue; }

		[rowsToInsert addObject:indexPath];
	}

	if(rowsToInsert.count > 0) {
		[[self tableView] insertRowsAtIndexPaths:rowsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (void)updateOrMoveRowsForNewShoppingLists:(NSSet*)newShoppingLists newSections:(NSArray*)newSections oldShoppingLists:(NSSet*)oldShoppingLists oldSections:(NSArray*)oldSections {
	NSArray* indexPathsForVisibleRows = [[self tableView] indexPathsForVisibleRows];

	for(GRCShoppingList* shoppingList in newShoppingLists) {
		if(![oldShoppingLists member:shoppingList]) { continue; } // shopping list was inserted

		NSIndexPath* newIndexPath = [self indexPathForShoppingList:shoppingList sections:newSections];
		NSIndexPath* oldIndexPath = [self indexPathForShoppingList:shoppingList sections:oldSections];

		if([newIndexPath isEqual:oldIndexPath]) {
			if([indexPathsForVisibleRows containsObject:newIndexPath]) {
				UITableViewCell* cell = [[self tableView] cellForRowAtIndexPath:newIndexPath];
				[self configureShoppingListCell:(id)cell forRowAtIndexPath:newIndexPath];
			}
		}
	}
}

- (NSArray*)sectionsForShoppingLists:(NSSet*)shoppingLists {
	NSMutableArray* sections = [NSMutableArray arrayWithCapacity:1];
	
//	for(EKSource* source in [eventStore sources]) {
		NSArray* shoppingListsInSource = [self shoppingListsForSource:nil inSet:shoppingLists];
		
		BOOL isDefaultSource = YES;
		//BOOL isLocalSource = source.sourceType == EKSourceTypeLocal;

		if(isDefaultSource /*|| isLocalSource*/ || shoppingListsInSource.count > 0) {
			NSDictionary* section = @{
				@"title": [self titleForSource:nil],
				@"shoppingLists": shoppingListsInSource,
				@"isDefaultSource": @(isDefaultSource) };
			[sections addObject:section];
		}
//	}
	
	NSArray* sortDescriptors = @[
		[[NSSortDescriptor alloc] initWithKey:@"isDefaultSource" ascending:NO],
		[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] ];
	[sections sortUsingDescriptors:sortDescriptors];
	
	return sections;
}

- (NSArray*)shoppingListsForSource:(id)source inSet:(NSSet*)array {
	NSMutableArray* shoppingLists = [NSMutableArray array];
	
	for(GRCShoppingList* shoppingList in array) {
//		if(![[[shoppingList calendar] source] isEqual:source]) { continue; }
		[shoppingLists addObject:shoppingList];
	}
	
	NSArray* sortDescriptors = @[
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES],
		[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] ];
	[shoppingLists sortUsingDescriptors:sortDescriptors];
	
	return shoppingLists;
}

- (NSString*)titleForSource:(id)source {
//	EKSourceType sourceType = source.sourceType;
//	if(sourceType != EKSourceTypeLocal) { return source.title; }

	NSString* model = [[UIDevice currentDevice] localizedModel];

	NSString* title = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_EVENTSTORE_TITLE_FORMAT", nil), model];
	return title;
}

- (void)pickShoppingListAtIndexPath:(NSIndexPath*)indexPath {
	GRCShoppingList* shoppingList = [self shoppingListForRowAtIndexPath:indexPath];

	self.selectedShoppingList = shoppingList;

	if([[self delegate] respondsToSelector:@selector(shoppingListPicker:didFinishPickingShoppingList:)]) {
		[[self delegate] shoppingListPicker:self didFinishPickingShoppingList:shoppingList];
	}
}

- (void)editShoppingListAtIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated {
	SUIFormViewController* viewController = [SUIFormViewController viewController];
	
	NSMutableDictionary* fieldObject = [NSMutableDictionary dictionaryWithCapacity:4];
	
	GRCShoppingList* shoppingList = [self shoppingListForRowAtIndexPath:indexPath];
	if(shoppingList.shoppingListIdentifier) { [fieldObject setObject:[shoppingList shoppingListIdentifier] forKey:@"identifier"]; }
	if(shoppingList) { [fieldObject setObject:shoppingList forKey:@"shoppingList"]; }
	
	NSString* title = shoppingList.title;
	if(!title) { title = [[self shoppingListStore] preferredTitleForNewShoppingList]; }
	[fieldObject setObject:title forKey:@"title"];
	
	viewController.fields = @[
		@{	SUIFormViewControllerObjectKey: fieldObject,
			SUIFormViewControllerPropertyKey: @"title",
			SUIFormViewControllerMandatoryKey: @(YES),
			SUIFormViewControllerPlaceholderKey: NSLocalizedString(@"PROPERTY_LABEL_NAME", nil) } ];
	
	viewController.title = NSLocalizedString(@"EDITING_NAVIGATIONITEM_TITLE", nil);
	viewController.navigationItem.prompt = self.navigationItem.prompt;
	
	viewController.delegate = self;
	
	[self unregisterAsConsumer];
	
	[[self navigationController] pushViewController:viewController animated:animated];
}

- (void)updateButtonItems {
	self.cancelButtonItem.enabled = self.selectedShoppingList != nil;
}

- (void)updateShoppingListSortOrders:(NSArray*)orderedShoppingLists {
	[[self shoppingListStore] beginUpdates];

	[orderedShoppingLists enumerateObjectsUsingBlock:^(GRCShoppingList* shoppingList, NSUInteger index, BOOL* stop) {
		if(shoppingList.sortOrder == index) { return; }

		shoppingList.sortOrder = index;
		[[self shoppingListStore] saveShoppingList:shoppingList error:nil];
	}];

	[[self shoppingListStore] endUpdatesAndCommit:YES];
}

@end
