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

#import "SQLiteStore.h"
#import "SQLiteStore+Private.h"

#import "NSError+SQLite.h"
#import "NSString+SQL.h"

#import "SQLiteQuery.h"
#import "SQLiteQuery+Private.h"

@implementation SQLiteStore

#pragma mark - Construction & Destruction

- (id)initWithContentsOfURL:(NSURL*)URL error:(NSError* __autoreleasing *)error {
	return [self initWithContentsOfURL:URL options:SQLITE_OPEN_READWRITE|SQLITE_OPEN_SHAREDCACHE error:error];
}

- (id)initWithContentsOfURL:(NSURL*)URL options:(int)options error:(NSError* __autoreleasing *)error {
	if((self = [super init])) {
		self.transactionCount = 0;

		// Enable shared caches
		sqlite3_enable_shared_cache(1);
	
		// Open the database file
		int result = sqlite3_open_v2([[URL relativePath] UTF8String], &_handle, options, NULL);
	
		if(result == SQLITE_OK) {
			#ifdef SQLITE_DEBUG
				sqlite3_commit_hook(_handle, sqlitestore_commit_handler, (__bridge void*)self);
				sqlite3_rollback_hook(_handle, sqlitestore_rollback_handler, (__bridge void*)self);
				sqlite3_update_hook(_handle, sqlitestore_update_handler, (__bridge void*)self);
			#endif

			// Set some pragmas
			[self setPragmaValue:@"1" forKey:@"cache_size"];
			[self setPragmaValue:@"FULL" forKey:@"synchronous"];
			[self setPragmaValue:@"NORMAL" forKey:@"locking_mode"];
			// [self setPragmaValue:@"1" forKey:@"fullfsync"];
			// [self setPragmaValue:@"1" forKey:@"vdbe_listing"];
			
			#ifdef SQLITE_DEBUG
				NSLog(@"Opened file %@ with sqlite %s%s", [URL path], sqlite3_libversion(), sqlite3_threadsafe() ? " (threadsafe)" : "");
			#endif
			
			if(error) { *error = nil; }
		} else {
			if(error) { *error = [NSError SQLiteErrorForDatabase:_handle]; }
			return nil;
		}
	}

	return self;
}

- (void)dealloc {
	sqlite3_close_v2(_handle);
}

#pragma mark - SQLiteStore

- (void)beginTransaction {
	if(self.transactionCount == 0) {
#ifdef SQLITE_DEBUG
		NSLog(@"BEGIN TRANSACTION");
#endif

		[self executeSQL:@"BEGIN TRANSACTION" error:nil];
	}
	
	++self.transactionCount;
}

- (void)commitTransaction {
	--self.transactionCount;

	if(self.transactionCount == 0) {
		[self executeSQL:@"COMMIT TRANSACTION" error:nil];
	}
}

- (void)cancelTransaction {
	--self.transactionCount;

	if(self.transactionCount == 0) {
		[self executeSQL:@"ROLLBACK TRANSACTION" error:nil];
	}
}

- (id)pragmaValueForKey:(NSString*)pragmaKey {
	NSString* SQL = [NSString stringWithFormat:@"PRAGMA %@", pragmaKey];
	NSError* error;

	SQLiteQuery* query = [SQLiteQuery queryWithFormat:SQL arguments:nil store:self error:&error];

	if(error) {
		NSLog(@"Error while reading pragma: %@", error);
	}

	id pragmaValue = [[query recordEnumeratorWithUnarchiveBlock:^ id (NSCoder* unarchiver) {
		return [unarchiver decodeObjectForKey:pragmaKey];
	}] nextObject];

	[query resetCursors];

	return pragmaValue;
}

- (void)setPragmaValue:(id)pragmaValue forKey:(NSString*)pragmaKey {
	if([pragmaValue respondsToSelector:@selector(stringValue)]) {
		pragmaValue = [pragmaValue stringValue];
	}

	if([pragmaValue respondsToSelector:@selector(stringByEscapingSQLCharacters)]) {
		pragmaValue = [NSString stringWithFormat:@"'%@'", [pragmaValue stringByEscapingSQLCharacters]];
	}

	NSString* SQL = [NSString stringWithFormat:@"PRAGMA %@ = %@", pragmaKey, pragmaValue];
	NSError* error;

	[self executeSQL:SQL error:&error];
	
	if(error) {
		NSLog(@"Error while setting pragma: %@", error);
	}
}

- (BOOL)executeSQL:(NSString*)SQL error:(NSError* __autoreleasing *)error {
	int result = sqlite3_exec([self handle], [SQL UTF8String], NULL, NULL, NULL);
	
	if(result == SQLITE_OK || result == SQLITE_DONE) {
		return YES;
	}
	
	// Something went wrong
	NSError* e = [NSError SQLiteErrorForDatabase:[self handle]];
	
	if(error) {
		*error = e;
	} else {
		NSLog(@"Error while executing SQL statement: %@", e);
	}
	
	return NO;
}

- (void)interrupt {
	sqlite3_interrupt([self handle]);
}

- (void)close {
	sqlite3_close(_handle), _handle = NULL;
}

- (BOOL)attachContentsOfURL:(NSURL*)URL alias:(NSString*)alias error:(NSError* __autoreleasing *)error {
	if([[self attachedDatabaseURLs] objectForKey:alias]) { return YES; }

	NSString* SQL = [NSString stringWithFormat:@"ATTACH '%@' AS '%@'",
		[[URL path] stringByEscapingSQLCharacters],
		[alias stringByEscapingSQLCharacters]];
	
	if([self executeSQL:SQL error:error]) {
		if(!self.attachedDatabaseURLs) { self.attachedDatabaseURLs = [NSMutableDictionary dictionaryWithCapacity:1]; }
		[[self attachedDatabaseURLs] setObject:URL forKey:alias];
		
		return YES;
	}

	return NO;
}

- (BOOL)detachDatabaseWithAliasIfNeeded:(NSString*)alias error:(NSError* __autoreleasing *)error {
	if(![[self attachedDatabaseURLs] objectForKey:alias]) { return YES; }

	NSString* SQL = [NSString stringWithFormat:@"DETACH '%@'", [alias stringByEscapingSQLCharacters]];
	
	if([self executeSQL:SQL error:error]) {
		[[self attachedDatabaseURLs] removeObjectForKey:alias];
		
		return YES;
	}

	return NO;
}

#pragma mark - Private

int sqlitestore_commit_handler(void* pointer) {
	NSLog(@"COMMIT");
	return SQLITE_OK;
}

void sqlitestore_rollback_handler(void* pointer) {
	NSLog(@"ROLLBACK");
}

void sqlitestore_update_handler(void* pointer, int operation, char const* databaseName, char const* tableName, sqlite_int64 rowID) {
	// SQLiteStore* persistentStore = (__bridge id)pointer;
	return;
	if(operation == SQLITE_DELETE) {
		NSLog(@"DELETE FROM %s.%s WHERE rowid=%qi", databaseName, tableName, rowID);
	} else if(operation == SQLITE_INSERT) {
		NSLog(@"INSERT INTO %s.%s (rowid) VALUES (%qi)", databaseName, tableName, rowID);
	} else if(operation == SQLITE_UPDATE) {
		NSLog(@"UPDATE %s.%s SET rowid=%qi", databaseName, tableName, rowID);
	}
}

@end
