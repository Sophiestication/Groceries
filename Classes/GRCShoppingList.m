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

#import "GRCShoppingList.h"
#import "GRCShoppingList+Private.h"

#import "GRCShoppingListItem+Private.h"

#import "GRCReminderMetadataMigration.h"
#import "GRCReminderMetadata.h"

#import "GRCDetector.h"

#import "NSString+Additions.h"

@implementation GRCShoppingList

NSUInteger const GRCShoppingListInvalidDatabaseIdentifier = NSNotFound;

@dynamic numberOfRemainingItems;

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		self.shoppingListDatabaseIdentifier = GRCShoppingListInvalidDatabaseIdentifier;
		self.shoppingListIdentifier = [NSString stringWithUUID];

		self.sortOrder = NSIntegerMax;

		self.needsUpdate = YES;

		self.consumers = [NSMapTable
			mapTableWithKeyOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPersonality
			valueOptions:NSPointerFunctionsCopyIn|NSPointerFunctionsStrongMemory];
	}

	return self;
}

#pragma mark - CGCShoppingList

- (void)addConsumer:(id)consumer callback:(void (^)(NSSet* items))callback {
	// if(self.consumers.count == 0) { self.needsUpdate = YES; }

	[[self consumers] setObject:callback forKey:consumer];

	if(self.needsUpdate) {
		[self updateShoppingListItemsIfNeeded];
	} else {
		dispatch_async(dispatch_get_main_queue(), ^() {
			NSSet* items = [NSSet setWithArray:[[self items] allValues]];
			[self notifyConsumersAboutItems:items changes:nil];
		});
	}
}

- (void)removeConsumer:(id)consumer {
	[[self consumers] removeObjectForKey:consumer];
}

- (NSUInteger)numberOfRemainingItems {
	if(self.cachedNumberOfRemainingItems && !self.needsUpdate) {
		return [[self cachedNumberOfRemainingItems] unsignedIntegerValue];
	}

	NSString* SQL = @"SELECT COUNT(*) AS 'count' FROM shoppinglist_items WHERE shoppinglist_id=:shoppingListIdentifier AND checked!=1";

	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[[self store] sqliteStore] error:nil];
	query.substitutionVariables = @{
		@"shoppingListIdentifier": @([self shoppingListDatabaseIdentifier]) };

	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id(NSCoder* coder) {
		return @([coder decodeIntegerForKey:@"count"]);
	}];
	
	self.cachedNumberOfRemainingItems = [enumerator nextObject];
	return [[self cachedNumberOfRemainingItems] unsignedIntegerValue];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(![object isKindOfClass:[self class]]) { return NO; }
	return [[self shoppingListIdentifier] isEqual:[object shoppingListIdentifier]];
}

- (NSUInteger)hash {
	return [[self shoppingListIdentifier] hash];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {id = %@, title = %@}",
		[super description],
		[self shoppingListIdentifier],
		[self title]];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)coder {
	if((self = [self init])) {
		self.shoppingListDatabaseIdentifier = [coder decodeIntegerForKey:@"id"];
		self.shoppingListIdentifier = [coder decodeObjectForKey:@"persistent_id"];

		self.title = [coder decodeObjectForKey:@"name"];

		self.sortOrder = [coder decodeIntegerForKey:@"sort_order"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder {
	[NSException raise:@"encodeWithCoder not implemented" format:@""];
}

#pragma mark - Private

- (void)updateShoppingListItemsIfNeeded {
	if(!self.needsUpdate) { return; }
	if(self.updating) { return; }
	if(self.consumers.count == 0) { return; }

	[self updateShoppingListItems];
}

- (void)updateShoppingListItems {
	self.updating = YES;
	self.needsUpdate = NO;

	NSString* SQL = @"SELECT * FROM shoppinglist_items WHERE shoppinglist_id=:shoppingListIdentifier";

	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[[self store] sqliteStore] error:nil];
	query.substitutionVariables = @{
		@"shoppingListIdentifier": @([self shoppingListDatabaseIdentifier]) };
	
	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [[GRCShoppingListItem alloc] initWithCoder:coder store:[self store]];
	}];

	NSMutableDictionary* items = [NSMutableDictionary dictionaryWithCapacity:10];
	
	for(GRCShoppingListItem* item in enumerator) {
		item.shoppingList = self;
		[items setObject:item forKey:[item shoppingListItemIdentifier]];
	}

//	dispatch_async(dispatch_get_main_queue(), ^() {
		self.updating = NO;
		self.items = items;

		[self notifyConsumersAboutItems:[NSSet setWithArray:[items allValues]] changes:nil];
		[self updateShoppingListItemsIfNeeded]; // in case of pending updates
//	});

	// fetching might fail
	if(!enumerator) {
//		dispatch_async(dispatch_get_main_queue(), ^() {
			self.updating = NO;
			[self notifyConsumersAboutItems:nil changes:nil];
//		});
	}
}

- (void)didSaveItem:(GRCShoppingListItem*)item notify:(BOOL)notify {
	self.cachedNumberOfRemainingItems = nil;

	[[self items] setObject:item forKey:[item shoppingListItemIdentifier]];
	if(notify) { [self notifyConsumers]; }
}

- (void)didDeleteItem:(GRCShoppingListItem*)item notify:(BOOL)notify {
	self.cachedNumberOfRemainingItems = nil;

	[[self items] removeObjectForKey:[item shoppingListItemIdentifier]];
	if(notify) { [self notifyConsumers]; }
}

- (void)notifyConsumers {
	NSSet* items = [NSSet setWithArray:[[self items] allValues]];
	
//	dispatch_async(dispatch_get_main_queue(), ^() {
		[self notifyConsumersAboutItems:items changes:nil];
//	});
}

- (void)notifyConsumersAboutItems:(NSSet*)items changes:(NSArray*)changes {
	for(void (^callback)(NSSet* items) in [[self consumers] objectEnumerator]) {
		callback(items);
	}
}

@end

#pragma mark - Item

@implementation GRCShoppingList(Item)

- (GRCShoppingListItem*)newItemForGrocery:(GRCGrocery*)grocery {
	GRCShoppingListItem* item = [[GRCShoppingListItem alloc] init];
	
	item.shoppingList = self;
	
	item.title = grocery.title;
	item.notes = grocery.notes;

	item.quantity = grocery.quantity;

	GRCUnit* unit = grocery.unit; // unit from the data detector
	if(!unit) { unit = [[self store] unitForDatabaseIdentifier:[grocery unitDatabaseIdentifier]]; } // grocery default
	if(!unit) { unit = [[self store] defaultUnit]; } // default unit
	item.unit = unit;
	
	item.aisle = [[self store] aisleForDatabaseIdentifier:[grocery aisleDatabaseIdentifier]];
	
	item.grocery = grocery;
	
	return item;
}

@end
