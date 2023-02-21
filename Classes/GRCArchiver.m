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

#import "GRCArchiver.h"
#import "GRCDefaultStore.h"

#import "NSString+SQL.h"

#import <zipzap/zipzap.h>

NSString* const GRCShoppingListDocumentExtension = @"groceries";

@interface GRCArchiver()

@property(nonatomic, copy, readwrite) NSString* archiveTitle;
@property(nonatomic, copy, readwrite) NSSet* shoppingListIdentifiers;

@end

@implementation GRCArchiver

#pragma mark - Construction & Destruction

- (id)initWithArchiveTitle:(NSString*)archiveTitle shoppingListIdentifiers:(NSSet*)shoppingListIdentifiers {
	if((self = [super init])) {
		self.archiveTitle = archiveTitle;
		self.shoppingListIdentifiers = shoppingListIdentifiers;
	}

	return self;
}

#pragma mark - GRCArchiver

- (NSURL*)archiveWithOptions:(NSDictionary*)options error:(NSError* __autoreleasing *)error {
	SQLiteStore* store = GRCNewDefaultStore();

	NSString* title = self.archiveTitle;
	NSURL* archiveURL = [self archiveURLForTitle:title];

	// make sure to remove any previous archive, and make all intermediate directories
	NSFileManager* fileManager = [[NSFileManager alloc] init];
	[fileManager removeItemAtURL:archiveURL error:nil];
	[fileManager createDirectoryAtURL:[archiveURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];

	// make a new archive
	ZZMutableArchive* archive = [ZZMutableArchive archiveWithContentsOfURL:archiveURL];

	NSArray* entries = @[
		[ZZArchiveEntry archiveEntryWithFileName:@"payload" compress:YES dataBlock:^NSData*(NSError** error) {
			return [self payloadData];
		}],

		[ZZArchiveEntry archiveEntryWithFileName:@"lists" compress:YES dataBlock:^NSData*(NSError** error) {
			return [self dataForShoppingLists:[self shoppingListIdentifiers] store:store];
		}],

		[ZZArchiveEntry archiveEntryWithFileName:@"aisles" compress:YES dataBlock:^NSData*(NSError** error) {
			return [self dataForAislesUsedInShoppingLists:[self shoppingListIdentifiers] store:store];
		}],

		[ZZArchiveEntry archiveEntryWithFileName:@"units" compress:YES dataBlock:^NSData*(NSError** error) {
			return [self dataForUnitsUsedInShoppingLists:[self shoppingListIdentifiers] store:store];
		}]
	];

	[archive updateEntries:entries error:nil];

	return archiveURL;
}

#pragma mark - 

- (NSURL*)archiveURLForTitle:(NSString*)title {
	if(title.length == 0) { return nil; }

	NSString* archivesPath = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".archives"];

	NSURL* temporaryURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
	temporaryURL = [temporaryURL URLByAppendingPathComponent:archivesPath isDirectory:YES];

	NSURL* archiveURL = [temporaryURL URLByAppendingPathComponent:title];
	archiveURL = [archiveURL URLByAppendingPathExtension:GRCShoppingListDocumentExtension];

	return archiveURL;
}

- (NSDictionary*)shoppingListDictionaryForIdentifier:(NSString*)identifier store:(SQLiteStore*)store {
	NSString* SQL = @"SELECT id AS 'database-identifier', persistent_id AS identifier, name AS title, strftime('%s', modification_date) AS 'modification-date' FROM shoppinglists WHERE persistent_id=:identifier LIMIT 1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:@[ identifier ] store:store error:nil];

	NSDictionary* metadata = [[query recordEnumerator] nextObject];
	return metadata;
}

- (NSData*)payloadData {
	NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithCapacity:1];

	NSString* deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
	[payload setValue:deviceIdentifier forKey:@"device-identifier"];

	NSData* data = [self dataForJSONObject:payload];
	return data;
}

- (NSData*)dataForShoppingLists:(NSSet*)shoppingListIdentifiers store:(SQLiteStore*)store {
	NSMutableArray* lists = [NSMutableArray array];

	for(NSString* shoppingListIdentifier in self.shoppingListIdentifiers) {
		NSMutableDictionary* shoppingList = [[self shoppingListDictionaryForIdentifier:shoppingListIdentifier store:store] mutableCopy];
		if(!shoppingList) { continue; }

		NSArray* items = [self itemsForShoppingList:shoppingList store:store];
		[shoppingList setValue:items forKey:@"items"];

		NSArray* deletedItems = [self deletedItemsForShoppingList:shoppingList store:store];
		[shoppingList setValue:deletedItems forKey:@"deleted-items"];
		
		[shoppingList removeObjectForKey:@"database-identifier"]; // only used for item queries

		[lists addObject:shoppingList];
	}

	NSData* data = [self dataForJSONObject:lists];
	return data;
}

- (NSArray*)itemsForShoppingList:(NSDictionary*)shoppingList store:(SQLiteStore*)store {
	NSNumber* shoppingListDatabaseIdentifier = shoppingList[@"database-identifier"];

	NSString* SQL = @"SELECT items.persistent_id AS 'identifier', aisles.persistent_id AS 'aisle-identifier', items.name AS title, items.note AS notes, items.checked AS completed, items.quantity, units.persistent_id AS 'unit-identifier', strftime('%s', items.modification_date) AS 'modification-date', strftime('%s', items.checked_modification_date) AS 'completed-modification-date', strftime('%s', items.aisle_modification_date) AS 'aisle-modification-date', strftime('%s', items.quantity_modification_date) AS 'quantity-modification-date' FROM shoppinglist_items items LEFT OUTER JOIN aisles ON items.aisle_id=aisles.id LEFT OUTER JOIN units ON items.unit_id=units.id WHERE items.shoppinglist_id=:shoppingListIdentifier";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:@[ shoppingListDatabaseIdentifier ] store:store error:nil];

	NSArray* allItems = [[query recordEnumerator] allObjects];
	return allItems;
}

- (NSArray*)deletedItemsForShoppingList:(NSDictionary*)shoppingList store:(SQLiteStore*)store {
	NSNumber* shoppingListDatabaseIdentifier = shoppingList[@"database-identifier"];
	
	NSString* SQL = @"SELECT persistent_id AS identifier, strftime('%s', deletion_date) AS 'deletion-date' FROM deleted_shoppinglist_items WHERE shoppinglist_id=:shoppingListIdentifier";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:@[ shoppingListDatabaseIdentifier ] store:store error:nil];

	NSArray* allDeletedItems = [[query recordEnumerator] allObjects];
	return allDeletedItems;
}

- (NSData*)dataForAislesUsedInShoppingLists:(NSSet*)shoppingListIdentifiers store:(SQLiteStore*)store {
	NSString* identifiersQueryString = [self queryStringForContainer:shoppingListIdentifiers];

	NSString* SQL = [NSString stringWithFormat:@"SELECT DISTINCT b.aisle_id AS 'identifier' FROM shoppinglists a, shoppinglist_items b WHERE a.id=b.shoppinglist_id AND b.aisle_id IS NOT NULL AND a.persistent_id IN (%@)", identifiersQueryString];
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:store error:nil];

	NSArray* aisleIdentifiers = [[query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [coder decodeObjectForKey:@"identifier"];
	}] allObjects];

	NSString* aisleIdentifiersQueryString = [self queryStringForContainer:aisleIdentifiers];

	SQL = [NSString stringWithFormat:@"SELECT id AS 'database-identifier', persistent_id AS identifier, name AS 'custom-title', image, custom, strftime('%%s', modification_date) AS 'modification-date' FROM aisles WHERE id IN(%@) ORDER BY sort_order", aisleIdentifiersQueryString];
	query = [SQLiteQuery queryWithFormat:SQL arguments:@[ aisleIdentifiersQueryString ] store:store error:nil];

	NSArray* allAisles = [[query recordEnumerator] allObjects];

	NSData* data = [self dataForJSONObject:allAisles];
	return data;
}

- (NSData*)dataForUnitsUsedInShoppingLists:(NSSet*)shoppingListIdentifiers store:(SQLiteStore*)store {
	NSString* identifiersQueryString = [self queryStringForContainer:shoppingListIdentifiers];

	NSString* SQL = [NSString stringWithFormat:@"SELECT DISTINCT b.unit_id AS 'identifier' FROM shoppinglists a, shoppinglist_items b WHERE a.id=b.shoppinglist_id AND b.quantity IS NOT NULL AND b.unit_id IS NOT NULL AND a.persistent_id IN (%@)", identifiersQueryString];
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:store error:nil];

	NSArray* unitIdentifiers = [[query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [coder decodeObjectForKey:@"identifier"];
	}] allObjects];

	NSString* unitIdentifiersQueryString = [self queryStringForContainer:unitIdentifiers];

	SQL = [NSString stringWithFormat:@"SELECT persistent_id AS identifier, custom, name AS 'custom-singular', plural_name AS 'custom-plural', short_name AS 'custom-abbreviation', strftime('%%s', modification_date) AS 'modification-date' FROM units WHERE id IN(%@) ORDER BY sort_order", unitIdentifiersQueryString];
	query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:store error:nil];

	NSArray* allUnits = [[query recordEnumerator] allObjects];

	NSData* data = [self dataForJSONObject:allUnits];
	return data;
}

- (NSData*)dataForJSONObject:(id)JSONObject {
	if(!JSONObject) { return nil; }

	NSJSONWritingOptions options = 0;

#ifndef NDEBUG
	options = NSJSONWritingPrettyPrinted;
#endif

	NSData* data = [NSJSONSerialization dataWithJSONObject:JSONObject options:options error:nil];
	return data;
}

- (NSString*)queryStringForContainer:(id)set {
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

@end
