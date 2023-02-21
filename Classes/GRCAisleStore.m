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

#import "GRCAisleStore.h"

@interface GRCAisleStore()

@property(nonatomic, strong) SQLiteStore* sqliteStore;

@end

@implementation GRCAisleStore

#pragma mark - Construction & Destruction

- (id)initWithSQLiteStore:(SQLiteStore*)SQLiteStore {
	if((self = [super init])) {
		self.sqliteStore = SQLiteStore;
	}

	return self;
}

#pragma mark - GRCAisleStore

- (GRCAisle*)newAisle {
	GRCAisle* newAisle = [[GRCAisle alloc] init];
	return newAisle;
}

- (BOOL)saveAisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error {
	[[self sqliteStore] beginTransaction];

	BOOL didSucceed = YES;
	NSUInteger databaseIdentifier = aisle.aisleDatabaseIdentifier;

	if(databaseIdentifier == GRCAisleInvalidDatabaseIdentifier) {
		didSucceed = [self insertAisle:aisle error:error];
	} else {
		didSucceed = [self updateAisle:aisle error:error];
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	return didSucceed;
}

- (BOOL)deleteAisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error {
	NSUInteger databaseIdentifier = aisle.aisleDatabaseIdentifier;
	if(databaseIdentifier == GRCAisleInvalidDatabaseIdentifier) { return YES; }

	BOOL didSucceed = YES;

	[[self sqliteStore] beginTransaction];

	NSString* SQL = @"DELETE FROM aisles WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:@(databaseIdentifier) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not delete aisle: %@", *error);
		didSucceed = NO;
	}

	if(didSucceed) {
		[[self sqliteStore] commitTransaction];
	} else {
		[[self sqliteStore] cancelTransaction];
	}

	return didSucceed;
}

- (NSSet*)aisles {
	NSString* SQL = @"SELECT * FROM aisles";
	
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	if(!query) { return nil; }
	
	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [[GRCAisle alloc] initWithCoder:coder];
	}];
	
	NSSet* aisles = [NSSet setWithArray:[enumerator allObjects]];
	
	return aisles;
}

- (GRCAisle*)aisleForDatabaseIdentifier:(NSInteger)databaseIdentifier {
	if(databaseIdentifier == GRCAisleInvalidDatabaseIdentifier) { return nil; }
	
	NSString* SQL = @"SELECT * FROM aisles WHERE id=:identifier LIMIT 1";
	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:[self sqliteStore] error:nil];
	
	query.substitutionVariables = @{
		@"identifier": @(databaseIdentifier) };
	
	NSEnumerator* enumerator = [query recordEnumeratorWithUnarchiveBlock:^id (NSCoder* coder) {
		return [[GRCAisle alloc] initWithCoder:coder];
	}];
	
	GRCAisle* aisle = [enumerator nextObject];
	
	return aisle;
}

- (BOOL)updateSortOrderForAisles:(NSArray*)aisles error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE aisles SET sort_order=:sortOrder WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	__block BOOL didSucceed = YES;

	[[self sqliteStore] beginTransaction];

	[aisles enumerateObjectsUsingBlock:^(GRCAisle* aisle, NSUInteger aisleIndex, BOOL* stop) {
		[statement substituteObject:@([aisle aisleDatabaseIdentifier]) forKey:@"identifier"];
		[statement substituteObject:@(aisleIndex + 1) forKey:@"sortOrder"];

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

- (BOOL)insertAisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"INSERT INTO aisles (persistent_id, name, image, custom, sort_order) VALUES (:aisleIdentifier, :customTitle, :image, :custom, :sortOrder)";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:[aisle aisleIdentifier] forKey:@"aisleIdentifier"];
	
	[statement substituteObject:[aisle customTitle] forKey:@"customTitle"];
	[statement substituteObject:[aisle image] forKey:@"image"];

	id isCustom = aisle.custom ? @(1) : [NSNull null];
	[statement substituteObject:isCustom forKey:@"custom"];

	[statement substituteObject:@([aisle sortOrder]) forKey:@"sortOrder"];

	NSUInteger identifier = NSNotFound;

	if(![statement executeAndReturnLastRowIdentifier:&identifier error:error]) {
		return NO;
	}

	aisle.aisleDatabaseIdentifier = identifier;

	return YES;
}

- (BOOL)updateAisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error {
	NSString* SQL = @"UPDATE aisles SET persistent_id=:aisleIdentifier, name=:name, image=:image, sort_order=:sortOrder WHERE id=:identifier";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	[statement substituteObject:[aisle aisleIdentifier] forKey:@"aisleIdentifier"];

	[statement substituteObject:[aisle customTitle] forKey:@"name"];
	[statement substituteObject:[aisle image] forKey:@"image"];

	[statement substituteObject:@([aisle sortOrder]) forKey:@"sort_order"];

	[statement substituteObject:@([aisle aisleDatabaseIdentifier]) forKey:@"identifier"];

	if(![statement execute:error]) {
		NSLog(@"Could not update aisle: %@", *error);
		return NO;
	}

	return YES;
}

@end
