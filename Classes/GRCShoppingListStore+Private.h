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

#import "GRCShoppingListStore.h"

#import "GRCDetector.h"
#import "GRCInflector.h"

#import "SQLite.h"

#import "GRCGroceryStore.h"
#import "GRCAisleStore.h"
#import "GRCUnitStore.h"

NSString* const GRCShoppingListStoreDidReceiveExternalChangeNotification;

@interface GRCShoppingListStore()

@property(nonatomic, strong) SQLiteStore* sqliteStore;
@property(nonatomic, strong) GRCGroceryStore* groceryStore;
@property(nonatomic, strong) GRCAisleStore* aisleStore;
@property(nonatomic, strong) GRCUnitStore* unitStore;

@property(nonatomic, strong) NSMapTable* consumers;
@property(nonatomic) BOOL needsUpdate;
@property(nonatomic, strong) NSMapTable* livingShoppingLists;

@property(nonatomic, strong) NSCache* cache;

@property(nonatomic, strong) NSLocale* locale;
- (NSLocale*)newLocaleWithPreferredLanguageCode;

- (void)enumerateLivingShoppingListItems:(void (^)(GRCShoppingListItem* item))block;

@end
