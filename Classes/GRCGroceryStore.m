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

#import "GRCGroceryStore.h"

#import "SQLite.h"

#import "GRCGrocery.h"
#import "GRCAisle.h"
#import "GRCUnit.h"

#import "GRCInflector.h"

#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"
#import "NSString+Additions.h"

@interface GRCGroceryStore()

@property(nonatomic, strong) SQLiteStore* sqliteStore;
@property(atomic, strong) GRCInflector* inflector;

@end

@implementation GRCGroceryStore

#pragma mark - Construction & Destruction

- (id)initWithSQLiteStore:(SQLiteStore*)SQLiteStore {
	if((self = [super init])) {
		self.sqliteStore = SQLiteStore;
	}
	
	return self;
}

#pragma mark - GRCGroceryStore

- (GRCGrocery*)groceryForDatabaseIdentifier:(NSUInteger)groceryDatabaseIdentifier {
	if(groceryDatabaseIdentifier == GRCGroceryInvalidDatabaseIdentifier) { return nil; }

	NSString* SQL = @"SELECT * FROM groceries WHERE id=:identifier LIMIT 1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	query.substitutionVariables = @{
		@"identifier": @(groceryDatabaseIdentifier) };
	
	GRCGrocery* grocery = [[self groceryEnumeratorForQuery:query] nextObject];
	
	return grocery;
}

- (GRCGrocery*)groceryForTitle:(NSString*)title locale:(NSLocale*)locale {
	if(title.length == 0) { return nil; }
	
	NSString* SQL = @"SELECT * FROM groceries WHERE name=:title AND language=:language LIMIT 1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	query.substitutionVariables = @{
		@"title": title,
		@"language": @([[self class] languageDatabaseIdentifierForLocale:locale]) };
	
	GRCGrocery* grocery = [[self groceryEnumeratorForQuery:query] nextObject];
	
	return grocery;
}

- (GRCGrocery*)matchingGroceryForString:(NSString*)string locale:(NSLocale*)locale {
	GRCGrocery* grocery;

	// simple match by title
	NSString* title = string;
	grocery = [self groceryForTitle:title locale:locale];
	if(grocery) { return grocery; }

	GRCInflector* inflector = [self sharedInflectorForLocale:locale];

	// try plural form
	NSString* pluralTitle = [inflector pluralize:title];

	if(![title isEqualToString:pluralTitle]) {
		grocery = [self groceryForTitle:pluralTitle locale:locale];
		if(grocery) { return grocery; }
	}

	// try singular form
	NSString* singularTitle = [inflector singularize:title];

	if(![title isEqualToString:singularTitle]) {
		grocery = [self groceryForTitle:singularTitle locale:locale];
		if(grocery) { return grocery; }
	}

	return nil;
}

- (NSEnumerator*)allGroceriesForLocale:(NSLocale*)locale error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"SELECT * FROM groceries WHERE language=:language";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	query.substitutionVariables = @{
		@"language": @([[self class] languageDatabaseIdentifierForLocale:locale]) };
	
	NSEnumerator* enumerator = [self groceryEnumeratorForQuery:query];
	return enumerator;
}

- (BOOL)saveGrocery:(GRCGrocery*)grocery locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error {
	[[self sqliteStore] beginTransaction];

	BOOL didSucceed = YES;
	NSUInteger databaseIdentifier = grocery.groceryDatabaseIdentifier;

	if(databaseIdentifier == GRCGroceryInvalidDatabaseIdentifier) {
		didSucceed = [self insertGrocery:grocery locale:locale error:error];
	} else {
		didSucceed = [self updateGrocery:grocery locale:locale error:error];
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	return didSucceed;
}

- (BOOL)deleteGrocery:(GRCGrocery*)grocery locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error {
	NSUInteger databaseIdentifier = grocery.groceryDatabaseIdentifier;
	if(databaseIdentifier == GRCGroceryInvalidDatabaseIdentifier) { return YES; }

	BOOL didSucceed = YES;

	[[self sqliteStore] beginTransaction];

	NSString* SQL = @"DELETE FROM groceries WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:@(databaseIdentifier) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not delete grocery: %@", *error);
		didSucceed = NO;
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	return didSucceed;
}

#pragma mark - Private

+ (NSURL*)standardGroceryStoreURL {
	return [[NSBundle mainBundle] URLForResource:@"standard-groceries" withExtension:@"sqlite"];
}

+ (NSURL*)groceryStoreURL {
	NSURL* applicationSupportURL = [[[NSFileManager defaultManager]
		URLsForDirectory:NSApplicationSupportDirectory
		inDomains:NSUserDomainMask] firstObject];
		
	NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:bundleIdentifier];
	
	NSURL* groceryStoreURL = [applicationSupportURL URLByAppendingPathComponent:@"groceries.sqlite"];
	return groceryStoreURL;
}

+ (NSURL*)legacyGroceryStoreURL2 {
	NSURL* applicationDocumentsURL = [[[NSFileManager defaultManager]
		URLsForDirectory:NSDocumentDirectory
		inDomains:NSUserDomainMask] firstObject];
	
	NSURL* legacyGroceryStoreURL = [applicationDocumentsURL URLByAppendingPathComponent:@"My Groceries"];
	return legacyGroceryStoreURL;
}

+ (NSURL*)legacyGroceryStoreURL {
	NSURL* applicationSupportURL = [[[NSFileManager defaultManager]
		URLsForDirectory:NSApplicationSupportDirectory
		inDomains:NSUserDomainMask] firstObject];
		
	NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:bundleIdentifier];
	
	NSURL* legacyGroceryStoreURL = [applicationSupportURL URLByAppendingPathComponent:@"My Groceries"];
	return legacyGroceryStoreURL;
}

- (BOOL)insertGrocery:(GRCGrocery*)grocery locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"INSERT INTO groceries (persistent_id, language, name, note, custom, generic, aisle_id, quantity, unit_id) VALUES (:identifier, :language, :title, :notes, :custom, :generic, :aisle, :quantity, :uni)";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	NSString* identifier = grocery.groceryIdentifier;
	if(identifier.length == 0) { identifier = [NSString stringWithUUID]; }
	[statement substituteObject:identifier forKey:@"identifier"];

	NSUInteger languageDatabaseIdentifier = [[self class] languageDatabaseIdentifierForLocale:locale];
	[statement substituteObject:@(languageDatabaseIdentifier) forKey:@"language"];
	
	[statement substituteObject:[grocery title] forKey:@"title"];
	[statement substituteObject:[grocery notes] forKey:@"notes"];

	[statement substituteObject:@([grocery custom]) forKey:@"custom"];
	[statement substituteObject:@([grocery generic]) forKey:@"generic"];

	if(grocery.aisleDatabaseIdentifier == GRCAisleInvalidDatabaseIdentifier) {
		[statement substituteObject:[NSNull null] forKey:@"aisle"];
	} else {
		[statement substituteObject:@([grocery aisleDatabaseIdentifier]) forKey:@"aisle"];
	}

	[statement substituteObject:[grocery quantity] forKey:@"quantity"];

	NSUInteger unitDatabaseIdentifier = grocery.unit ?
		grocery.unit.unitDatabaseIdentifier : grocery.unitDatabaseIdentifier;

	if(unitDatabaseIdentifier == GRCUnitInvalidDatabaseIdentifier) {
		[statement substituteObject:[NSNull null] forKey:@"unit"];
	} else {
		[statement substituteObject:@(unitDatabaseIdentifier) forKey:@"unit"];
	}

	NSUInteger databaseIdentifier = NSNotFound;

	if(![statement executeAndReturnLastRowIdentifier:&databaseIdentifier error:error]) {
		return NO;
	}

	grocery.groceryDatabaseIdentifier = databaseIdentifier;

	return YES;
}

- (BOOL)updateGrocery:(GRCGrocery*)grocery locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE groceries SET language=:language, name=:title, note=:notes, custom=:custom, generic=:generic, aisle_id=:aisle, quantity=:quantity, unit_id=:unit WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	NSUInteger languageDatabaseIdentifier = [[self class] languageDatabaseIdentifierForLocale:locale];
	[statement substituteObject:@(languageDatabaseIdentifier) forKey:@"language"];
	
	[statement substituteObject:[grocery title] forKey:@"title"];
	[statement substituteObject:[grocery notes] forKey:@"notes"];

	[statement substituteObject:@([grocery custom]) forKey:@"custom"];
	[statement substituteObject:@([grocery generic]) forKey:@"generic"];

	if(grocery.aisleDatabaseIdentifier == GRCAisleInvalidDatabaseIdentifier) {
		[statement substituteObject:[NSNull null] forKey:@"aisle"];
	} else {
		[statement substituteObject:@([grocery aisleDatabaseIdentifier]) forKey:@"aisle"];
	}

	[statement substituteObject:[grocery quantity] forKey:@"quantity"];

	NSUInteger unitDatabaseIdentifier = grocery.unit ?
		grocery.unit.unitDatabaseIdentifier : grocery.unitDatabaseIdentifier;

	if(unitDatabaseIdentifier == GRCUnitInvalidDatabaseIdentifier) {
		[statement substituteObject:[NSNull null] forKey:@"unit"];
	} else {
		[statement substituteObject:@(unitDatabaseIdentifier) forKey:@"unit"];
	}

	[statement substituteObject:@([grocery groceryDatabaseIdentifier]) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update grocery: %@", *error);
		return NO;
	}

	return YES;
}

- (NSEnumerator*)groceryEnumeratorForQuery:(SQLiteQuery*)query {
	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [[GRCGrocery alloc] initWithCoder:coder];
	}];

	return enumerator;
}

- (GRCInflector*)sharedInflectorForLocale:(NSLocale*)locale {
	GRCInflector* inflector = self.inflector;
	if([[inflector locale] isEqual:locale]) { return inflector; }

	inflector = [[GRCInflector alloc] initWithLocale:locale];
	self.inflector = inflector;

	return inflector;
}

@end

#pragma mark - Locale

@implementation GRCGroceryStore(Locale)

NSUInteger const GRCGroceryStoreLanguageDatabaseIdentifierEnglish = 1;
NSUInteger const GRCGroceryStoreLanguageDatabaseIdentifierGerman = 2;
NSUInteger const GRCGroceryStoreLanguageDatabaseIdentifierFrench = 3;

+ (NSUInteger)languageDatabaseIdentifierForLocale:(NSLocale*)locale {
	NSString* languageCode = [locale preferredLanguageCode];

	if([languageCode isEqualToString:@"de"]) { return GRCGroceryStoreLanguageDatabaseIdentifierGerman; }
	if([languageCode isEqualToString:@"fr"]) { return GRCGroceryStoreLanguageDatabaseIdentifierFrench; }

	return GRCGroceryStoreLanguageDatabaseIdentifierEnglish;
}

@end

#pragma mark - Autocompletion

NSString* const GRCGroceryStoreAutocompletionScopeGenerics = @"grocery";
NSString* const GRCGroceryStoreAutocompletionScopeBrands = @"brand";

@implementation GRCGroceryStore(Autocompletion)

- (NSEnumerator*)autocompleteWithStrings:(NSSet*)strings scope:(NSString*)scope locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error {
	if(strings.count == 0) { return nil; }

	NSMutableArray* newStrings = [NSMutableArray arrayWithCapacity:[strings count]];

	for(NSString* string in strings) {
		NSString* newString = [NSRegularExpression escapedPatternForString:string];
		newString = [newString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
		newString = [newString stringByAppendingString:@"*"];

		if(newString) { [newStrings addObject:newString]; }
	}

	NSString* predicateString = [newStrings componentsJoinedByString:@" "];
	if(predicateString == nil) { predicateString = @""; }

	NSUInteger languageDatabaseIdentifier = [[self class] languageDatabaseIdentifierForLocale:locale];

	NSString* autocompletionQueryString = @"SELECT docid FROM autocomplete WHERE name MATCH :predicate AND language=:language";
	NSString* queryString = [NSString stringWithFormat:@"SELECT groceries.* FROM groceries OUTER LEFT JOIN recently_used_groceries AS recents ON groceries.id=recents.grocery_id WHERE id IN (%@) ORDER BY recents.last_used_date DESC, custom DESC, generic DESC, LENGTH(name), name LIMIT :limit", autocompletionQueryString];

	SQLiteQuery* query = [SQLiteQuery queryWithFormat:queryString arguments:nil store:[self sqliteStore] error:error];

	query.substitutionVariables = @{
		@"predicate": predicateString,
		@"language": @(languageDatabaseIdentifier),
		@"limit": @(25) };

	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [[GRCGrocery alloc] initWithCoder:coder];
	}];
		
	return enumerator;
}

@end

#pragma mark - Recent Items

@implementation GRCGroceryStore(RecentItems)

- (NSArray*)recentlyUsedGroceryItems:(NSUInteger)limit locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error {
	if(limit <= 0) { return @[]; }
	
	NSString* SQL = @"SELECT groceries.* FROM recently_used_groceries AS recents INNER JOIN groceries ON recents.grocery_id=groceries.id WHERE groceries.language=:language ORDER BY recents.last_used_date DESC LIMIT :limit";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	query.substitutionVariables = @{
		@"limit": @(limit),
		@"language": @([[self class] languageDatabaseIdentifierForLocale:locale]) };
	
	NSArray* recentlyUsedGroceryItems = [[self groceryEnumeratorForQuery:query] allObjects];

	recentlyUsedGroceryItems = [recentlyUsedGroceryItems sortedArrayUsingDescriptors:
		@[ [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] ]];

	return recentlyUsedGroceryItems;
}

- (BOOL)markGroceryAsRecentlyUsed:(GRCGrocery*)grocery error:(NSError* __autoreleasing *)error {
	if(!grocery) { return YES; }
	if(grocery.groceryDatabaseIdentifier == GRCGroceryInvalidDatabaseIdentifier) { return YES; }

	NSString* SQL = @"INSERT OR REPLACE INTO recently_used_groceries (grocery_id) VALUES (:groceryDatabaseIdentifier);";
	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	
	NSUInteger groceryDatabaseIdentifier = grocery.groceryDatabaseIdentifier;
	[statement substituteObject:@(groceryDatabaseIdentifier) forKey:@"groceryDatabaseIdentifier"];
	
	if(![statement execute:error]) {
		NSLog(@"Could not mark grocery item as recently used: %@", *error);
		return NO;
	}
	
	return YES;
}

@end
