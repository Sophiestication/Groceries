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

#import "GRCUnitPickerViewController.h"

#import "SUIFormViewController.h"

#import "GRCUnit.h"
#import "GRCShoppingListStore.h"

#import "GRCUnitFormatter.h"

#import "NSArray+Additions.h"
#import "UIColor+Interface.h"

@interface GRCUnitPickerViewController()<SUIFormViewControllerDelegate>

@property(nonatomic, strong) GRCShoppingListStore* store;
@property(nonatomic, strong) GRCUnitFormatter* unitFormatter;
@property(nonatomic, strong) NSArray* sections;
@property(nonatomic, strong) UIBarButtonItem* insertUnitButtonItem;

@end

@implementation GRCUnitPickerViewController

static NSInteger const DefaultUnitSectionIndex = 0;
static NSInteger const StandardUnitsSectionIndex = 1;

#pragma mark - Construction & Destruction

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore {
	if((self = [super initWithStyle:UITableViewStyleGrouped])) {
		self.store = shoppingListStore;
		self.unitFormatter = [[GRCUnitFormatter alloc] initWithUnitStyle:GRCUnitFormatterStyleTitleForDisplaying];
		
		self.navigationItem.title = NSLocalizedString(@"PROPERTY_LABEL_UNIT", nil);
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:GRCShoppingListStoreLocaleDidChangeNotification object:nil];
}

#pragma mark - UnitPickerViewController

- (void)insertUnit:(id)sender {
	[self editUnitAtIndexPath:nil];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// button items
	self.insertUnitButtonItem = [[UIBarButtonItem alloc]
		initWithTitle:NSLocalizedString(@"NEW_UNIT_BUTTONITEM", nil)
		style:UIBarButtonItemStyleBordered
		target:self
		action:@selector(insertUnit:)];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	self.tableView.allowsSelectionDuringEditing = YES;

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(shoppingListStoreLocaleDidChange:)
		name:GRCShoppingListStoreLocaleDidChangeNotification
		object:nil];

	[self reloadAllAndSelectUnit:[self selectedUnit] animated:NO];
	[self deselectUnit:[self selectedUnit] animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];

	UIBarButtonItem* buttonItem = editing ? self.insertUnitButtonItem : nil;
	[[self navigationItem] setLeftBarButtonItem:buttonItem animated:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows = [[[self sections] objectAtIndex:section] count];
	return numberOfRows;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	static NSString* reuseIdentifier = @"regular";
			
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if(!cell) { cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]; }
			
	GRCUnit* unit = [self unitForIndexPath:indexPath];
	GRCUnit* defaultUnit = self.store.defaultUnit;
		
	BOOL selected = [unit isEqual:[self selectedUnit]] ||
		(!self.selectedUnit && [unit isEqual:defaultUnit]);
		
	cell.textLabel.text = [[self unitFormatter] stringForUnit:unit];

	cell.textLabel.textColor = selected ?
		[UIColor blueTableViewCellTextColor] :
		[UIColor tableViewCellTextColor];

	cell.accessoryType = selected ?
		UITableViewCellAccessoryCheckmark :
		UITableViewCellAccessoryNone;
	cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;

	if(unit == defaultUnit) {
		cell.shouldIndentWhileEditing = NO;
		cell.editingAccessoryType = UITableViewCellAccessoryNone;
	}

	return cell;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == DefaultUnitSectionIndex) { return NO; }
	return YES;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	GRCUnit* unit = [self unitForIndexPath:indexPath];
	
	if(unit) {
		if(unit == self.selectedUnit) {
			self.selectedUnit = self.store.defaultUnit;
			
			// This might lead into side effects one day
			id delegate = self.delegate;
	
			if([delegate respondsToSelector:@selector(unitPickerController:didFinishPickingUnit:)]) {
				[delegate unitPickerController:self didFinishPickingUnit:[self selectedUnit]];
			}
		}
		
		[[self store] deleteUnit:unit error:nil];
		
		[self resetSections];
		
		[[self tableView]
			deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
			withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
	if(indexPath.section == StandardUnitsSectionIndex) {
		if([self unitForIndexPath:indexPath]) {
			return YES;
		}
	}
	
	return NO;
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath {
	if(sourceIndexPath.section != StandardUnitsSectionIndex) { return; }
	
	GRCUnit* unit = [self unitForIndexPath:sourceIndexPath];
	[[self store] insertUnit:unit atIndex:[destinationIndexPath row] error:nil];
}

#pragma mark - UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView*)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath {
	if(proposedDestinationIndexPath.section != StandardUnitsSectionIndex) {
		return [NSIndexPath indexPathForRow:0 inSection:StandardUnitsSectionIndex];
	}
	
	NSInteger numberOfRows = [tableView numberOfRowsInSection:[proposedDestinationIndexPath section]];
	
	if(proposedDestinationIndexPath.row + 1 >= numberOfRows) {
		return [NSIndexPath indexPathForRow:numberOfRows - 2 inSection:StandardUnitsSectionIndex];
	}
	
	return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if(tableView.editing && indexPath.section != DefaultUnitSectionIndex) {
		[self editUnitAtIndexPath:indexPath];
	} else {
		[self pickUnitAtIndexPath:indexPath];
	}
}

#pragma mark - SUIFormViewControllerDelegate

- (void)formControllerDidSave:(SUIFormViewController*)controller {
	self.editing = NO;
	
	GRCShoppingListStore* store = self.store;
	
	NSDictionary* formObject = [[[controller fields] firstObject] objectForKey:SUIFormViewControllerObjectKey];
	GRCUnit* unit;
	
	if(formObject[@"identifier"]) {
		NSUInteger unitIdentifier = [[formObject objectForKey:@"identifier"] unsignedIntegerValue];
		unit = [store unitForDatabaseIdentifier:unitIdentifier];
		
		NSString* singularTitle = [GRCUnitFormatter localizedStringForUnit:unit unitStyle:GRCUnitFormatterStyleSingular];
		if(![singularTitle isEqualToString:[formObject objectForKey:@"singular"]]) { unit.customSingularTitle = formObject[@"singular"]; }
		
		NSString* pluralTitle = [GRCUnitFormatter localizedStringForUnit:unit unitStyle:GRCUnitFormatterStylePlural];
		if(![pluralTitle isEqualToString:[formObject objectForKey:@"plural"]]) { unit.customPluralTitle = formObject[@"plural"]; }
		
		NSString* abbreviation = [GRCUnitFormatter localizedStringForUnit:unit unitStyle:GRCUnitFormatterStyleAbbreviation];
		if(![abbreviation isEqualToString:[formObject objectForKey:@"abbreviation"]]) { unit.customAbbreviation = formObject[@"abbreviation"]; }
	} else {
		unit = [store newUnit];
		
		unit.customSingularTitle = formObject[@"singular"];
		unit.customPluralTitle = formObject[@"plural"];
		unit.customAbbreviation = formObject[@"abbreviation"];
	}
	
	[[self store] saveUnit:unit error:nil];
	
	[self reloadAllAndSelectUnit:unit animated:NO];
	
	[[self navigationController] popToViewController:self animated:YES];
}

- (void)formControllerDidCancel:(SUIFormViewController*)controller {
	[[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - GRCShoppingListStoreLocaleDidChangeNotification

- (void)shoppingListStoreLocaleDidChange:(NSNotification*)notification {
	self.unitFormatter.locale = [[notification userInfo] objectForKey:GRCShoppingListStoreLocaleKey];

	[self resetSections];
	[[self tableView] reloadData];
}

#pragma mark - Private

- (NSIndexPath*)indexPathForUnit:(GRCUnit*)unit {
	NSInteger sectionIndex = 0;
	NSInteger rowIndex = 0;
	
	for(NSArray* section in _sections) {
		for(GRCUnit* otherUnit in section) {
			if([otherUnit isEqual:unit]) {
				return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
			}
			
			++rowIndex;
		}
	
		++sectionIndex;
		rowIndex = 0;
	}
	
	return nil;
}

- (GRCUnit*)unitForIndexPath:(NSIndexPath*)indexPath {
	if(!indexPath) { return nil; }
	
	NSArray* section = [_sections objectAtIndex:[indexPath section]];
	
	if(section.count > indexPath.row) {
		return [section objectAtIndex:[indexPath row]];
	}
	
	return nil;
}

- (void)scrollToSelectedUnit {
	NSIndexPath* indexPath = [self indexPathForUnit:[self selectedUnit]];
	
	if(indexPath) {
		[[self tableView] scrollToRowAtIndexPath:indexPath
			atScrollPosition:UITableViewScrollPositionMiddle
			animated:NO];
	}
}

- (void)resetSections {
	GRCUnit* defaultUnit = self.store.defaultUnit;
	
	NSMutableArray* units = [[[self store] units] mutableCopy];
	[units removeObject:defaultUnit];

	self.sections = @[
		defaultUnit ? @[ defaultUnit ] : @[ ],
		units ? units : @[ ]];
}

- (void)reloadAllAndSelectUnit:(GRCUnit*)unit animated:(BOOL)animated {
	[self resetSections];
	[[self tableView] reloadData];

	NSIndexPath* indexPath = [self indexPathForUnit:unit];
	if(!indexPath) { return; }

	[[self tableView]
		selectRowAtIndexPath:indexPath
		animated:animated
		scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)deselectUnit:(GRCUnit*)unit animated:(BOOL)animated {
	NSIndexPath* indexPath = [self indexPathForUnit:unit];
	if(!indexPath) { return; }

	[[self tableView] deselectRowAtIndexPath:indexPath animated:animated];
}

- (void)pickUnitAtIndexPath:(NSIndexPath*)indexPath {
	// deselect the previously selected unit
	GRCUnit* selectedUnit = self.selectedUnit;
	
	if(selectedUnit) {
		NSUInteger aisleIndex = 0;
		UITableViewCell* selectedCell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:aisleIndex inSection:StandardUnitsSectionIndex]];
		
		selectedCell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		UITableViewCell* selectedCell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:DefaultUnitSectionIndex]];
		selectedCell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	// select the new one
	UITableViewCell* cell = [[self tableView] cellForRowAtIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	[[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
	
	self.selectedUnit = [self unitForIndexPath:indexPath];

	// notify our delegate
	id delegate = self.delegate;
	
	if([delegate respondsToSelector:@selector(unitPickerController:didFinishPickingUnit:)]) {
		[delegate unitPickerController:self didFinishPickingUnit:[self selectedUnit]];
	}
}

- (void)editUnitAtIndexPath:(NSIndexPath*)indexPath {
	GRCUnit* unit = [self unitForIndexPath:indexPath];
	
	NSMutableDictionary* formObject = [NSMutableDictionary dictionaryWithCapacity:4];
	
	if(unit) {
		formObject[@"identifier"] = @(unit.unitDatabaseIdentifier);
		
		NSString* string = [GRCUnitFormatter localizedStringForUnit:unit unitStyle:GRCUnitFormatterStyleSingular];
		[formObject setValue:string forKey:@"singular"];
		
		string = [GRCUnitFormatter localizedStringForUnit:unit unitStyle:GRCUnitFormatterStylePlural];
		[formObject setValue:string forKey:@"plural"];
		
		string = [GRCUnitFormatter localizedStringForUnit:unit unitStyle:GRCUnitFormatterStyleAbbreviation];
		[formObject setValue:string forKey:@"abbreviation"];
	}
		
	SUIFormViewController* viewController = [SUIFormViewController viewController];
		
	viewController.fields = @[
		@{	SUIFormViewControllerObjectKey: formObject,
			SUIFormViewControllerPropertyKey: @"singular",
			SUIFormViewControllerMandatoryKey: @(YES),
			SUIFormViewControllerPlaceholderKey: NSLocalizedString(@"PROPERTY_LABEL_NAME", nil) },
		@{	SUIFormViewControllerObjectKey: formObject,
			SUIFormViewControllerPropertyKey: @"plural",
			SUIFormViewControllerPlaceholderKey: NSLocalizedString(@"PROPERTY_LABEL_PLURAL_NAME", nil) },
		@{	SUIFormViewControllerObjectKey: formObject,
			SUIFormViewControllerPropertyKey: @"abbreviation",
			SUIFormViewControllerPlaceholderKey: NSLocalizedString(@"PROPERTY_LABEL_ABBREVIATION", nil) }
	];

	// use a different title if this unit is new
	if(!unit) {
		viewController.title = NSLocalizedString(@"NEW_UNIT_NAVIGATIONITEM_TITLE", nil);
	}
		
	viewController.delegate = self;

	[[self navigationController] pushViewController:viewController animated:YES];
}

@end
