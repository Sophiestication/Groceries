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

#import "GRCShoppingListStore.h"
#import "GRCShoppingListStore+Private.h"

#import "GRCShoppingList+Private.h"
#import "GRCShoppingListItem+Private.h"

#import "GRCDefaultStore.h"

#import "GRCGrocery.h"

#import "GRCAisle.h"
#import "GRCUnit.h"

#import "GRCUnitFormatter.h"

#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"
#import "NSString+Additions.h"

@implementation GRCShoppingListStore

NSString* const GRCShoppingListStoreUnitDidChangeNotification = @"GRCShoppingListStoreUnitDidChange";
NSString* const GRCShoppingListStoreAisleDidChangeNotification = @"GRCShoppingListStoreAisleDidChange";

NSString* const GRCShoppingListStoreLocaleDidChangeNotification = @"GRCShoppingListStoreLocaleDidChange";
NSString* const GRCShoppingListStoreLocaleKey = @"locale";

NSString* const GRCShoppingListDidSaveItemNotification = @"GRCShoppingListDidSaveItem";
NSString* const GRCShoppingListDidDeleteItemNotification = @"GRCShoppingListDidDeleteItem";

NSString* const GRCShoppingListItemKey = @"item";

NSString* const GRCShoppingListStoreDidReceiveExternalChangeNotification = @"GRCShoppingListStoreDidReceiveExternalChangeNotification";

NSString* const GRCShoppingListStoreRecentItemsDefaultsKey = @"recent-items";

@dynamic authorizationStatus;

#pragma mark - Construction & Destruction

+ (void)requestStore:(void (^)(GRCShoppingListStore*, NSError*))completion {
	[GRCDefaultStoreOperationQueue() addOperationWithBlock:^(void) {
		SQLiteStore* sqliteStore = GRCNewDefaultStore();
		GRCShoppingListStore* store = [[GRCShoppingListStore alloc] initWithSQLiteStore:sqliteStore];
		
		// load aisles and units
		if(!store.aisles) {}
		if(!store.units) {}

		dispatch_async(dispatch_get_main_queue(), ^() {
			completion(store, nil);
		});
	}];
}

- (id)initWithSQLiteStore:(SQLiteStore*)SQLiteStore {
	if(self = ([super init])) {
		self.needsUpdate = YES;

		self.consumers = [NSMapTable
			mapTableWithKeyOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPersonality
			valueOptions:NSPointerFunctionsCopyIn|NSPointerFunctionsStrongMemory];

		self.sqliteStore = SQLiteStore;
		
		self.locale = [self newLocaleWithPreferredLanguageCode];
		self.cache = [[NSCache alloc] init];

		self.groceryStore = [[GRCGroceryStore alloc] initWithSQLiteStore:SQLiteStore];
		
		self.aisleStore = [[GRCAisleStore alloc] initWithSQLiteStore:SQLiteStore];
		self.unitStore = [[GRCUnitStore alloc] initWithSQLiteStore:SQLiteStore];

		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(currentLocaleDidChange:)
			name:NSCurrentLocaleDidChangeNotification
			object:nil];
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(userDefaultsDidChange:)
			name:NSUserDefaultsDidChangeNotification
			object:nil];
			
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(storeDidReceiveExternalChange:)
			name:GRCShoppingListStoreDidReceiveExternalChangeNotification
			object:nil];
	}

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - GRCShoppingListStore

- (GRCShoppingListStoreAuthorizationStatus)authorizationStatus {
	return GRCShoppingListStoreAuthorizationStatusAuthorized;
}

- (void)addConsumer:(id)consumer callback:(void (^)(NSSet* shoppingLists, NSArray* changes))callback {
	[[self consumers] setObject:callback forKey:consumer];

	if(self.needsUpdate) {
		[self updateIfNeeded];
	} else {
//		dispatch_async(dispatch_get_main_queue(), ^() {
			callback([self shoppingLists], nil);
//		});
	}
}

- (void)removeConsumer:(id)consumer {
	[[self consumers] removeObjectForKey:consumer];
}

- (void)beginUpdates {
	[[self sqliteStore] beginTransaction];
}

- (void)endUpdatesAndCommit:(BOOL)commit {
	if(commit) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}
}

#pragma mark - External Store Change

- (void)storeDidReceiveExternalChange:(NSNotification*)notification {
	self.cache = [[NSCache alloc] init]; // force re-evaluation
	[self updateAfterExternalStoreChange:notification];
}

- (void)scheduleUpdateAfterExternalStoreChange:(id)sender {
	NSTimeInterval delay = 0.0; // just schedule for the next runloop for now

	[NSObject
		cancelPreviousPerformRequestsWithTarget:self
		selector:@selector(updateAfterExternalStoreChange:)
		object:nil];
	[self
		performSelector:@selector(updateAfterExternalStoreChange:)
		withObject:nil
		afterDelay:delay];
}

#pragma mark - NSUserDefaultsDidChangeNotification

- (void)userDefaultsDidChange:(NSNotification*)notification {
	NSString* preferredLanguageCode = [[NSUserDefaults standardUserDefaults]
		stringForKey:@"GRCPreferredLanguageCode"];

	if(SUIEqualCaseInsensitiveStrings(preferredLanguageCode, @"automatic")) {
		preferredLanguageCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleLanguageCode];
	}
		
	NSString* currentLanguageCode = [[self locale] objectForKey:NSLocaleLanguageCode];
	
	if(!SUIEqualCaseInsensitiveStrings(preferredLanguageCode, currentLanguageCode)) {
		[self currentLocaleDidChange:nil];
	}
}

#pragma mark - NSCurrentLocaleDidChangeNotification

- (void)currentLocaleDidChange:(NSNotification*)notification {
	self.cache = [[NSCache alloc] init]; // force re-evaluation
	self.locale = [self newLocaleWithPreferredLanguageCode];
	
	[self updateAfterExternalStoreChange:notification];

	NSDictionary* userInfo = @{
		GRCShoppingListStoreLocaleKey: self.locale };
	[[NSNotificationCenter defaultCenter]
		postNotificationName:GRCShoppingListStoreLocaleDidChangeNotification
		object:self
		userInfo:userInfo];
}

#pragma mark - Private

- (void)updateIfNeeded {
	if(!self.needsUpdate) { return; }

	if(self.consumers.count == 0) {
		for(GRCShoppingList* shoppingList in [[self livingShoppingLists] objectEnumerator]) {
			shoppingList.needsUpdate = YES;
			[shoppingList updateShoppingListItemsIfNeeded];
		}

		return;
	}

	self.needsUpdate = NO;

	// update shopping lists, create if needed
	NSString* SQL = @"SELECT * FROM shoppinglists ORDER BY sort_order, name";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	NSMutableSet* shoppingLists = [NSMutableSet setWithCapacity:3];
	NSMapTable* livingShoppingLists = [NSMapTable strongToStrongObjectsMapTable];
	
	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		NSString* identifier = [coder decodeObjectForKey:@"persistent_id"];
		
		GRCShoppingList* shoppingList = [[self livingShoppingLists] objectForKey:identifier];
		if(!shoppingList) { shoppingList = [[GRCShoppingList alloc] initWithCoder:coder]; }
		
		shoppingList.store = self;
		
		return shoppingList;
	}];
	
	for(GRCShoppingList* shoppingList in enumerator) {
		[shoppingLists addObject:shoppingList];
		[livingShoppingLists setObject:shoppingList forKey:[shoppingList shoppingListIdentifier]];

		shoppingList.needsUpdate = YES;
		[shoppingList updateShoppingListItemsIfNeeded];
	}

	self.livingShoppingLists = livingShoppingLists;

	[self notifyConsumers:shoppingLists];
}

- (NSSet*)shoppingLists {
	NSMutableSet* shoppingLists = [NSMutableSet setWithCapacity:[[self livingShoppingLists] count]];
	
	NSEnumerator* enumerator = [[self livingShoppingLists] objectEnumerator];
	GRCShoppingList* shoppingList;
	
	while(shoppingList = [enumerator nextObject]) {
		[shoppingLists addObject:shoppingList];
	}

	return shoppingLists;
}

- (void)notifyConsumers {
	NSSet* shoppingLists = [self shoppingLists];
	[self notifyConsumers:shoppingLists];
}

- (void)notifyConsumers:(NSSet*)shoppingLists {
	// notify consumers about changes
	for(void (^callback)(NSSet* shoppingLists, NSArray* changes) in [[self consumers] objectEnumerator]) {
//		dispatch_async(dispatch_get_main_queue(), ^() {
			callback(shoppingLists, nil);
//		});
	}
}

- (void)notifyShoppingListConsumers {
	NSEnumerator* enumerator = [[self livingShoppingLists] objectEnumerator];
	GRCShoppingList* shoppingList;
	
	while(shoppingList = [enumerator nextObject]) {
		[shoppingList notifyConsumers];
	}
}

- (void)updateAfterExternalStoreChange:(id)sender {
	self.needsUpdate = YES;
	[self updateIfNeeded];
}

- (void)notifyStoreItemDidChange:(id)sender {
	[self notifyConsumers];
}

- (void)enumerateLivingShoppingListItems:(void (^)(GRCShoppingListItem* item))block {
	NSEnumerator* enumerator = [[self livingShoppingLists] objectEnumerator];
	GRCShoppingList* shoppingList;

	while(shoppingList = [enumerator nextObject]) {
		[[shoppingList items] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
			block(obj);
		}];
	}
}

- (NSLocale*)newLocaleWithPreferredLanguageCode {
	return [NSLocale localeWithPreferredLanguageCode];
}

@end

#pragma mark - ShoppingLists

@implementation GRCShoppingListStore(ShoppingLists)

- (GRCShoppingList*)newShoppingList {
	GRCShoppingList* shoppingList = [[GRCShoppingList alloc] init];
	shoppingList.store = self;
	return shoppingList;
}

- (BOOL)saveShoppingList:(GRCShoppingList*)list error:(NSError* __autoreleasing *)error {
	[[self sqliteStore] beginTransaction];

	BOOL didSucceed = YES;
	NSUInteger databaseIdentifier = list.shoppingListDatabaseIdentifier;

	if(databaseIdentifier == GRCShoppingListInvalidDatabaseIdentifier) {
		didSucceed = [self insertShoppingList:list error:error];
	} else {
		didSucceed = [self updateShoppingList:list error:error];
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}
	
	if(didSucceed) {
		if(!self.livingShoppingLists) { self.livingShoppingLists = [NSMapTable strongToWeakObjectsMapTable]; }
		[[self livingShoppingLists] setObject:list forKey:[list shoppingListIdentifier]];
	
		[self notifyStoreItemDidChange:self];
		[list notifyConsumers];
	}
	
	return didSucceed;
}

- (BOOL)deleteShoppingList:(GRCShoppingList*)list error:(NSError* __autoreleasing *)error {
	BOOL didSucceed = YES;

	NSUInteger databaseIdentifier = list.shoppingListDatabaseIdentifier;

	if(databaseIdentifier != GRCShoppingListInvalidDatabaseIdentifier) {
		[[self sqliteStore] beginTransaction];

		NSString* SQL = @"DELETE FROM shoppinglists WHERE id=:identifier";

		SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
		[statement substituteObject:@(databaseIdentifier) forKey:@"identifier"];

		if(![statement execute:error]) {
			NSLog(@"Could not delete shopping list: %@", *error);
			didSucceed = NO;
		}

		if(didSucceed) {
			[[self sqliteStore] commitTransaction];
		} else {
			[[self sqliteStore] cancelTransaction];
		}
	}

	if(didSucceed) {
		NSString* identifier = list.shoppingListIdentifier;
		[[self livingShoppingLists] removeObjectForKey:identifier];

		[self notifyStoreItemDidChange:self];
	}
	
	return didSucceed;
}

- (BOOL)insertShoppingList:(GRCShoppingList*)shoppingList error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"INSERT INTO shoppinglists (persistent_id, name, sort_order, modification_date) VALUES (:shoppingListIdentifier, :title, :sortOrder, CURRENT_TIMESTAMP)";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:[shoppingList shoppingListIdentifier] forKey:@"shoppingListIdentifier"];
	[statement substituteObject:[shoppingList title] forKey:@"title"];
	[statement substituteObject:@([shoppingList sortOrder]) forKey:@"sortOrder"];

	NSUInteger identifier = NSNotFound;

	if(![statement executeAndReturnLastRowIdentifier:&identifier error:error]) {
		NSLog(@"Could not insert shopping list: %@", *error);
		return NO;
	}

	shoppingList.shoppingListDatabaseIdentifier = identifier;

	return YES;
}

- (BOOL)updateShoppingList:(GRCShoppingList*)shoppingList error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE shoppinglists SET persistent_id=:shoppingListIdentifier, name=:title, sort_order=:sortOrder WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:[shoppingList shoppingListIdentifier] forKey:@"shoppingListIdentifier"];

	[statement substituteObject:[shoppingList title] forKey:@"title"];
	[statement substituteObject:@([shoppingList sortOrder]) forKey:@"sortOrder"];

	[statement substituteObject:@([shoppingList shoppingListDatabaseIdentifier]) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update shopping list: %@", *error);
		return NO;
	}

	return YES;
}

@end

#pragma mark - ShoppingListItems

@implementation GRCShoppingListStore(ShoppingListItems)

- (BOOL)saveShoppingListItem:(GRCShoppingListItem*)item notify:(BOOL)notify error:(NSError* __autoreleasing *)error {
	return [self saveShoppingListItem:item notify:notify overwriteGrocery:NO markAsRecentlyUsed:NO error:error];
}

- (BOOL)saveShoppingListItem:(GRCShoppingListItem*)item notify:(BOOL)notify overwriteGrocery:(BOOL)overwriteGrocery markAsRecentlyUsed:(BOOL)markAsRecentlyUsed error:(NSError* __autoreleasing *)error {
	if(!item) { return YES; }

	[[self sqliteStore] beginTransaction];

	BOOL didSucceed = YES;

	GRCGrocery* grocery = item.grocery;

	if(grocery.groceryDatabaseIdentifier == GRCGroceryInvalidDatabaseIdentifier) {
		didSucceed = [[self groceryStore] saveGrocery:grocery locale:[self locale] error:error];
	} else {
		GRCGrocery* groceryToOverwrite = overwriteGrocery ? grocery : nil;
		didSucceed = [self updateGroceryForShoppingListItem:item existingGrocery:groceryToOverwrite error:error];
	}

	if(didSucceed) {
		NSUInteger databaseIdentifier = item.shoppingListItemDatabaseIdentifier;

		if(databaseIdentifier == GRCShoppingListInvalidDatabaseIdentifier) {
			didSucceed = [self insertShoppingListItem:item error:error];
		} else {
			didSucceed = [self updateShoppingListItem:item error:error];
		}
	}

	if(didSucceed && markAsRecentlyUsed) {
		didSucceed = [self markShoppingListItemAsRecentlyUsed:item];
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}
	
	if(didSucceed) {
		[[item shoppingList] didSaveItem:item notify:notify];

		if(notify) {
			NSDictionary* userInfo = @{
				GRCShoppingListItemKey: item };
			[[NSNotificationCenter defaultCenter] postNotificationName:GRCShoppingListDidSaveItemNotification object:self userInfo:userInfo];
		}
	}
	
	return didSucceed;
}

- (BOOL)deleteShoppingListItem:(GRCShoppingListItem*)item notify:(BOOL)notify error:(NSError* __autoreleasing *)error {
	NSUInteger databaseIdentifier = item.shoppingListItemDatabaseIdentifier;
	if(databaseIdentifier == GRCShoppingListItemInvalidDatabaseIdentifier) { return YES; }

	BOOL didSucceed = YES;

	[[self sqliteStore] beginTransaction];

	NSString* SQL = @"DELETE FROM shoppinglist_items WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:@(databaseIdentifier) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not delete shopping list item: %@", *error);
		didSucceed = NO;
	}

	if(didSucceed) {
		[[item shoppingList] didDeleteItem:item notify:notify];

		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	return didSucceed;
}

- (BOOL)deleteShoppingListItemIncludingGrocery:(GRCShoppingListItem*)item error:(NSError* __autoreleasing *)error {
	BOOL didSucceed = YES;

	[[self sqliteStore] beginTransaction];
	
	GRCGrocery* grocery = item.grocery;

	if(grocery) {
		if(![[self groceryStore] deleteGrocery:grocery locale:[self locale] error:error]) {
			didSucceed = NO;
		}
	}

	if(didSucceed) {
		if(![self deleteShoppingListItem:item notify:YES error:error]) {
			didSucceed = NO;
		}
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	[[self cache] removeObjectForKey:GRCShoppingListStoreRecentItemsDefaultsKey];

	return didSucceed;
}

- (BOOL)insertShoppingListItem:(GRCShoppingListItem*)shoppingListItem error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"INSERT INTO shoppinglist_items (persistent_id, shoppinglist_id, aisle_id, grocery_id, name, note, checked, quantity, unit_id) VALUES (:identifier, :shoppingListIdentifier, :aisleIdentifier, :groceryIdentifier, :title, :notes, :completed, :quantity, :unitIdentifier)";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }
	
	[statement substituteObject:[shoppingListItem shoppingListItemIdentifier] forKey:@"identifier"];

	[statement substituteObject:@([[shoppingListItem shoppingList] shoppingListDatabaseIdentifier]) forKey:@"shoppingListIdentifier"];

	if(shoppingListItem.aisle) {
		[statement substituteObject:@([[shoppingListItem aisle] aisleDatabaseIdentifier]) forKey:@"aisleIdentifier"];
	} else {
		[statement substituteObject:[NSNull null] forKey:@"aisleIdentifier"];
	}

	if(shoppingListItem.grocery) {
		[statement substituteObject:@([[shoppingListItem grocery] groceryDatabaseIdentifier]) forKey:@"groceryIdentifier"];
	} else {
		[statement substituteObject:[NSNull null] forKey:@"groceryIdentifier"];
	}
	
	[statement substituteObject:[shoppingListItem title] forKey:@"title"];
	[statement substituteObject:[shoppingListItem notes] forKey:@"notes"];

	[statement substituteObject:@([shoppingListItem isCompleted]) forKey:@"completed"];

	[statement substituteObject:[shoppingListItem quantity] forKey:@"quantity"];

	if(shoppingListItem.unit) {
		[statement substituteObject:@([[shoppingListItem unit] unitDatabaseIdentifier]) forKey:@"unitIdentifier"];
	} else {
		[statement substituteObject:[NSNull null] forKey:@"unitIdentifier"];
	}
	
	NSUInteger identifier = NSNotFound;

	if(![statement executeAndReturnLastRowIdentifier:&identifier error:error]) {
		NSLog(@"Could not insert shopping list item: %@", *error);
		return NO;
	}

	shoppingListItem.shoppingListItemDatabaseIdentifier = identifier;

	return YES;
}

- (BOOL)updateShoppingListItem:(GRCShoppingListItem*)shoppingListItem error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE shoppinglist_items SET shoppinglist_id=:shoppingListIdentifier, aisle_id=:aisleIdentifier, grocery_id=:groceryIdentifier, name=:title, note=:notes, checked=:completed, quantity=:quantity, unit_id=:unitIdentifier WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:@([[shoppingListItem shoppingList] shoppingListDatabaseIdentifier]) forKey:@"shoppingListIdentifier"];

	if(shoppingListItem.aisle) {
		[statement substituteObject:@([[shoppingListItem aisle] aisleDatabaseIdentifier]) forKey:@"aisleIdentifier"];
	} else {
		[statement substituteObject:[NSNull null] forKey:@"aisleIdentifier"];
	}

	if(shoppingListItem.grocery) {
		[statement substituteObject:@([[shoppingListItem grocery] groceryDatabaseIdentifier]) forKey:@"groceryIdentifier"];
	} else {
		[statement substituteObject:[NSNull null] forKey:@"groceryIdentifier"];
	}
	
	[statement substituteObject:[shoppingListItem title] forKey:@"title"];
	[statement substituteObject:[shoppingListItem notes] forKey:@"notes"];

	[statement substituteObject:@([shoppingListItem isCompleted]) forKey:@"completed"];

	[statement substituteObject:[shoppingListItem quantity] forKey:@"quantity"];

	if(shoppingListItem.unit) {
		[statement substituteObject:@([[shoppingListItem unit] unitDatabaseIdentifier]) forKey:@"unitIdentifier"];
	} else {
		[statement substituteObject:[NSNull null] forKey:@"unitIdentifier"];
	}
	
	[statement substituteObject:@([shoppingListItem shoppingListItemDatabaseIdentifier]) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update shopping list: %@", *error);
		return NO;
	}

	return YES;
}

- (BOOL)updateGroceryForShoppingListItem:(GRCShoppingListItem*)shoppingListItem existingGrocery:(GRCGrocery*)existingGrocery error:(NSError* __autoreleasing *)error {
	NSLocale* locale = self.locale;
	NSString* title = shoppingListItem.title;

	BOOL needsSave = NO;
	
	GRCGrocery* grocery = existingGrocery;

	if(!grocery) {
		grocery = [[self groceryStore] groceryForTitle:title locale:locale];
	}

	if(grocery) {
		if(grocery.aisleDatabaseIdentifier != shoppingListItem.aisle.aisleDatabaseIdentifier) {
			grocery.aisleDatabaseIdentifier = shoppingListItem.aisle.aisleDatabaseIdentifier;
			needsSave = YES;
		}

		if([[grocery quantity] doubleValue] != [[shoppingListItem quantity] doubleValue]) {
			grocery.quantity = shoppingListItem.quantity;
			needsSave = YES;
		}

		if(grocery.unitDatabaseIdentifier != shoppingListItem.unit.unitDatabaseIdentifier) {
			grocery.unitDatabaseIdentifier = shoppingListItem.unit.unitDatabaseIdentifier;
			needsSave = YES;
		}

		if(!SUIEqualStrings(grocery.notes, shoppingListItem.notes)) {
			grocery.notes = shoppingListItem.notes;
			needsSave = YES;
		}

		if(!SUIEqualStrings(grocery.title, shoppingListItem.title)) {
			grocery.title = shoppingListItem.title;
			needsSave = YES;
		}
	}

	if(!grocery) {
		grocery = [[GRCGrocery alloc] init];
		
		grocery.title = title;
		grocery.notes = shoppingListItem.notes;
		grocery.quantity = shoppingListItem.quantity;

		if(shoppingListItem.unit) {
			grocery.unitDatabaseIdentifier = shoppingListItem.unit.unitDatabaseIdentifier;
		}
		
		if(shoppingListItem.aisle) {
			grocery.aisleDatabaseIdentifier = shoppingListItem.aisle.aisleDatabaseIdentifier;
		}
		
		needsSave = YES;
	}

	if(needsSave) {
		if(![[self groceryStore] saveGrocery:grocery locale:locale error:error]) {
			return NO;
		}
	}
	
	shoppingListItem.grocery = grocery;
	
	return YES;
}

@end

#pragma mark - Aisles

@implementation GRCShoppingListStore(Aisles)

NSString* const GRCShoppingListStoreAislesDefaultsKey = @"aisles";

- (NSArray*)aisles {
	NSArray* aisles = [[self cache] objectForKey:GRCShoppingListStoreAislesDefaultsKey];

	if(!aisles) {
		[self loadAislesIfNeeded];
		return [[self cache] objectForKey:GRCShoppingListStoreAislesDefaultsKey];
	}

	return aisles;
}

- (GRCAisle*)newAisle {
	GRCAisle* newAisle = [[GRCAisle alloc] init];
	return newAisle;
}

- (BOOL)insertAisle:(GRCAisle*)aisle atIndex:(NSUInteger)aisleIndex error:(NSError* __autoreleasing *)error {
	NSMutableArray* aisles = [[self aisles] mutableCopy];

	NSUInteger previousAisleIndex = [aisles indexOfObject:aisle];

	if(previousAisleIndex != NSNotFound) {
		[aisles removeObjectAtIndex:previousAisleIndex];
	}

	if(aisleIndex >= aisles.count) {
		[aisles addObject:aisle];
	} else {
		[aisles insertObject:aisle atIndex:aisleIndex];
	}

	if(![[self aisleStore] saveAisle:aisle error:error]) { return NO; }
	if(![[self aisleStore] updateSortOrderForAisles:aisles error:error]) { return NO; }

	if(aisles) { [[self cache] setObject:aisles forKey:GRCShoppingListStoreAislesDefaultsKey]; }

	[self scheduleUpdateAfterExternalStoreChange:nil];

	return YES;
}

- (BOOL)deleteAisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error {
	if(![[self aisleStore] deleteAisle:aisle error:error]) {
		return NO;
	}
	
	[self enumerateLivingShoppingListItems:^(GRCShoppingListItem* item) {
		if([[item aisle] isEqual:aisle]) { item.aisle = nil; }
	}];

	NSMutableArray* aisles = [[self aisles] mutableCopy];
	[aisles removeObject:aisle];

	if(![[self aisleStore] updateSortOrderForAisles:aisles error:error]) {
		return NO;
	}

	if(aisles) { [[self cache] setObject:aisles forKey:GRCShoppingListStoreAislesDefaultsKey]; }

	[self scheduleUpdateAfterExternalStoreChange:nil];
	
	return YES;
}

- (BOOL)saveAisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error {
	NSArray* aisles = [self aisles];

	if(![aisles containsObject:aisle]) {
		return [self insertAisle:aisle atIndex:[aisles count] error:error];
	}
	
	if(![[self aisleStore] saveAisle:aisle error:error]) { return NO; }
	if(![[self aisleStore] updateSortOrderForAisles:[self aisles] error:error]) { return NO; }

	[self scheduleUpdateAfterExternalStoreChange:nil];

	return YES;
}

- (GRCAisle*)aisleForDatabaseIdentifier:(NSInteger)databaseIdentifier {
	if(databaseIdentifier == GRCAisleInvalidDatabaseIdentifier) { return nil; }

	for(GRCAisle* aisle in [self aisles]) {
		if(aisle.aisleDatabaseIdentifier == databaseIdentifier) { return aisle; }
	}
	
	return nil;
}

- (void)loadAislesIfNeeded {
	NSSet* allAisles = [[self aisleStore] aisles];
	
	NSArray* orderedAisles = [[allAisles allObjects] sortedArrayUsingDescriptors:@[
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES]
	]];
	
	if(orderedAisles) {
		[[self cache] setObject:orderedAisles forKey:GRCShoppingListStoreAislesDefaultsKey];
	}
}

@end

#pragma mark - Units

@implementation GRCShoppingListStore(Units)

NSString* const GRCShoppingListStoreUnitsDefaultsKey = @"units";
NSString* const GRCShoppingListStoreDefaultUnitDefaultsKey = @"default-unit";

- (NSArray*)units {
	NSArray* units = [[self cache] objectForKey:GRCShoppingListStoreUnitsDefaultsKey];

	if(!units) {
		[self loadUnitsIfNeeded];
		return [[self cache] objectForKey:GRCShoppingListStoreUnitsDefaultsKey];
	}

	return units;
}

- (GRCUnit*)defaultUnit {
	GRCUnit* defaultUnit = [[self cache] objectForKey:GRCShoppingListStoreDefaultUnitDefaultsKey];

	if(!defaultUnit) {
		[self loadUnitsIfNeeded];
		return [[self cache] objectForKey:GRCShoppingListStoreDefaultUnitDefaultsKey];
	}

	return defaultUnit;
}

- (GRCUnit*)newUnit {
	GRCUnit* newUnit = [[GRCUnit alloc] init];
	return newUnit;
}

- (BOOL)insertUnit:(GRCUnit*)unit atIndex:(NSUInteger)unitIndex error:(NSError* __autoreleasing *)error {
	NSMutableArray* units = [[self units] mutableCopy];

	NSUInteger previousUnitIndex = [units indexOfObject:unit];

	if(previousUnitIndex != NSNotFound) {
		[units removeObjectAtIndex:previousUnitIndex];
	}

	if(unitIndex >= units.count) {
		[units addObject:unit];
	} else {
		[units insertObject:unit atIndex:unitIndex];
	}

	if(![[self unitStore] saveUnit:unit error:error]) { return NO; }
	if(![[self unitStore] updateSortOrderForUnits:units error:error]) { return NO; }

	[[self cache] setObject:units forKey:GRCShoppingListStoreUnitsDefaultsKey];

	[self scheduleUpdateAfterExternalStoreChange:nil];

	return YES;
}

- (BOOL)deleteUnit:(GRCUnit*)unit error:(NSError* __autoreleasing *)error {
	if(![[self unitStore] deleteUnit:unit error:error]) {
		return NO;
	}

	NSMutableArray* units = [[self units] mutableCopy];
	[units removeObject:unit];

	if(![[self unitStore] updateSortOrderForUnits:units error:error]) {
		return NO;
	}

	[self enumerateLivingShoppingListItems:^(GRCShoppingListItem* item) {
		if([[item unit] isEqual:unit]) { item.unit = [self defaultUnit]; }
	}];

	[[self cache] setObject:units forKey:GRCShoppingListStoreUnitsDefaultsKey];

	[self scheduleUpdateAfterExternalStoreChange:nil];
	
	return YES;
}

- (BOOL)saveUnit:(GRCUnit*)unit error:(NSError* __autoreleasing *)error {
	NSArray* units = [self units];

	if(![units containsObject:unit]) {
		return [self insertUnit:unit atIndex:[units count] error:error];
	}

	if(![[self unitStore] saveUnit:unit error:error]) { return NO; }
	if(![[self unitStore] updateSortOrderForUnits:[self units] error:error]) { return NO; }

	[self scheduleUpdateAfterExternalStoreChange:nil];

	return YES;
}

- (GRCUnit*)unitForDatabaseIdentifier:(NSInteger)databaseIdentifier {
	if(databaseIdentifier == GRCUnitInvalidDatabaseIdentifier) { return nil; }

	for(GRCUnit* unit in [self units]) {
		if(unit.unitDatabaseIdentifier == databaseIdentifier) { return unit; }
	}
	
	return nil;
}

- (void)loadUnitsIfNeeded {
	NSSet* allUnits = [[self unitStore] units];
	
	NSArray* orderedUnits = [[allUnits allObjects] sortedArrayUsingDescriptors:@[
		[[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES]
	]];
	
	orderedUnits = [self filteredArrayOfUnits:orderedUnits availableForLocale:[self locale]];
	
	if(orderedUnits) {
		[[self cache] setObject:orderedUnits forKey:GRCShoppingListStoreUnitsDefaultsKey];
		
		GRCUnit* defaultUnit = [self unitForDatabaseIdentifier:GRCDefaultUnitDatabaseIdentifier];
		if(defaultUnit) { [[self cache] setObject:defaultUnit forKey:GRCShoppingListStoreDefaultUnitDefaultsKey]; }
	}
}

- (NSMutableArray*)filteredArrayOfUnits:(NSArray*)units availableForLocale:(NSLocale*)locale {
	NSMutableArray* filteredUnits = [NSMutableArray arrayWithCapacity:[units count]];
	
	for(GRCUnit* unit in units) {
		NSSet* possibleStrings = [GRCUnitFormatter possibleStringsForUnit:unit locale:locale];
		if(possibleStrings.count == 0) { continue; }
		
		[filteredUnits addObject:unit];
	}
	
	return filteredUnits;
}

@end

#pragma mark - Organize

@implementation GRCShoppingListStore(Organize)

- (BOOL)moveShoppingListItems:(NSSet*)items intoShoppingList:(GRCShoppingList*)shoppingList aisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error {
	BOOL didSucceed = YES;

	[self beginUpdates];
	
	for(GRCShoppingListItem* item in items) {
		if(aisle != (id)[NSNull null]) {
			item.aisle = aisle;
		}

		if(item.shoppingList != shoppingList) {
			[[item shoppingList] didDeleteItem:item notify:NO];
			item.shoppingList = shoppingList;
		}
		
		if(![self saveShoppingListItem:item notify:NO error:error]) {
			break;
		}
	}
	
	[self endUpdatesAndCommit:didSucceed];
	
	[self scheduleUpdateAfterExternalStoreChange:nil];
	
	return didSucceed;
}

- (BOOL)copyShoppingListItems:(NSSet*)items intoShoppingList:(GRCShoppingList*)shoppingList aisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error {
	BOOL didSucceed = YES;

	[self beginUpdates];
	
	for(GRCShoppingListItem* item in items) {
		GRCShoppingListItem* newItem = [[GRCShoppingListItem alloc] init];

		newItem.title = item.title;
		newItem.notes = item.notes;

		newItem.quantity = item.quantity;
		newItem.unit = item.unit;

		newItem.completed = item.completed;

		newItem.grocery = item.grocery;

		if(aisle != (id)[NSNull null]) {
			newItem.aisle = aisle;
		} else {
			newItem.aisle = item.aisle;
		}

		newItem.shoppingList = shoppingList;
		
		if(![self saveShoppingListItem:newItem notify:NO error:error]) {
			break;
		}
	}
	
	[self endUpdatesAndCommit:didSucceed];
	
	[self scheduleUpdateAfterExternalStoreChange:nil];
	
	return didSucceed;
}

@end

#pragma mark - Recent Items

@implementation GRCShoppingListStore(RecentItems)

- (NSArray*)recentItems {
	NSArray* recentItems = [[self cache] objectForKey:GRCShoppingListStoreRecentItemsDefaultsKey];

	if(!recentItems) {
		[self loadRecentItemsIfNeeded];
		recentItems = [[self cache] objectForKey:GRCShoppingListStoreRecentItemsDefaultsKey];
	}

	return recentItems;
}

- (BOOL)markShoppingListItemAsRecentlyUsed:(GRCShoppingListItem*)shoppingListItem {
	[[self sqliteStore] beginTransaction];

	BOOL didSucceed = YES;
	GRCGrocery* grocery = shoppingListItem.grocery;

	if(grocery.groceryDatabaseIdentifier == GRCGroceryInvalidDatabaseIdentifier) {
		if(![[self groceryStore] saveGrocery:grocery locale:[self locale] error:nil]) {
			didSucceed = NO;
		}
	}

	if(didSucceed) {
		didSucceed = [[self groceryStore] markGroceryAsRecentlyUsed:grocery error:nil];
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}
	
	[[self cache] removeObjectForKey:GRCShoppingListStoreRecentItemsDefaultsKey];

	return didSucceed;
}

- (void)loadRecentItemsIfNeeded {
	NSArray* recentItems = [[self groceryStore]
		recentlyUsedGroceryItems:50
		locale:[self locale]
		error:nil];
	if(!recentItems) { return; }

	for(GRCGrocery* grocery in recentItems) {
		grocery.unit = [self unitForDatabaseIdentifier:[grocery unitDatabaseIdentifier]];
	}

	[[self cache] setObject:recentItems forKey:GRCShoppingListStoreRecentItemsDefaultsKey];
}

@end

#pragma mark - UIAdditions

@implementation GRCShoppingListStore(UIAdditions)

- (NSString*)preferredTitleForNewShoppingList {
	// determine the lists title
	NSString* newTitle = NSLocalizedString(@"NEW_SHOPPINGLIST_TITLE", nil);
	NSInteger untitledCount = 0;

	for(GRCShoppingList* shoppingList in [[self livingShoppingLists] objectEnumerator]) {
		NSString* title = shoppingList.title;
		
		if([title hasPrefix:newTitle]) {
			untitledCount = MAX(untitledCount, 1);
			
			NSInteger count = [[title stringByReplacingOccurrencesOfString:newTitle withString:@""] integerValue];
			untitledCount = MAX(untitledCount, count);
		}
	}
	
	if(untitledCount > 0) {
		++untitledCount;
		newTitle = [NSString stringWithFormat:@"%@ %@",
			newTitle,
			[NSNumberFormatter localizedStringFromNumber:@(untitledCount) numberStyle:NSNumberFormatterDecimalStyle]];
	}
	
	return newTitle;
}

@end

#pragma mark - RemainingItems

@implementation GRCShoppingListStore(RemainingItems)

-(NSUInteger)numberOfRemainingShoppingListItems {
	NSString* SQL = @"SELECT COUNT(*) AS count FROM shoppinglist_items WHERE checked!=1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return @([coder decodeIntegerForKey:@"count"]);
	}];

	NSUInteger numberOfRemainingShoppingListItems = [[enumerator nextObject] unsignedIntegerValue];
	return numberOfRemainingShoppingListItems;
}

- (void)updateRemainingItemsBadgeIfNeeded {
	NSUInteger numberOfRemainingShoppingListItems = 0;

	BOOL reminderBadgeEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GRCReminderBadgeEnabled"];
	if(reminderBadgeEnabled) { numberOfRemainingShoppingListItems = [self numberOfRemainingShoppingListItems]; }

	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:numberOfRemainingShoppingListItems];
}

@end
