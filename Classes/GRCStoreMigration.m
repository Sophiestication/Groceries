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

#import "GRCStoreMigration.h"

#import "GRCDefaultStore.h"

#import "GRCUnit.h"
#import "GRCAisle.h"
#import "GRCGrocery.h"

#import "GRCGroceryStore.h"

NSInteger const GRCCurrentDefaultStoreVersion = 311;
NSInteger const GRCDefaultStoreVersion310 = 310;
NSInteger const GRCDefaultStoreVersion300 = 300;

@interface GRCStoreMigration()

@property(nonatomic, strong) SQLiteStore* sqliteStore;
@property(nonatomic) NSInteger storeVersion;

@end

@implementation GRCStoreMigration

#pragma mark - Construction & Destruction

- (id)initWithSQLiteStore:(SQLiteStore*)SQLiteStore {
	if((self = [super init])) {
		self.sqliteStore = SQLiteStore;

		NSInteger storeVersion = [[SQLiteStore pragmaValueForKey:@"user_version"] integerValue];
		self.storeVersion = storeVersion;
	}

	return self;
}

#pragma mark - GRCStoreMigration

- (BOOL)migrateIfNeeded:(NSError* __autoreleasing *)error {
	BOOL didSucceed = YES;
	BOOL didMigrate = NO;
	
	if(self.storeVersion < GRCDefaultStoreVersion300) {
		didMigrate = YES;

		[[self sqliteStore] beginTransaction];
		didSucceed = [self migrateFrom223:error];
		
		if(didSucceed) {
			[[self sqliteStore] commitTransaction];
		} else {
			[[self sqliteStore] cancelTransaction];
		}
	}

	if(self.storeVersion <= GRCDefaultStoreVersion310) {
		didMigrate = YES;

		[[self sqliteStore] beginTransaction];
		didSucceed = [self migrateFrom310:error];
		
		if(didSucceed) {
			[[self sqliteStore] commitTransaction];
		} else {
			[[self sqliteStore] cancelTransaction];
		}
	}

	if(didMigrate && didSucceed) {
		[[self sqliteStore] setPragmaValue:@(GRCCurrentDefaultStoreVersion) forKey:@"user_version"];
		// [[self sqliteStore] executeSQL:@"VACUUM" error:nil]; // ignore on fail
	}

	return didSucceed;
}

#pragma mark - Version 2.2.3

- (BOOL)migrateFrom223:(NSError* __autoreleasing *)error {
	if(![self migrateSchemeFrom223:error]) { return NO; }
	if(![self migrateUnitsFrom223:error]) { return NO; }
	if(![self migrateAislesFrom223:error]) { return NO; }

	return YES;
}

- (BOOL)migrateSchemeFrom223:(NSError* __autoreleasing *)error {
	NSURL* scriptURL = [[NSBundle mainBundle] URLForResource:@"migration-223" withExtension:@"sql"];

	NSString* SQL = [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:error];
	if(!SQL) { return NO; }

	if(![[self sqliteStore] executeSQL:SQL error:error]) { return NO; }
	return YES;
}

- (BOOL)migrateUnitsFrom223:(NSError* __autoreleasing *)error {
	// update unit identifiers
	NSString* SQL = @"UPDATE units SET persistent_id=:unitIdentifier WHERE id=:identifier AND persistent_id IS NULL";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	NSArray* standardUnits = [GRCUnit standardUnits];

	for(GRCUnit* unit in standardUnits) {
		[statement substituteObject:[unit unitIdentifier] forKey:@"unitIdentifier"];
		[statement substituteObject:@([unit unitDatabaseIdentifier]) forKey:@"identifier"];

		if(![statement execute:error]) { return NO; }
	}

	return YES;
}

- (BOOL)migrateAislesFrom223:(NSError* __autoreleasing *)error {
	// update aisle identifiers
	NSString* SQL = @"UPDATE aisles SET persistent_id=:aisleIdentifier WHERE id=:identifier AND persistent_id IS NULL";

	SQLiteStatement* statement = [SQLiteStatement statementWithFormat:SQL arguments:nil store:[self sqliteStore] error:error];
	if(!statement) { return NO; }

	NSArray* standardAisles = [GRCAisle standardAisles];

	for(GRCAisle* aisle in standardAisles) {
		[statement substituteObject:[aisle aisleIdentifier] forKey:@"aisleIdentifier"];
		[statement substituteObject:@([aisle aisleDatabaseIdentifier]) forKey:@"identifier"];

		if(![statement execute:error]) { return NO; }
	}
	
	// delete obsolete standard aisles
	[[self sqliteStore] executeSQL:@"DELETE FROM aisles WHERE persistent_id IS NULL AND custom=0" error:nil];

	return YES;
}

#pragma mark - Version 3.1.0

- (BOOL)migrateFrom310:(NSError* __autoreleasing *)error {
	if(![self migrateAutocompletionIndexFrom310:error]) { return NO; }

	return YES;
}

- (BOOL)migrateAutocompletionIndexFrom310:(NSError* __autoreleasing *)error {
	NSURL* scriptURL = [[NSBundle mainBundle] URLForResource:@"migration-310" withExtension:@"sql"];

	NSString* SQL = [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:error];
	if(!SQL) { return NO; }

	if(![[self sqliteStore] executeSQL:SQL error:error]) { return NO; }

	return YES;
}

@end
