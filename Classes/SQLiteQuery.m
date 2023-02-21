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

#import "SQLiteQuery.h"
#import "SQLiteQuery+Private.h"

#import "SQLiteQueryEnumerator.h"

#import "SQLiteStore.h"
#import "SQLiteStore+Private.h"

#import "NSError+SQLite.h"

@implementation SQLiteQuery

#pragma mark - Construction & Destruction

+ (SQLiteQuery*)queryWithFormat:(NSString*)format arguments:(NSArray*)arguments store:(SQLiteStore*)store error:(NSError* __autoreleasing *)error {
	// Retrieve the SQLite database handle
	sqlite3* database = store.handle;
	
	// Compile the SQL statement in byte code
	sqlite3_stmt* statement = NULL;

	const char* formatBuffer = [format cStringUsingEncoding:NSUTF8StringEncoding];
	NSUInteger formatButterSize = [format lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	
	if(sqlite3_prepare_v2(database, formatBuffer, (int)formatButterSize, &statement, NULL) != SQLITE_OK) {
		if(error) {
			*error = [NSError SQLiteErrorForDatabase:database];
		} else {
			NSLog(@"Could not prepare query: %@", [NSError SQLiteErrorForDatabase:database]);
		}

		return nil;
	}
	
	// Make a new query...
	SQLiteQuery* query = [[self alloc] init];
	
	query.statement = statement;
	query.statementString = format;
	
	// ... and substitute the supplied arguments by index if needed
	NSInteger index = 1; // SQLite wants the index to start at one not zero

	for(id argument in arguments) {
		[query substituteObject:argument toIndex:index++];
	}
	
	return query;
}

- (void)dealloc {
	sqlite3_finalize(_statement);
}

#pragma mark - SQLiteQuery

- (void)setSubstitutionVariables:(NSDictionary*)substitutionVariables {
	if(!_substitutionVariables || ![_substitutionVariables isEqualToDictionary:substitutionVariables]) {
		_substitutionVariables = substitutionVariables;
		[self substitute:substitutionVariables];
	}
}

- (NSEnumerator*)recordEnumeratorWithUnarchiveBlock:(id (^)(NSCoder*))unarchiveBlock {
//	Make enumerator for query...
//	NSLog(@"%@", self.statementString);
	
	// Make a new query enumerator
	NSDictionary* substitutionVariables = [self substitutionVariables];

	SQLiteQueryEnumerator* recordEnumerator = [[SQLiteQueryEnumerator alloc]
		initWithQuery:self
		substitutionVariables:substitutionVariables];
		
	if(unarchiveBlock) {
		[recordEnumerator setUnarchiveBlock:unarchiveBlock];
	}
		
	return recordEnumerator;
}

- (NSEnumerator*)recordEnumerator {
	return [self recordEnumeratorWithUnarchiveBlock:nil];
}

#pragma mark - Private

- (BOOL)substitute:(NSDictionary*)substitutionVariables {
	// Now reset our database cursors
	[self resetCursors];
	
	// Reset previous substitution variables
	sqlite3_clear_bindings(_statement);
	
	// Set the substitution variables in our statement
	for(NSString* key in substitutionVariables.allKeys) {
		id object = [substitutionVariables objectForKey:key];
		
		if(![self substituteObject:object forKey:key]) {
			NSLog(@"Could not substitute variable for key %@", key);
		}
	}
	
	return YES;
}

- (BOOL)substituteObject:(id)object toIndex:(NSInteger)index {
	// The value is null
	if(!object || [object isEqual:[NSNull null]]) {
		return sqlite3_bind_null(_statement, (int)index) == SQLITE_OK;
	}
	
	// It's a date, so bind it as a double value
	if([object isKindOfClass:[NSDate class]]) {
		return sqlite3_bind_double(_statement, (int)index, [object timeIntervalSince1970]) == SQLITE_OK;
	}
	
	// The value is a number. Use a double for substitution
	if([object isKindOfClass:[NSNumber class]]) {
		const char* objCType = [object objCType];
		
		// check if this is floating point value
		if(strcmp(objCType, @encode(float)) == 0 || strcmp(objCType, @encode(double)) == 0) {
			return sqlite3_bind_double(_statement, (int)index, [object doubleValue]) == SQLITE_OK;
		}
		
		// Bind as a 64 bit integer. We always use int64 since SQLite does that internally anyways
		return sqlite3_bind_int64(_statement, (int)index, [object longLongValue]) == SQLITE_OK;
	}
	
	// We have binary data
	if([object isKindOfClass:[NSData class]]) {
		NSData* data = (NSData*)object;
		return sqlite3_bind_blob(_statement, (int)index, [data bytes], (int)[data length], SQLITE_STATIC) == SQLITE_OK;
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
	NSInteger index = sqlite3_bind_parameter_index(_statement, [substitutionKey UTF8String]);
	
	// substitute our object
	return [self substituteObject:object toIndex:index];
}

- (void)resetCursors {
	sqlite3_reset(_statement);
}

@end
