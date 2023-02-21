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

#import <Foundation/Foundation.h>
#import	<sqlite3.h>

@interface SQLiteStore : NSObject

- (id)initWithContentsOfURL:(NSURL*)URL error:(NSError* __autoreleasing *)error;
- (id)initWithContentsOfURL:(NSURL*)URL options:(int)options error:(NSError* __autoreleasing *)error;

- (void)beginTransaction;
- (void)commitTransaction;
- (void)cancelTransaction;

- (id)pragmaValueForKey:(NSString*)pragmaKey;
- (void)setPragmaValue:(id)pragmaValue forKey:(NSString*)pragmaKey;

- (BOOL)executeSQL:(NSString*)SQL error:(NSError* __autoreleasing *)error;

- (void)interrupt;
- (void)close; // use with caution

- (BOOL)attachContentsOfURL:(NSURL*)URL alias:(NSString*)alias error:(NSError* __autoreleasing *)error;
- (BOOL)detachDatabaseWithAliasIfNeeded:(NSString*)alias error:(NSError* __autoreleasing *)error;

@end
