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

#import "GRCImporter.h"

#import "GRCDefaultStore.h"
#import "GRCAisleStore.h"
#import "GRCUnitStore.h"
#import "GRCGroceryStore.h"

#import "GRCAisle.h"
#import "GRCUnit.h"
#import "GRCGrocery.h"

#import "GRCArchiver.h"

#import "GRCZIPUnarchiver.h"
#import "GRCURLUnarchiver.h"

#import "GRCShoppingListStore+Private.h"

#import "NSLocale+Additions.h"
#import "NSString+Additions.h"
#import "NSURL+Groceries.h"

@interface GRCImporter()

@property(nonatomic, copy, readwrite) NSSet* identifiersForImportedShoppingLists;
@property(nonatomic, copy) NSURL* URL;

@property(nonatomic, strong) SQLiteStore* sqliteStore;

@property(nonatomic, strong) GRCAisleStore* aisleStore;
@property(nonatomic, strong) NSMapTable* aisleIdentifierMapping;
@property(nonatomic, strong) NSMutableArray* existingAisles;

@property(nonatomic, strong) GRCUnitStore* unitStore;
@property(nonatomic, strong) NSMapTable* unitIdentifierMapping;
@property(nonatomic, strong) NSMutableArray* existingUnits;

@property(nonatomic, strong) GRCGroceryStore* groceryStore;

@property(nonatomic, strong) NSLocale* locale;

@property(nonatomic, strong) id<GRCUnarchiver> unarchiver;

@end

@implementation GRCImporter

#pragma mark Construction & Destruction

- (id)initWithURL:(NSURL*)URL {
	if((self = [super init])) {
		self.URL = URL;
	}

	return self;
}

#pragma mark - GRCImporter

+ (BOOL)canImportFromURL:(NSURL*)URL {
	if([GRCZIPUnarchiver canUnarchiveURL:URL]) { return YES; }
	if([GRCURLUnarchiver canUnarchiveURL:URL]) { return YES; }
	
	return NO;
}

- (BOOL)importAndReturnError:(NSError* __autoreleasing *)error {
	NSURL* URL = self.URL;

	// unarchive
	id<GRCUnarchiver> unarchiver = [self unarchiverForURL:URL];
	if(![unarchiver unarchiveWithOptions:nil error:error]) {
		return NO;
	}

	self.unarchiver = unarchiver;
	
	// locale
	self.locale = [NSLocale localeWithPreferredLanguageCode];

	// open a default store
	self.sqliteStore = GRCNewDefaultStore();
	
	self.groceryStore = [[GRCGroceryStore alloc] initWithSQLiteStore:[self sqliteStore]];

	[[self sqliteStore] beginTransaction];

	// import aisles
	if(![self importAislesAndReturnError:error]) {
		[[self sqliteStore] cancelTransaction];
		[self finalizeSQLiteStore];

		return NO;
	}
	
	// import units
	if(![self importUnitsAndReturnError:error]) {
		[[self sqliteStore] cancelTransaction];
		[self finalizeSQLiteStore];

		return NO;
	}
	
	// import shopping lists
	if(![self importShoppingListsAndReturnError:error]) {
		[[self sqliteStore] cancelTransaction];
		[self finalizeSQLiteStore];

		return NO;
	}

	[[self sqliteStore] commitTransaction];
	[self finalizeSQLiteStore];
}

#pragma mark Aisles

- (BOOL)importAislesAndReturnError:(NSError* __autoreleasing *)error {
	GRCAisleStore* aisleStore = [[GRCAisleStore alloc] initWithSQLiteStore:[self sqliteStore]];
	self.aisleStore = aisleStore;

	NSMutableArray* existingAisles = [[[aisleStore aisles] allObjects] mutableCopy];
	self.existingAisles = existingAisles;

	for(NSDictionary* aisle in self.unarchiver.aisles) {
		if(![self importAisle:aisle existingAisles:existingAisles error:error]) {
			return NO;
		}
	}

	return YES;
}

- (BOOL)importAisle:(NSDictionary*)aisle existingAisles:(NSMutableArray*)existingAisles error:(NSError* __autoreleasing *)error {
	NSString* identifier = aisle[@"identifier"];
	NSString* title = aisle[@"custom-title"];

	GRCAisle* existingAisle = [self aisleForTitle:title inArray:existingAisles];

	if(existingAisle) {
		// TODO: merge if needed

		if(!self.aisleIdentifierMapping) { self.aisleIdentifierMapping = [NSMapTable strongToStrongObjectsMapTable]; }
		if(identifier) { [[self aisleIdentifierMapping] setObject:[existingAisle aisleIdentifier] forKey:identifier]; }

		return YES;
	} 

	existingAisle = [self aisleForIdentifier:identifier inArray:existingAisles];
	if(existingAisle) { return YES; } // TODO: merge if needed

	GRCAisle* newAisle = [[self aisleStore] newAisle];

	newAisle.aisleIdentifier = identifier;
	if(title.length > 0) { newAisle.customTitle = title; }

	newAisle.image = aisle[@"image"];

	newAisle.custom = [[aisle objectForKey:@"custom"] boolValue];

	newAisle.sortOrder = existingAisles.count + 1;

	if(![[self aisleStore] saveAisle:newAisle error:error]) {
		return NO;
	}

	[existingAisles addObject:newAisle];

	return YES;
}

- (GRCAisle*)aisleForTitle:(NSString*)title inArray:(NSArray*)array {
	if(title.length == 0) { return nil; }

	for(GRCAisle* aisle in array) {
		if(SUIEqualCaseInsensitiveStrings(title, aisle.customTitle)) {
			return aisle;
		}
	}

	return nil;
}

- (GRCAisle*)aisleForIdentifier:(NSString*)identifier inArray:(NSArray*)array {
	for(GRCAisle* aisle in array) {
		if(SUIEqualStrings(identifier, aisle.aisleIdentifier)) {
			return aisle;
		}
	}

	return nil;
}

#pragma mark Units

- (BOOL)importUnitsAndReturnError:(NSError* __autoreleasing *)error {
	GRCUnitStore* unitStore = [[GRCUnitStore alloc] initWithSQLiteStore:[self sqliteStore]];
	self.unitStore = unitStore;

	NSMutableArray* existingUnits = [[[unitStore units] allObjects] mutableCopy];
	self.existingUnits = existingUnits;

	NSArray* unarchivedUnits = self.unarchiver.units;

	for(NSDictionary* unit in unarchivedUnits) {
		if(![self importUnit:unit existingUnits:existingUnits error:error]) {
			return NO;
		}
	}

	return YES;
}

- (BOOL)importUnit:(NSDictionary*)unit existingUnits:(NSMutableArray*)existingUnits error:(NSError* __autoreleasing *)error {
	NSString* identifier = unit[@"identifier"];
	
	NSString* customPluralTitle = unit[@"custom-plural-title"];
	NSString* customSingularTitle = unit[@"custom-singular-title"];
	NSString* customAbbreviationTitle = unit[@"custom-abbreviation"];

	GRCUnit* existingUnit = nil; // TODO: 

	if(existingUnit) {
		// TODO: merge if needed

		if(!self.unitIdentifierMapping) { self.unitIdentifierMapping = [NSMapTable strongToStrongObjectsMapTable]; }
		[[self unitIdentifierMapping] setValue:[existingUnit unitIdentifier] forKey:identifier];

		return YES;
	} 

	existingUnit = [self unitForIdentifier:identifier inArray:existingUnits];
	if(existingUnit) { return YES; } // TODO: merge if needed

	GRCUnit* newUnit = [[self unitStore] newUnit];

	newUnit.unitIdentifier = identifier;

	newUnit.customPluralTitle = customPluralTitle;
	newUnit.customSingularTitle = customSingularTitle;
	newUnit.customAbbreviation = customAbbreviationTitle;

	newUnit.custom = [[unit objectForKey:@"custom"] boolValue];

	newUnit.sortOrder = existingUnits.count + 1;

	if(![[self unitStore] saveUnit:newUnit error:error]) {
		return NO;
	}

	[existingUnits addObject:newUnit];

	return YES;
}

- (GRCUnit*)unitForIdentifier:(NSString*)identifier inArray:(NSArray*)array {
	for(GRCUnit* unit in array) {
		if(SUIEqualStrings(identifier, unit.unitIdentifier)) {
			return unit;
		}
	}

	return nil;
}

#pragma mark - Shopping Lists

- (BOOL)importShoppingListsAndReturnError:(NSError* __autoreleasing *)error {
	NSMutableDictionary* existingShoppingLists = [self existingShoppingLists];
	NSMutableSet* identifiers = [NSMutableSet setWithCapacity:1];
	
	for(NSDictionary* shoppingList in self.unarchiver.shoppingLists) {
		if(![self importShoppingList:shoppingList existingShoppingLists:existingShoppingLists error:error]) {
			return NO;
		}

		[identifiers addObject:[shoppingList objectForKey:@"identifier"]];
	}

	self.identifiersForImportedShoppingLists = identifiers;
	
	return YES;
}

- (BOOL)importShoppingList:(NSDictionary*)shoppingList existingShoppingLists:(NSMutableDictionary*)existingShoppingLists error:(NSError* __autoreleasing *)error {
	NSString* identifier = shoppingList[@"identifier"];
	
	NSDictionary* existingShoppingList = existingShoppingLists[identifier];
	
	if(!existingShoppingList) {
		NSString* title = shoppingList[@"title"];
		existingShoppingList = [self shoppingListForTitle:title inArray:[existingShoppingLists allValues]];
	}
	
	if(existingShoppingList) {
		// merge
		return [self mergeShoppingList:shoppingList withExistingShoppingList:existingShoppingList error:error];
	}
	
	// insert new
	NSMutableDictionary* newShoppingList = [shoppingList mutableCopy];
	if(![self insertNewShoppingList:newShoppingList error:error]) {
		return NO;
	}
	
	return [self importShoppingListItemsForShoppingList:newShoppingList error:error];
}

- (BOOL)mergeShoppingList:(NSDictionary*)shoppingList withExistingShoppingList:(NSDictionary*)existingShoppingList error:(NSError* __autoreleasing *)error {
	id modificationDate = shoppingList[@"modification-date"];
	id otherModificationDate = existingShoppingList[@"modification-date"];
	
	if([self isModificationDate:modificationDate newerThanModificationDate:otherModificationDate]) {
		if(![self updateShoppingList:shoppingList error:error]) {
			return NO;
		}
	}

	NSMutableDictionary* mergedShoppingList = [existingShoppingList mutableCopy];
	[mergedShoppingList setValue:[shoppingList objectForKey:@"deleted-items"] forKey:@"deleted-items"];
	[mergedShoppingList setValue:[shoppingList objectForKey:@"items"] forKey:@"items"];
	
	return [self importShoppingListItemsForShoppingList:mergedShoppingList error:error];
}

- (BOOL)insertNewShoppingList:(NSMutableDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"INSERT INTO shoppinglists (persistent_id, name, modification_date, sort_order) VALUES (:shoppingListIdentifier, :title, DATETIME(:modificationDate, 'unixepoch'), (SELECT MAX(sort_order)+1 FROM shoppinglists))";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:[shoppingList objectForKey:@"identifier"] forKey:@"shoppingListIdentifier"];
	[statement substituteObject:[shoppingList objectForKey:@"title"] forKey:@"title"];
	[statement substituteObject:[shoppingList objectForKey:@"modification-date"] forKey:@"modificationDate"];

	NSUInteger identifier = NSNotFound;

	if(![statement executeAndReturnLastRowIdentifier:&identifier error:error]) {
		NSLog(@"Could not insert shopping list: %@", *error);
		return NO;
	}

	shoppingList[@"database-identifier"] = @(identifier);

	return YES;
}

- (BOOL)updateShoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE shoppinglists SET name=:title WHERE persistent_id=:identifier";
	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	
	[statement substituteObject:[shoppingList objectForKey:@"title"] forKey:@"title"];
	[statement substituteObject:[shoppingList objectForKey:@"identifier"] forKey:@"identifier"];
	
	if(![statement execute:error]) {
		NSLog(@"Could not update shopping list: %@", *error);
		return NO;
	}
	
	SQL = @"UPDATE shoppinglists SET modification_date=DATETIME(:modificationDate, 'unixepoch') WHERE persistent_id=:identifier";
	statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	
	NSDate* modificationDate = [self dateForModificationDate:[shoppingList objectForKey:@"modification-date"]];
	[statement substituteObject:modificationDate forKey:@"modificationDate"];
	
	[statement substituteObject:[shoppingList objectForKey:@"identifier"] forKey:@"identifier"];
	
	if(![statement execute:error]) {
		NSLog(@"Could not update shopping list: %@", *error);
		return NO;
	}
	
	return YES;
}

- (NSMutableDictionary*)existingShoppingLists {
	NSString* SQL = @"SELECT id AS 'database-identifier', persistent_id AS identifier, name AS title, strftime('%s', modification_date) AS 'modification-date' FROM shoppinglists ORDER BY sort_order";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	NSMutableDictionary* shoppingLists = [NSMutableDictionary dictionaryWithCapacity:3];
	
	for(NSDictionary* shoppingList in [query recordEnumerator]) {
		shoppingLists[shoppingList[@"identifier"]] = shoppingList;
	}
	
	return shoppingLists;
}

- (NSDictionary*)shoppingListForTitle:(NSString*)title inArray:(NSArray*)array {
	if(title.length == 0) { return nil; }

	for(NSDictionary* shoppingList in array) {
		if(SUIEqualCaseInsensitiveStrings(title, shoppingList[@"title"])) {
			return shoppingList;
		}
	}

	return nil;
}

#pragma mark Shopping List Items

- (BOOL)importShoppingListItemsForShoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	if(![self deleteShoppingListItemsOfShoppingListIfNeeded:shoppingList error:error]) {
		return NO;
	}

	for(NSDictionary* item in shoppingList[@"items"]) {
		if(![self importItem:item ofShoppingList:shoppingList error:error]) {
			return NO;
		}
	}

	return YES;
}

- (BOOL)importItem:(NSDictionary*)item ofShoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	NSString* identifier = item[@"identifier"];

	NSDictionary* existingItem = [self itemForIdentifier:identifier shoppingList:shoppingList];
	if(!existingItem) {
		NSString* existingIdentifier = [self identifierForExistingItem:item shoppingList:shoppingList];

		if(existingIdentifier.length > 0) {
			identifier = existingIdentifier;
			existingItem = [self itemForIdentifier:identifier shoppingList:shoppingList];
		}
	}

	NSDate* deletionDate = [self deletionDateForItemIdentifier:identifier];
	if(deletionDate) { return YES; } // do nothing if deleted

	if(existingItem) {
		return [self mergeItem:item withExistingItem:existingItem shoppingList:shoppingList error:error];
	}

	return [self insertNewItem:item shoppingList:shoppingList error:error];
}

- (NSString*)identifierForExistingItem:(NSDictionary*)item shoppingList:(NSDictionary*)shoppingList {
	NSNumber* shoppingListDatabaseIdentifier = shoppingList[@"database-identifier"];
	if(!shoppingListDatabaseIdentifier) { return nil; }

	NSString* title = item[@"title"];

	NSString* SQL = @"SELECT persistent_id AS 'identifier' FROM shoppinglist_items WHERE name=:title AND shoppinglist_id=:shoppingListDatabaseIdentifier LIMIT 1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:@[ title, shoppingListDatabaseIdentifier ] store:[self sqliteStore] error:nil];

	NSString* identifier = [[query recordEnumeratorWithUnarchiveBlock:^id(NSCoder* coder) {
		return [coder decodeObjectForKey:@"identifier"];
	}] nextObject];

	return identifier;
}

- (NSDictionary*)itemForIdentifier:(NSString*)identifier shoppingList:(NSDictionary*)shoppingList {
	if(identifier.length == 0) { return nil; }

	NSString* SQL = @"SELECT items.persistent_id AS 'identifier', items.id AS 'database-identifier', aisles.persistent_id AS 'aisle-identifier', items.name AS title, items.note AS notes, items.checked AS completed, items.quantity, units.persistent_id AS 'unit-identifier', strftime('%s', items.modification_date) AS 'modification-date', strftime('%s', items.checked_modification_date) AS 'completed-modification-date', strftime('%s', items.aisle_modification_date) AS 'aisle-modification-date', strftime('%s', items.quantity_modification_date) AS 'quantity-modification-date' FROM shoppinglist_items items LEFT OUTER JOIN aisles ON items.aisle_id=aisles.id LEFT OUTER JOIN units ON items.unit_id=units.id WHERE items.persistent_id=:identifier LIMIT 1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	query.substitutionVariables = @{
		@"identifier": identifier };
	
	NSDictionary* item = [[query recordEnumerator] nextObject];
	return item;
}

- (GRCGrocery*)matchingGroceryForItem:(NSDictionary*)item {
	NSString* title = item[@"title"];
	GRCGrocery* grocery = [[self groceryStore] matchingGroceryForString:title locale:[self locale]];
	
	if(!grocery) {
		grocery = [[GRCGrocery alloc] init];
		
		grocery.title = title;
		
		id quantity = item[@"quantity"];
		if(quantity) {
			grocery.quantity = @([quantity doubleValue]);
		}

		NSString* unitIdentifier = item[@"unit-identifier"];
		if(unitIdentifier.length > 0) {
			GRCUnit* unit = [self unitForIdentifier:unitIdentifier inArray:[self existingUnits]];
			grocery.unitDatabaseIdentifier = unit ? unit.unitDatabaseIdentifier : GRCUnitInvalidDatabaseIdentifier;
		}
		
		NSString* aisleIdentifier = item[@"aisle-identifier"];
		if(aisleIdentifier.length > 0) {
			GRCAisle* aisle = [self aisleForIdentifier:aisleIdentifier inArray:[self existingAisles]];
			grocery.aisleDatabaseIdentifier = aisle ? aisle.aisleDatabaseIdentifier : GRCAisleInvalidDatabaseIdentifier;
		}
		
		NSError* error;
		if(![[self groceryStore] saveGrocery:grocery locale:[self locale] error:&error]) {
			return nil;
		}
	}
	
	return grocery;
}

- (BOOL)insertNewItem:(NSDictionary*)item shoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	GRCGrocery* grocery = [self matchingGroceryForItem:item];
	
	NSString* SQL = @"INSERT INTO shoppinglist_items (persistent_id, shoppinglist_id, aisle_id, grocery_id, name, note, checked, quantity, unit_id) VALUES (:identifier, :shoppingListIdentifier, (SELECT id FROM aisles WHERE persistent_id=:aisleIdentifier), :groceryDatabaseIdentifier, :title, :notes, :completed, :quantity, (SELECT id FROM units WHERE persistent_id=:unitIdentifier))";
	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	[statement substituteObject:[item objectForKey:@"identifier"] forKey:@"identifier"];

	[statement substituteObject:[shoppingList objectForKey:@"database-identifier"] forKey:@"shoppingListIdentifier"];

	[statement substituteObject:[item objectForKey:@"aisle-identifier"] forKey:@"aisleIdentifier"];
	
	[statement substituteObject:[item objectForKey:@"title"] forKey:@"title"];
	[statement substituteObject:[item objectForKey:@"notes"] forKey:@"notes"];

	[statement substituteObject:[item objectForKey:@"completed"] forKey:@"completed"];

	[statement substituteObject:[item objectForKey:@"quantity"] forKey:@"quantity"];
	[statement substituteObject:[item objectForKey:@"unit-identifier"] forKey:@"unitIdentifier"];
	
	if(grocery) {
		[statement substituteObject:@([grocery groceryDatabaseIdentifier]) forKey:@"groceryDatabaseIdentifier"];
	}

	NSUInteger identifier = NSNotFound;

	if(![statement executeAndReturnLastRowIdentifier:&identifier error:error]) {
		NSLog(@"Could not insert shopping list item: %@", *error);
		return NO;
	}

	// modification dates
	SQL = @"UPDATE shoppinglist_items SET modification_date=DATETIME(:modificationDate, 'unixepoch'), checked_modification_date=DATETIME(:completedModificationDate, 'unixepoch'), aisle_modification_date=DATETIME(:aisleModificationDate, 'unixepoch'), quantity_modification_date=DATETIME(:quantityModificationDate, 'unixepoch') WHERE id=:databaseIdentifier AND shoppinglist_id=:shoppingListDatabaseIdentifier";
	statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];

	if(!statement) {
		NSLog(@"Could not prepare update modification dates statememt: %@", *error);
		return NO;
	}

	[statement substituteObject:[item objectForKey:@"modification-date"] forKey:@"modificationDate"];
	[statement substituteObject:[item objectForKey:@"completed-modification-date"] forKey:@"completedModificationDate"];
	[statement substituteObject:[item objectForKey:@"aisle-modification-date"] forKey:@"aisleModificationDate"];
	[statement substituteObject:[item objectForKey:@"quantity-modification-date"] forKey:@"quantityModificationDate"];

	[statement substituteObject:@(identifier) forKey:@"databaseIdentifier"];
	[statement substituteObject:[shoppingList objectForKey:@"database-identifier"] forKey:@"shoppingListDatabaseIdentifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update modification dates: %@", *error);
		return NO;
	}

	return YES;
}

- (BOOL)mergeItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	NSNumber* modificationDate = item[@"modification-date"];
	NSNumber* existingModificationDate = existingItem[@"modification-date"];
	
	if([self isModificationDate:modificationDate newerThanModificationDate:existingModificationDate]) {
		if(![self mergePropertiesOfItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:shoppingList error:error]) {
			return NO;
		}
	}
	
	NSNumber* completedModificationDate = item[@"completed-modification-date"];
	NSNumber* existingCompletedModificationDate = existingItem[@"completed-modification-date"];
	
	if([self isModificationDate:completedModificationDate newerThanModificationDate:existingCompletedModificationDate]) {
		if(![self mergeCompletedPropertyOfItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:shoppingList error:error]) {
			return NO;
		}
	}
	
	NSNumber* aisleModificationDate = item[@"aisle-modification-date"];
	NSNumber* existingAisleModificationDate = existingItem[@"aisle-modification-date"];
	
	if([self isModificationDate:aisleModificationDate newerThanModificationDate:existingAisleModificationDate]) {
		if(![self mergeAisleOfItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:shoppingList error:error]) {
			return NO;
		}
	}
	
	NSNumber* quantityModificationDate = item[@"quantity-modification-date"];
	NSNumber* existingQuantityModificationDate = existingItem[@"quantity-modification-date"];
	
	if([self isModificationDate:quantityModificationDate newerThanModificationDate:existingQuantityModificationDate]) {
		if(![self mergeQuantityPropertiesOfItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:shoppingList error:error]) {
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)mergePropertiesOfItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	GRCGrocery* grocery = [self matchingGroceryForItem:item];
	
	NSString* SQL = @"UPDATE shoppinglist_items SET name=:title, note=:notes, grocery_id=:groceryDatabaseIdentifier WHERE id=:databaseIdentifier AND shoppinglist_id=:shoppingListDatabaseIdentifier";
	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	[statement substituteObject:[item objectForKey:@"title"] forKey:@"title"];
	[statement substituteObject:[item objectForKey:@"notes"] forKey:@"notes"];
	
	[statement substituteObject:[existingItem objectForKey:@"database-identifier"] forKey:@"databaseIdentifier"];
	[statement substituteObject:[shoppingList objectForKey:@"database-identifier"] forKey:@"shoppingListDatabaseIdentifier"];
	
	if(grocery) {
		[statement substituteObject:@([grocery groceryDatabaseIdentifier]) forKey:@"groceryDatabaseIdentifier"];
	}
	
	if(![statement execute:error]) {
		NSLog(@"Could not update shopping list item properties: %@", *error);
		return NO;
	}
	
	// modification date
	SQL = @"UPDATE shoppinglist_items SET modification_date=DATETIME(:modificationDate, 'unixepoch') WHERE id=:databaseIdentifier AND shoppinglist_id=:shoppingListDatabaseIdentifier";
	statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];

	[statement substituteObject:[item objectForKey:@"modification-date"] forKey:@"modificationDate"];

	[statement substituteObject:[existingItem objectForKey:@"database-identifier"] forKey:@"databaseIdentifier"];
	[statement substituteObject:[shoppingList objectForKey:@"database-identifier"] forKey:@"shoppingListDatabaseIdentifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update modification date: %@", *error);
		return NO;
	}

	return YES;
}

- (BOOL)mergeCompletedPropertyOfItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE shoppinglist_items SET checked=:completed WHERE id=:databaseIdentifier";
	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	BOOL completed = [[item objectForKey:@"completed"] integerValue] == 1;
	[statement substituteObject:@(completed) forKey:@"completed"];
	
	[statement substituteObject:[existingItem objectForKey:@"database-identifier"] forKey:@"databaseIdentifier"];
	
	if(![statement execute:error]) {
		NSLog(@"Could not update shopping list item completed property: %@", *error);
		return NO;
	}
	
	// modification date
	SQL = @"UPDATE shoppinglist_items SET checked_modification_date=DATETIME(:modificationDate, 'unixepoch') WHERE id=:databaseIdentifier";
	statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];

	[statement substituteObject:[item objectForKey:@"completed-modification-date"] forKey:@"modificationDate"];
	[statement substituteObject:[existingItem objectForKey:@"database-identifier"] forKey:@"databaseIdentifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update completed modification date: %@", *error);
		return NO;
	}

	return YES;
}

- (BOOL)mergeAisleOfItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE shoppinglist_items SET aisle_id=(SELECT id FROM aisles WHERE persistent_id=:aisleIdentifier) WHERE id=:databaseIdentifier AND shoppinglist_id=:shoppingListDatabaseIdentifier";
	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	NSString* aisleIdentifier = [item objectForKey:@"aisle-identifier"];
	if([[self aisleIdentifierMapping] objectForKey:aisleIdentifier]) {
		aisleIdentifier = [[self aisleIdentifierMapping] objectForKey:aisleIdentifier];
	}
	
	[statement substituteObject:aisleIdentifier forKey:@"aisleIdentifier"];
	
	[statement substituteObject:[existingItem objectForKey:@"database-identifier"] forKey:@"databaseIdentifier"];
	[statement substituteObject:[shoppingList objectForKey:@"database-identifier"] forKey:@"shoppingListDatabaseIdentifier"];
	
	if(![statement execute:error]) {
		NSLog(@"Could not update aisle for shopping list item: %@", *error);
		return NO;
	}
	
	// modification date
	SQL = @"UPDATE shoppinglist_items SET aisle_modification_date=DATETIME(:aisleModificationDate, 'unixepoch') WHERE id=:databaseIdentifier AND shoppinglist_id=:shoppingListDatabaseIdentifier";
	statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];

	[statement substituteObject:[item objectForKey:@"aisle-modification-date"] forKey:@"aisleModificationDate"];

	[statement substituteObject:[existingItem objectForKey:@"database-identifier"] forKey:@"databaseIdentifier"];
	[statement substituteObject:[shoppingList objectForKey:@"database-identifier"] forKey:@"shoppingListDatabaseIdentifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update aisle modification date: %@", *error);
		return NO;
	}

	return YES;
}

- (BOOL)mergeQuantityPropertiesOfItem:(NSDictionary*)item withExistingItem:(NSDictionary*)existingItem shoppingList:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE shoppinglist_items SET quantity=:quantity, unit_id=(SELECT id FROM units WHERE persistent_id=:unitIdentifier) WHERE id=:databaseIdentifier AND shoppinglist_id=:shoppingListDatabaseIdentifier";
	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	NSString* unitIdentifier = [item objectForKey:@"unit-identifier"];
	if(unitIdentifier && [[self unitIdentifierMapping] objectForKey:unitIdentifier]) {
		unitIdentifier = [[self unitIdentifierMapping] objectForKey:unitIdentifier];
	}

	[statement substituteObject:[item objectForKey:@"quantity"] forKey:@"quantity"];
	[statement substituteObject:unitIdentifier forKey:@"unitIdentifier"];
	
	[statement substituteObject:[existingItem objectForKey:@"database-identifier"] forKey:@"databaseIdentifier"];
	[statement substituteObject:[shoppingList objectForKey:@"database-identifier"] forKey:@"shoppingListDatabaseIdentifier"];
	
	if(![statement execute:error]) {
		NSLog(@"Could not update unit for shopping list item: %@", *error);
		return NO;
	}
	
	// modification date
	SQL = @"UPDATE shoppinglist_items SET quantity_modification_date=DATETIME(:quantityModificationDate, 'unixepoch') WHERE id=:databaseIdentifier AND shoppinglist_id=:shoppingListDatabaseIdentifier";
	statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];

	[statement substituteObject:[item objectForKey:@"quantity-modification-date"] forKey:@"quantityModificationDate"];

	[statement substituteObject:[existingItem objectForKey:@"database-identifier"] forKey:@"databaseIdentifier"];
	[statement substituteObject:[shoppingList objectForKey:@"database-identifier"] forKey:@"shoppingListDatabaseIdentifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update quantity modification date: %@", *error);
		return NO;
	}

	return YES;
}

- (BOOL)deleteShoppingListItemsOfShoppingListIfNeeded:(NSDictionary*)shoppingList error:(NSError* __autoreleasing *)error {
	NSArray* identifiers = [[shoppingList objectForKey:@"deleted-items"] valueForKeyPath:@"identifier"];
	if(identifiers.count == 0) { return YES; }

	NSString* identifierSQLString = [self SQLStringForContainer:identifiers];

	NSString* SQL = [NSString stringWithFormat:@"DELETE FROM shoppinglist_items WHERE persistent_id IN (%@)", identifierSQLString];
	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];

	if(![statement execute:error]) {
		return NO;
	}

	return YES;
}

- (NSDate*)deletionDateForItemIdentifier:(NSString*)identifier {
	if(identifier.length == 0) { return nil; }

	NSString* SQL = @"SELECT strftime('%s', deletion_date) AS 'deletion-date' FROM deleted_shoppinglist_items WHERE persistent_id=:identifier LIMIT 1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:@[ identifier ] store:[self sqliteStore] error:nil];
	
	NSDate* deletionDate = [[query recordEnumeratorWithUnarchiveBlock:^id(NSCoder* coder) {
		if(![coder containsValueForKey:@"deletion-date"]) { return nil; }

		NSTimeInterval timestamp = [coder decodeDoubleForKey:@"deletion-date"];
		return [NSDate dateWithTimeIntervalSince1970:timestamp];
	}] nextObject];
	
	return deletionDate;
}

#pragma mark -

- (NSDate*)dateForModificationDate:(id)modificationDate {
	if(!modificationDate) { return nil; }
	if([modificationDate isKindOfClass:[NSDate class]]) { return modificationDate; }
	
	NSTimeInterval timeInterval = [modificationDate doubleValue];
	return [NSDate dateWithTimeIntervalSince1970:timeInterval];
}

- (BOOL)isModificationDate:(id)modificationDate newerThanModificationDate:(id)otherModificationDate {
	modificationDate = [self dateForModificationDate:modificationDate];
	otherModificationDate = [self dateForModificationDate:otherModificationDate];

	if(!modificationDate) { return NO; }
	if(modificationDate == otherModificationDate) { return NO; }
	if(modificationDate && !otherModificationDate) { return YES; }

	return [(NSDate*)modificationDate compare:otherModificationDate] == NSOrderedDescending;
}

- (void)finalizeSQLiteStore {
	self.aisleStore = nil; self.unitStore = nil; self.groceryStore = nil;
	[[self sqliteStore] close]; self.sqliteStore = nil;
}

- (NSString*)SQLStringForContainer:(id)set {
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:[set count]];

	for(id object in set) {
		NSString* escapedString;

		if([object isKindOfClass:[NSNumber class]]) {
			escapedString = [object stringValue];
		} else if([object isKindOfClass:[NSString class]]) {
			escapedString = [NSString stringWithFormat:@"'%@'", [object stringByEscapingSQLCharacters]];
		}

		if(escapedString) { [array addObject:escapedString]; }
	}

	NSString* queryString = [array componentsJoinedByString:@","];
	return queryString;
}

- (id<GRCUnarchiver>)unarchiverForURL:(NSURL*)URL {
	if([GRCZIPUnarchiver canUnarchiveURL:URL]) { return [[GRCZIPUnarchiver alloc] initWithContentsOfURL:URL]; }
	if([GRCURLUnarchiver canUnarchiveURL:URL]) { return [[GRCURLUnarchiver alloc] initWithContentsOfURL:URL]; }
	return nil;
}

@end
