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

@class SQLiteStore;

@interface SQLiteStatement : NSObject

+ (SQLiteStatement*)statementWithFormat:(NSString*)format arguments:(NSArray*)arguments store:(SQLiteStore*)store error:(NSError* __autoreleasing *)error;

- (BOOL)substitute:(NSDictionary*)substitutionVariables;

- (BOOL)substituteObjectToAll:(id)object;

- (BOOL)substituteInteger:(NSUInteger)integer toIndex:(NSInteger)index;
- (BOOL)substituteDouble:(double)value toIndex:(NSInteger)index;
- (BOOL)substituteObject:(id)object toIndex:(NSInteger)index;

- (BOOL)substituteObject:(id)object forKey:(NSString*)key;

- (NSUInteger)numberOfSubstitutionVariables;

- (BOOL)execute:(NSError* __autoreleasing *)error;
- (BOOL)executeAndReturnLastRowIdentifier:(NSUInteger*)identifier error:(NSError* __autoreleasing *)error;

@end
