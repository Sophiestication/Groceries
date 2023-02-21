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

#import "SQLiteQueryEnumerator.h"

#import "SQLiteQuery.h"
#import "SQLiteQuery+Private.h"

#import "SQLiteUnarchiver.h"
#import "SQLiteUnarchiver+Private.h"

#import "NSArray+Additions.h"

@implementation SQLiteQueryEnumerator

@synthesize query = _query;
@synthesize substitutionVariables = _substitutionVariables;
@synthesize unarchiveBlock = _unarchiveBlock;

- (id)initWithQuery:(SQLiteQuery*)query substitutionVariables:(NSDictionary*)substitutionVariables {
	if((self = [super init])) {
		self.query = query;
		self.substitutionVariables = substitutionVariables;
		_needsToResetCursors = YES;
	}
	
	return self;
}

- (void)dealloc {
	[_query resetCursors];
}

- (id)nextObject {
	// First check if we need to reset the cursors in case a different enumerator didn't
	if(_needsToResetCursors) {
		[_query resetCursors];
		_needsToResetCursors = NO;
	}

	// Fetch the next object
	int result = sqlite3_step(_query.statement);
	
	// We're done, so reset the statement
	if(result == SQLITE_DONE) {
		[_query resetCursors];
	}
	
	// The query got interrupted
	if(result == SQLITE_INTERRUPT) {
		[_query resetCursors];
		return nil;
	}
	
//	// The connection is busy, so just sleep a bit and then try again.
//	if(result == SQLITE_BUSY) {
//		[NSThread sleepForTimeInterval:1.0 / 10.0];
//		return [self nextObject];
//	}
	
	// We have a record
	if(result == SQLITE_ROW) {
		// Make a new unarchiver if needed
		if(!_unarchiver) {
			_unarchiver = [[SQLiteUnarchiver alloc] initWithEnumerator:self];
		}
		
		if(self.unarchiveBlock) {
			id record = ((id (^)(NSCoder*))[self unarchiveBlock])(_unarchiver);
			return record;
		} else {
			NSArray* availableKeys = _unarchiver.allKeys;
			NSMutableDictionary* record = [NSMutableDictionary dictionaryWithCapacity:[availableKeys count]];
		
			for(NSString* key in availableKeys) {
				[record
					setValue:[_unarchiver decodeObjectForKey:key]
					forKey:key];
			}
				
			return record;
		}
	}
	
	// Something got fucked up
	if(result == SQLITE_ERROR || result == SQLITE_MISUSE) {
		sqlite3* database = sqlite3_db_handle(_query.statement);
		NSString* errorString = [NSString stringWithUTF8String:sqlite3_errmsg(database)];

		[NSException raise:@"SQLite error" format:errorString arguments:NULL];
    }
	
	return nil;
}

@end
