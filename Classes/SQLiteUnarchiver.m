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

#import "SQLiteUnarchiver.h"
#import "SQLiteUnarchiver+Private.h"

#import "SQLiteQueryEnumerator.h"

#import "SQLiteQuery.h"
#import "SQLiteQuery+Private.h"

@implementation SQLiteUnarchiver

@synthesize allKeys = _allKeys;
@synthesize enumerator = _enumerator;

#pragma mark - Construction & Destruction

- (id)initWithEnumerator:(SQLiteQueryEnumerator*)enumerator {
	if((self = [super init])) {
		self.enumerator = enumerator; // weak reference
		self.allKeys = [self createAllKeysArray];
	}
	
	return self;
}

- (void)dealloc {
	self.allKeys = nil;
	self.enumerator = nil;
}

#pragma mark - NSCoder

- (BOOL)allowsKeyedCoding {
	return YES;
}

- (BOOL)containsValueForKey:(NSString*)key {
	NSUInteger index = [[self allKeys] indexOfObject:key];
	
	if(index != NSNotFound) {
		return [self containsValueAtIndex:index];
	}
	
	return NO;
}

- (id)decodeObjectForKey:(NSString*)key {
	NSUInteger index = [[self allKeys] indexOfObject:key];
	
	if(index == NSNotFound) {
		return nil;
	}
	
	// Retrieve the column value
	sqlite3_stmt* statement = _enumerator.query.statement;

	int nativeIndex = (int)index;
	NSInteger nativeType = sqlite3_column_type(statement, nativeIndex);
	
	// This column holds no value
	if(nativeType == SQLITE_NULL) {
		return nil; // [NSNull null];
	}
	
	// We have a string. Be safe and always use utf16 encoding
	if(nativeType == SQLITE3_TEXT /* ||
	   nativeType == SQLITE_BLOB*/) {
		const void* buffer = sqlite3_column_text16(statement, nativeIndex);
		NSUInteger bufferSize = sqlite3_column_bytes16(statement, nativeIndex);
	
		return [[NSString alloc] initWithBytes:buffer length:bufferSize encoding:NSUTF16LittleEndianStringEncoding];
	}
	
	// We have a integer value
	if(nativeType == SQLITE_INTEGER) {
		sqlite_int64 integerValue = sqlite3_column_int64(statement, nativeIndex);
		return [NSNumber numberWithLongLong:integerValue];
	}
	
	// We have a double value
	if(nativeType == SQLITE_FLOAT) {
		double doubleValue = sqlite3_column_double(statement, nativeIndex);
		return [NSNumber numberWithDouble:doubleValue];
	}
	
	// We have a raw data value
	if(nativeType == SQLITE_BLOB) {
		const void* buffer = sqlite3_column_blob(statement, nativeIndex);
		int bufferSize = sqlite3_column_bytes(statement, nativeIndex);

		return [NSData dataWithBytes:buffer length:bufferSize];
	}
	
	return nil;
}

- (BOOL)decodeBoolForKey:(NSString*)key {
	return [self decodeIntegerForKey:key] > 0;
}

- (int)decodeIntForKey:(NSString*)key {
	return [self decodeInt32ForKey:key];
}

- (int32_t)decodeInt32ForKey:(NSString*)key {
	NSUInteger index = [[self allKeys] indexOfObject:key];
	
	if(index == NSNotFound) {
		return 0; // TODO:
	}
	
	return sqlite3_column_int(_enumerator.query.statement, (int)index);
}

- (int64_t)decodeInt64ForKey:(NSString*)key {
	NSUInteger index = [[self allKeys] indexOfObject:key];
	
	if(index == NSNotFound) {
		return 0; // TODO:
	}
	
	return sqlite3_column_int64(_enumerator.query.statement, (int)index);
}

- (float)decodeFloatForKey:(NSString*)key {
	return [self decodeDoubleForKey:key];
}

- (double)decodeDoubleForKey:(NSString*)key {
	NSUInteger index = [[self allKeys] indexOfObject:key];
	
	if(index == NSNotFound) {
		return 0.0; // TODO:
	}

	return sqlite3_column_double(_enumerator.query.statement, (int)index);
}

- (NSInteger)decodeIntegerForKey:(NSString*)key {
#if __LP64__ || NS_BUILD_32_LIKE_64
	return [self decodeInt64ForKey:key];
#else
	return [self decodeInt32ForKey:key];
#endif
}

- (const uint8_t*)decodeBytesForKey:(NSString*)key returnedLength:(NSUInteger*)lengthp {
	NSUInteger index = [[self allKeys] indexOfObject:key];
	
	if(index == NSNotFound) {
		return NULL; // TODO:
	}
	
	sqlite3_stmt* statement = _enumerator.query.statement;
	int nativeIndex = (int)index;
	
	const void* buffer = sqlite3_column_blob(statement, nativeIndex);
	int bufferSize = sqlite3_column_bytes(statement, nativeIndex);
	
	*lengthp = bufferSize;
	
	return buffer;
}

#pragma mark - Private

- (NSArray*)createAllKeysArray {
	sqlite3_stmt* statement = _enumerator.query.statement;

	NSInteger numberOfKeys = sqlite3_column_count(statement);
	int keyIndex = 0;
		
	NSMutableArray* allKeys = [NSMutableArray arrayWithCapacity:numberOfKeys];
		
	for(; keyIndex < numberOfKeys; ++keyIndex) {
		const char* key = sqlite3_column_name(statement, keyIndex);
		
		if(key) {
			[allKeys addObject:[NSString stringWithUTF8String:key]];
		} else {
			[allKeys addObject:[NSNull null]];
		}
	}
	
	return allKeys;
}

- (BOOL)containsValueAtIndex:(NSUInteger)index {
	return sqlite3_column_type(_enumerator.query.statement, (int)index) != SQLITE_NULL;
}

@end
