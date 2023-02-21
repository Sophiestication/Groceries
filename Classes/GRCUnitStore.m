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

#import "GRCUnitStore.h"

@interface GRCUnitStore()

@property(nonatomic, strong) SQLiteStore* sqliteStore;

@end

@implementation GRCUnitStore

#pragma mark - Construction & Destruction

- (id)initWithSQLiteStore:(SQLiteStore*)SQLiteStore {
	if((self = [super init])) {
		self.sqliteStore = SQLiteStore;
	}

	return self;
}

#pragma mark - GRCUnitStore

- (GRCUnit*)newUnit {
	GRCUnit* unit = [[GRCUnit alloc] init];
	return unit;
}

- (BOOL)saveUnit:(GRCUnit*)aisle error:(NSError* __autoreleasing *)error {
	[[self sqliteStore] beginTransaction];

	BOOL didSucceed = YES;
	NSUInteger databaseIdentifier = aisle.unitDatabaseIdentifier;

	if(databaseIdentifier == GRCUnitInvalidDatabaseIdentifier) {
		didSucceed = [self insertUnit:aisle error:error];
	} else {
		didSucceed = [self updateUnit:aisle error:error];
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	return didSucceed;
}

- (BOOL)deleteUnit:(GRCUnit*)aisle error:(NSError* __autoreleasing *)error {
	NSUInteger databaseIdentifier = aisle.unitDatabaseIdentifier;
	if(databaseIdentifier == GRCUnitInvalidDatabaseIdentifier) { return YES; }

	BOOL didSucceed = YES;

	[[self sqliteStore] beginTransaction];

	NSString* SQL = @"DELETE FROM units WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:@(databaseIdentifier) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not delete unit: %@", *error);
		didSucceed = NO;
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	return didSucceed;
}

- (NSSet*)units {
	NSString* SQL = @"SELECT * FROM units";
	
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	if(!query) { return nil; }
	
	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [[GRCUnit alloc] initWithCoder:coder];
	}];
	
	NSSet* units = [NSSet setWithArray:[enumerator allObjects]];
	
	return units;
}

- (GRCUnit*)unitForDatabaseIdentifier:(NSInteger)databaseIdentifier {
	if(databaseIdentifier == GRCUnitInvalidDatabaseIdentifier) { return nil; }
	
	NSString* SQL = @"SELECT * FROM units WHERE id=:identifier LIMIT 1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	query.substitutionVariables = @{
		@"identifier": @(databaseIdentifier) };
	
	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [[GRCUnit alloc] initWithCoder:coder];
	}];
	
	GRCUnit* unit = [enumerator nextObject];
	
	return unit;
}

- (BOOL)updateSortOrderForUnits:(NSArray*)units error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE units SET sort_order=:sortOrder WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	__block BOOL didSucceed = YES;

	[[self sqliteStore] beginTransaction];

	[units enumerateObjectsUsingBlock:^(GRCUnit* unit, NSUInteger unitIndex, BOOL* stop) {
		[statement substituteObject:@([unit unitDatabaseIdentifier]) forKey:@"identifier"];
		[statement substituteObject:@(unitIndex + 1) forKey:@"sortOrder"];

		if(![statement execute:error]) {
			*stop = YES;
			didSucceed = NO;
		}
	}];

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	return didSucceed;
}

#pragma mark - Private

- (BOOL)insertUnit:(GRCUnit*)unit error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"INSERT INTO units (persistent_id, name, plural_name, plural_short_name, custom, sort_order) VALUES (:unitIdentifier, :customSingularTitle, :customPluralTitle, :customAbbreviation, :custom, :sortOrder)";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:[unit unitIdentifier] forKey:@"unitIdentifier"];
	
	[statement substituteObject:[unit customSingularTitle] forKey:@"customSingularTitle"];
	[statement substituteObject:[unit customPluralTitle] forKey:@"customPluralTitle"];
	[statement substituteObject:[unit customAbbreviation] forKey:@"customAbbreviation"];
	
	[statement substituteObject:@([unit isCustom]) forKey:@"custom"];

	[statement substituteObject:@([unit sortOrder]) forKey:@"sortOrder"];

	NSUInteger identifier = NSNotFound;

	if(![statement executeAndReturnLastRowIdentifier:&identifier error:error]) {
		return NO;
	}

	unit.unitDatabaseIdentifier = identifier;

	return YES;
}

- (BOOL)updateUnit:(GRCUnit*)unit error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE units SET persistent_id=:unitIdentifier, name=:customSingularTitle, plural_name=:customPluralTitle, plural_short_name=:customAbbreviation, custom=:custom, sort_order=:sortOrder WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:[unit unitIdentifier] forKey:@"unitIdentifier"];

	[statement substituteObject:[unit customSingularTitle] forKey:@"customSingularTitle"];
	[statement substituteObject:[unit customPluralTitle] forKey:@"customPluralTitle"];
	[statement substituteObject:[unit customAbbreviation] forKey:@"customAbbreviation"];
	
	[statement substituteObject:@([unit isCustom]) forKey:@"custom"];

	[statement substituteObject:@([unit sortOrder]) forKey:@"sort_order"];

	[statement substituteObject:@([unit unitDatabaseIdentifier]) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update aisle: %@", *error);
		return NO;
	}

	return YES;
}

@end
