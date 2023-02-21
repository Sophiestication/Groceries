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

#import "SQLiteStatement.h"
#import "SQLiteStatement+Private.h"

#import "SQLiteStore.h"
#import "SQLiteStore+Private.h"

#import "NSError+SQLite.h"

@implementation SQLiteStatement

#pragma mark - Construction & Destruction

+ (SQLiteStatement*)statementWithFormat:(NSString*)format arguments:(NSArray*)arguments store:(SQLiteStore*)store error:(NSError* __autoreleasing *)error {
	// Retrieve the SQLite database handle
	sqlite3* database = store.handle;
	
	// Compile the SQL statement in byte code
	sqlite3_stmt* statementHandle = NULL;
	
	if(sqlite3_prepare_v2(database, [format UTF8String], -1, &statementHandle, NULL) != SQLITE_OK) {
		NSError* SQLiteError = [NSError SQLiteErrorForDatabase:database];
		
		if(error) {
			*error = SQLiteError;
		}
		
		NSLog(@"%@", SQLiteError);

		return nil;
	}
	
	// Make a new query...
	SQLiteStatement* statement = [[self alloc] init];
	
	statement.statement = statementHandle;
	statement.statementString = format;
	
	// ... and substitute the supplied arguments by index if needed
	NSInteger index = 1; // SQLite wants the index to start at one not zero

	for(id argument in arguments) {
		[statement substituteObject:argument toIndex:index++];
	}
	
	return statement;
}

- (void)dealloc {
	sqlite3_finalize(_statement);
	self.statementString = nil;
}

#pragma mark - SQLiteStatement

- (BOOL)substitute:(NSDictionary*)substitutionVariables {
	// Now reset our database cursors
	[self reset];
	
	// Reset previous substitution variables
	sqlite3_clear_bindings(self.statement);
	
	// Set the substitution variables in our statement
	for(NSString* key in substitutionVariables.allKeys) {
		id object = [substitutionVariables objectForKey:key];
		
		if(![self substituteObject:object forKey:key]) {
			NSLog(@"Could not substitute variable for key %@", key);
		}
	}
	
	return YES;
}

- (BOOL)substituteObjectToAll:(id)object {
	// Now reset our database cursors
	[self reset];
	
	// Reset previous substitution variables
	sqlite3_clear_bindings(self.statement);
	
	// Retrieve the number of parameters
	NSUInteger count = sqlite3_bind_parameter_count(self.statement);
	NSUInteger variableIndex = 1;
	
	// Substitute all to null
	for(; variableIndex < count; ++variableIndex) {
		if(![self substituteObject:object toIndex:variableIndex]) {
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)substituteInteger:(NSUInteger)integer toIndex:(NSInteger)index {
	return sqlite3_bind_int64(self.statement, (int)index, integer) == SQLITE_OK;
}

- (BOOL)substituteDouble:(double)value toIndex:(NSInteger)index {
	return sqlite3_bind_double(self.statement, (int)index, value) == SQLITE_OK;
}

- (BOOL)substituteObject:(id)object toIndex:(NSInteger)index {
	// The value is null
	if(!object || [object isEqual:[NSNull null]]) {
		return sqlite3_bind_null(self.statement, (int)index) == SQLITE_OK;
	}
	
	// It's a date, so bind it as a integer value
	if([object isKindOfClass:[NSDate class]]) {
		return sqlite3_bind_double(_statement, (int)index, [object timeIntervalSince1970]) == SQLITE_OK;
	}
	
	// The value is a number. Use a double for substitution
	if([object isKindOfClass:[NSNumber class]]) {
		const char* objCType = [object objCType];
		
		// check if this is floating point value
		if(strcmp(objCType, "f") == 0 || strcmp(objCType, "d") == 0) {
			return sqlite3_bind_double(self.statement, (int)index, [object doubleValue]) == SQLITE_OK;
		}
		
		// Bind as a 64 bit integer. We always use int64 since SQLite does that internally anyways
		return sqlite3_bind_int64(self.statement, (int)index, [object longLongValue]) == SQLITE_OK;
	}
	
	// We have binary data
	if([object isKindOfClass:[NSData class]]) {
		NSData* data = (NSData*)object;
		return sqlite3_bind_blob(self.statement, (int)index, [data bytes], (int)[data length], SQLITE_TRANSIENT) == SQLITE_OK;
	}
	
	// Value is a string
	if([object isKindOfClass:[NSString class]]) {
		NSData* buffer = [(NSString*)object dataUsingEncoding:NSUTF16StringEncoding];
		return sqlite3_bind_text16(self.statement, (int)index, [buffer bytes], (int)[buffer length], SQLITE_TRANSIENT) == SQLITE_OK;
	}
	
	return NO;
}

- (BOOL)substituteObject:(id)object forKey:(NSString*)key {
	// All substituation variables are prefixed with a colon
	NSString* substitutionKey = [@":" stringByAppendingString:key];
	
	// Retrieve the variable index by key
	NSInteger index = sqlite3_bind_parameter_index(self.statement, [substitutionKey UTF8String]);
	
	// substitute our object
	return [self substituteObject:object toIndex:index];
}

- (NSUInteger)numberOfSubstitutionVariables {
	return sqlite3_bind_parameter_count(self.statement);
}

- (BOOL)execute:(NSError* __autoreleasing *)error {
	// Fetch the next object
	int result = sqlite3_step(self.statement);
	
	// We're done, so reset the statement
	if(result == SQLITE_DONE) {
		[self reset];
	}
	
	// The query got interrupted
	if(result == SQLITE_INTERRUPT) {
		[self reset];
		return NO;
	}
	
	// The connection is busy, so just sleep a bit and then try again.
	if(result == SQLITE_BUSY) {
		[NSThread sleepForTimeInterval:1.0 / 10.0];
		return [self execute:error];
	}
	
	// We have a record
	if(result == SQLITE_ROW) {
	}
	
	// Something got fucked up
	if(result == SQLITE_ERROR || result == SQLITE_MISUSE) {
		sqlite3* database = sqlite3_db_handle(self.statement);
		NSError* SQLiteError = [NSError SQLiteErrorForDatabase:database];
	
		if(error) {
			*error = SQLiteError;
		}
		
		NSLog(@"%@", SQLiteError);
	
		return NO;
    }
	
	return YES;
}

- (BOOL)executeAndReturnLastRowIdentifier:(NSUInteger*)identifier error:(NSError* __autoreleasing *)error {
	if(identifier) { *identifier = NSNotFound; }
	if(![self execute:error]) { return NO; }

	sqlite3_int64 rowID = sqlite3_last_insert_rowid(sqlite3_db_handle(_statement));
	if(identifier) { *identifier = rowID; }

	return YES;
}

#pragma mark - Private

- (void)reset {
	sqlite3_reset(_statement);
}

@end
