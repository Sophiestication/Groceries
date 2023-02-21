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

#import "GRCAislePickerViewController.h"

#import "GRCAisleDetailsViewController.h"

#import "GRCShoppingListStore.h"
#import "GRCAisle.h"
#import "GRCAisleFormatter.h"
#import "GRCAisleColorizer.h"

#import "NSArray+Additions.h"
#import "UIColor+Interface.h"
#import "UIImage+Aisle.h"

@interface GRCAislePickerViewController()<GRCAisleDetailsViewControllerDelegate>

@property(nonatomic, strong) NSArray* aisles;
@property(nonatomic, readwrite, strong) GRCShoppingListStore* shoppingListStore;
@property(nonatomic, strong) GRCAisleFormatter* aisleFormatter;
@property(nonatomic, strong) GRCAisleColorizer* aisleColorizer;
@property(nonatomic, strong) UIBarButtonItem* insertAisleButtonItem;
@property(nonatomic) BOOL needsToScrollToSelectedAisle;

@end

@implementation GRCAislePickerViewController

static NSInteger const UnspecifiedAisleSectionIndex = 0;
static NSInteger const AisleSectionIndex = 1;

#pragma mark - Construction & Destruction

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore {
	return [self initWithShoppingListStore:shoppingListStore style:UITableViewStyleGrouped];
}

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore style:(UITableViewStyle)style; {
	if((self = [super initWithStyle:style])) {
		self.shoppingListStore = shoppingListStore;

		self.navigationItem.title = NSLocalizedString(@"AISLE_NAVIGATIONITEM_TITLE", nil);

		self.showsSelectionIndicator = YES;
		self.allowsModifications = YES;

		self.aisleFormatter = [[GRCAisleFormatter alloc] init];

		self.aisleColorizer = [[GRCAisleColorizer alloc] initWithShoppingListStore:shoppingListStore];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GRCShoppingListStoreLocaleDidChangeNotification object:nil];
}

#pragma mark - GRCAislePickerViewController

- (void)insertAisle:(id)sender {
	[self editAisleAtIndexPath:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// prompt
	UIViewController* viewController = self.navigationController.viewControllers.firstObject;
	NSString* prompt = viewController.navigationItem.prompt;
	self.navigationItem.prompt = prompt;

	// button items
	if(self.showsSelectionIndicator) {
		self.insertAisleButtonItem = [[UIBarButtonItem alloc]
			initWithTitle:NSLocalizedString(@"NEWAISLE_BUTTONITEM", nil)
			style:UIBarButtonItemStyleBordered
			target:self
			action:@selector(insertAisle:)];

		self.navigationItem.rightBarButtonItem = [self editButtonItem];
	}

	// ...
	self.tableView.allowsSelectionDuringEditing = YES;

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(shoppingListStoreLocaleDidChange:)
		name:GRCShoppingListStoreLocaleDidChangeNotification
		object:nil];

	self.needsToScrollToSelectedAisle = YES;
	[self reloadAllAisles];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if(self.needsToScrollToSelectedAisle) {
		[self scrollToAisle:[self selectedAisle] animated:animated];
		self.needsToScrollToSelectedAisle = NO;
	}
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];

	UIBarButtonItem* buttonItem = editing ? self.insertAisleButtonItem : nil;
	[[self navigationItem] setLeftBarButtonItem:buttonItem animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == UnspecifiedAisleSectionIndex) { return 1; }
	if(section == AisleSectionIndex) { return self.aisles.count; }
	return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if(indexPath.section == UnspecifiedAisleSectionIndex) {
		static NSString* reuseIdentifier = @"regular";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
		}
		
		cell.textLabel.text = NSLocalizedString(@"UNSPECIFIED_AISLE_TITLE", @"");

		if(!self.selectedAisle && self.showsSelectionIndicator) {
			cell.imageView.image = [UIImage imageNamed:@"placeholder-32" style:nil];
		} else {
			cell.imageView.image = [UIImage imageNamed:@"placeholder-32" style:nil];
		}

		cell.imageView.tintColor = [UIColor darkTextColor];

//		cell.imageView.highlightedImage = [UIImage imageNamed:@"placeholder-32" style:SUITableViewCellSelectedImageStyle];

		cell.shouldIndentWhileEditing = NO;

		cell.textLabel.textColor = !self.selectedAisle && self.showsSelectionIndicator ?
			[UIColor blueTableViewCellTextColor] :
			[UIColor tableViewCellTextColor];
		
		if(self.showsSelectionIndicator) {
			cell.accessoryType = cell.editingAccessoryType = self.selectedAisle == nil ?
				UITableViewCellAccessoryCheckmark :
				UITableViewCellAccessoryNone;
		}

		return cell;
	}
	
	if(indexPath.section == AisleSectionIndex) {
		static NSString* reuseIdentifier = @"aisle";
		
		UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
		
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
		}
		
		GRCAisle* aisle = [[self aisles] objectAtIndex:[indexPath row]];
		
		cell.textLabel.text = [[self aisleFormatter] stringForAisle:aisle];

		NSString* aisleImageName = aisle.image;

		if(self.showsSelectionIndicator && aisle == self.selectedAisle) {
			cell.imageView.image = [UIImage aisleImageNamed:aisleImageName size:32 style:nil];
		} else {
			cell.imageView.image = [UIImage aisleImageNamed:aisleImageName size:32 style:nil];
		}

//		cell.imageView.highlightedImage = [UIImage aisleImageNamed:aisleImageName size:32 style:SUITableViewCellSelectedImageStyle];

		if(self.allowsModifications) {
			UIColor* tintColor = [[self aisleColorizer] tintColorForAisle:aisle];
			cell.imageView.tintColor = tintColor;
		} else {
			cell.imageView.tintColor = [UIColor darkTextColor];
		}

		if(self.showsSelectionIndicator) {
			cell.accessoryType = aisle == self.selectedAisle ?
				UITableViewCellAccessoryCheckmark :
				UITableViewCellAccessoryNone;
		}

		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		cell.showsReorderControl = YES;
			
		cell.textLabel.textColor =  aisle == self.selectedAisle ?
			[UIColor blueTableViewCellTextColor] :
			[UIColor tableViewCellTextColor];

		return cell;
	}
	
	return nil;
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
	if(self.allowsModifications) { return indexPath.section == AisleSectionIndex; }
	return NO;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
	GRCAisle* aisle = [self aisleForRowAtIndexPath:fromIndexPath];
	
	[[self shoppingListStore] insertAisle:aisle atIndex:[toIndexPath row] error:nil];
	self.aisles = self.shoppingListStore.aisles;

	// [self updateTintColorsForVisibleAislesAnimated:YES];
	[self performSelector:@selector(updateTintColorsForVisibleAislesAnimated) withObject:nil afterDelay:0.0];
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if(editingStyle != UITableViewCellEditingStyleDelete) { return; }

	GRCAisle* aisle = [self aisleForRowAtIndexPath:indexPath];
	[[self shoppingListStore] deleteAisle:aisle error:nil];

	self.aisles = self.shoppingListStore.aisles;
	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];

	[self performSelector:@selector(updateTintColorsForVisibleAislesAnimated) withObject:nil afterDelay:0.0];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if(self.editing && indexPath.section == AisleSectionIndex) {
		[self editAisleAtIndexPath:indexPath];
		return;
	}

	[self pickAisleAtIndexPath:indexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(!self.allowsModifications) { return UITableViewCellEditingStyleNone; }
	if(indexPath.section == UnspecifiedAisleSectionIndex) { return UITableViewCellEditingStyleNone; }
	if(indexPath.section == AisleSectionIndex && indexPath.row >= self.aisles.count) { return UITableViewCellEditingStyleInsert; }
	return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView*)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == UnspecifiedAisleSectionIndex) { return NO; }
	return YES;
}

- (NSIndexPath*)tableView:(UITableView*)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath {
	if(proposedDestinationIndexPath.section != AisleSectionIndex) {
		return [NSIndexPath indexPathForRow:0 inSection:AisleSectionIndex];
	}

	return proposedDestinationIndexPath;
}

#pragma mark - AisleDetailsViewControllerDelegate

- (void)aisleDetailsViewController:(GRCAisleDetailsViewController*)picker didSaveAisle:(GRCAisle*)aisle {
	self.editing = NO;
	[self reloadAllAislesAndSelectAisle:aisle animated:NO];
	
	[[self navigationController] popToViewController:self animated:YES];
}

- (void)aisleDetailsViewControllerDidCancel:(GRCAisleDetailsViewController*)picker {
	[[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - GRCShoppingListStoreLocaleDidChangeNotification

- (void)shoppingListStoreLocaleDidChange:(NSNotification*)notification {
	self.aisleFormatter.locale = [[notification userInfo] objectForKey:GRCShoppingListStoreLocaleKey];
	[self reloadAllAislesAndSelectAisle:[self selectedAisle] animated:NO];
}

#pragma mark - Private

- (GRCAisle*)aisleForRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section != AisleSectionIndex) { return nil; }
	if(indexPath.row >= self.aisles.count) { return nil; }

	return [[self aisles] objectAtIndex:[indexPath row]];
}

- (NSIndexPath*)indexPathForAisle:(GRCAisle*)aisle {
	if(!aisle) { return nil; }

	NSUInteger aisleIndex = [[self aisles] indexOfObject:aisle];
	if(aisleIndex == NSNotFound) { return nil; }

	return [NSIndexPath indexPathForRow:aisleIndex inSection:AisleSectionIndex];
}

- (void)pickAisleAtIndexPath:(NSIndexPath*)indexPath {
	// determine the aisle to select
	GRCAisle* newAisle = indexPath.section == AisleSectionIndex ?
		[[self aisles] objectAtIndex:[indexPath row]] :
		nil;
	
	// first ask our delegate if we can pick this aisle
	id delegate = self.delegate;
	
	if([delegate respondsToSelector:@selector(shouldAislePicker:pickAisle:)]) {
		if(![delegate shouldAislePicker:self pickAisle:newAisle]) {
			return;
		}
	}

	// deselect the previously selected aisle
	GRCAisle* selectedAisle = self.selectedAisle;
	
	if(selectedAisle) {
		NSUInteger aisleIndex = [[self aisles] indexOfObject:selectedAisle];
		UITableViewCell* selectedCell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:aisleIndex inSection:AisleSectionIndex]];
		
		selectedCell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		UITableViewCell* selectedCell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:UnspecifiedAisleSectionIndex]];
		selectedCell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	// selecte the new one
	UITableViewCell* cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	
	if(self.showsSelectionIndicator) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}

//	[[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
	
	self.selectedAisle = newAisle;
	
	// notify our delegate
	if([delegate respondsToSelector:@selector(aislePicker:didFinishPickingAisle:)]) {
		[delegate aislePicker:self didFinishPickingAisle:newAisle];
	}
}

- (void)editAisleAtIndexPath:(NSIndexPath*)indexPath {
	GRCAisleDetailsViewController* viewController = [[GRCAisleDetailsViewController alloc] initWithShoppingListStore:[self shoppingListStore]];

	GRCAisle* newAisle = [self aisleForRowAtIndexPath:indexPath];
	if(!newAisle) { newAisle = [[self shoppingListStore] newAisle]; }

	viewController.aisle = newAisle;
	viewController.delegate = self;

	[[self navigationController] pushViewController:viewController animated:YES];
}

- (void)reloadAllAisles {
	self.aisles = [[self shoppingListStore] aisles];
	[[self tableView] reloadData];
}

- (void)reloadAllAislesAndSelectAisle:(GRCAisle*)aisle animated:(BOOL)animated {
	[self reloadAllAisles];

	NSIndexPath* indexPath = [self indexPathForAisle:aisle];
	if(!indexPath) { return; }

	[[self tableView]
		selectRowAtIndexPath:indexPath
		animated:animated
		scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)scrollToAisle:(GRCAisle*)aisle animated:(BOOL)animated {
	NSIndexPath* indexPath = [self indexPathForAisle:aisle];
	if(!indexPath) { return; }

	[[self tableView] scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:animated];
}

#pragma mark -

- (void)updateTintColorsForVisibleAislesAnimated {
	[self updateTintColorsForVisibleAislesAnimated:YES];
}

- (void)updateTintColorsForVisibleAislesAnimated:(BOOL)animated {
	UITableView* tableView = self.tableView;
	NSArray* indexPathsForVisibleRows = tableView.indexPathsForVisibleRows;

	void (^animations)() = ^() {
		for(NSIndexPath* indexPath in indexPathsForVisibleRows) {
			if(indexPath.section != AisleSectionIndex) { continue; }

			GRCAisle* aisle = [[self aisles] objectAtIndex:[indexPath row]];

			UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
			cell.imageView.tintColor = [[self aisleColorizer] tintColorForAisle:aisle];
		}
	};

	if(animated) {
		[UIView
			animateWithDuration:0.333
			delay:0.0
			options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
			animations:animations
			completion:nil];
	} else {
		animations();
	}
}

@end
