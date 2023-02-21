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
#import "SQLiteStore.h"

@class GRCGrocery;

@interface GRCGroceryStore : NSObject

- (id)initWithSQLiteStore:(SQLiteStore*)SQLiteStore;

- (GRCGrocery*)groceryForDatabaseIdentifier:(NSUInteger)groceryDatabaseIdentifier;
- (GRCGrocery*)groceryForTitle:(NSString*)title locale:(NSLocale*)locale;

- (GRCGrocery*)matchingGroceryForString:(NSString*)string locale:(NSLocale*)locale;

- (NSEnumerator*)allGroceriesForLocale:(NSLocale*)locale error:(NSError* __autoreleasing *)error;

- (BOOL)saveGrocery:(GRCGrocery*)grocery locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error;
- (BOOL)deleteGrocery:(GRCGrocery*)grocery locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error;

@end

@interface GRCGroceryStore(Locale)

+ (NSUInteger)languageDatabaseIdentifierForLocale:(NSLocale*)locale;

@end

NSString* const GRCGroceryStoreAutocompletionScopeGenerics;
NSString* const GRCGroceryStoreAutocompletionScopeBrands;

@interface GRCGroceryStore(Autocompletion)

- (NSEnumerator*)autocompleteWithStrings:(NSSet*)strings scope:(NSString*)scope locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error;

@end

@interface GRCGroceryStore(RecentItems)

- (NSArray*)recentlyUsedGroceryItems:(NSUInteger)limit locale:(NSLocale*)locale error:(NSError* __autoreleasing *)error;
- (BOOL)markGroceryAsRecentlyUsed:(GRCGrocery*)grocery error:(NSError* __autoreleasing *)error;

@end
