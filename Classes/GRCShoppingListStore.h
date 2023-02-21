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

@class GRCShoppingList;
@class GRCShoppingListItem;
@class GRCAisle;
@class GRCUnit;

NSString* const GRCShoppingListStoreUnitDidChangeNotification;
NSString* const GRCShoppingListStoreAisleDidChangeNotification;

NSString* const GRCShoppingListStoreLocaleDidChangeNotification;
NSString* const GRCShoppingListStoreLocaleKey;

NSString* const GRCShoppingListDidSaveItemNotification;
NSString* const GRCShoppingListDidDeleteItemNotification;
NSString* const GRCShoppingListItemKey;

typedef NS_ENUM(NSInteger, GRCShoppingListStoreAuthorizationStatus) {
    GRCShoppingListStoreAuthorizationStatusNotDetermined = 0,
    GRCShoppingListStoreAuthorizationStatusRestricted,
    GRCShoppingListStoreAuthorizationStatusDenied,
    GRCShoppingListStoreAuthorizationStatusAuthorized,
};

@interface GRCShoppingListStore : NSObject

+ (void)requestStore:(void (^)(GRCShoppingListStore* shoppingListStore, NSError* error))completion;

@property(nonatomic, readonly) GRCShoppingListStoreAuthorizationStatus authorizationStatus;

@property(nonatomic, readonly, strong) NSLocale* locale;

- (void)addConsumer:(id)consumer callback:(void (^)(NSSet* shoppingLists, NSArray* changes))callback;
- (void)removeConsumer:(id)consumer;

- (void)beginUpdates;
- (void)endUpdatesAndCommit:(BOOL)commit;

@end

@interface GRCShoppingListStore(ShoppingLists)

- (GRCShoppingList*)newShoppingList;
- (BOOL)saveShoppingList:(GRCShoppingList*)list error:(NSError* __autoreleasing *)error;
- (BOOL)deleteShoppingList:(GRCShoppingList*)list error:(NSError* __autoreleasing *)error;

@end

@interface GRCShoppingListStore(ShoppingListItems)

- (BOOL)saveShoppingListItem:(GRCShoppingListItem*)item notify:(BOOL)notify error:(NSError* __autoreleasing *)error;
- (BOOL)saveShoppingListItem:(GRCShoppingListItem*)item notify:(BOOL)notify overwriteGrocery:(BOOL)overwriteGrocery markAsRecentlyUsed:(BOOL)markAsRecentlyUsed error:(NSError* __autoreleasing *)error;

- (BOOL)deleteShoppingListItem:(GRCShoppingListItem*)item notify:(BOOL)notify error:(NSError* __autoreleasing *)error;
- (BOOL)deleteShoppingListItemIncludingGrocery:(GRCShoppingListItem*)item error:(NSError* __autoreleasing *)error;

@end

@interface GRCShoppingListStore(Aisles)

@property(nonatomic, readonly, strong) NSArray* aisles;

- (GRCAisle*)newAisle;

- (BOOL)insertAisle:(GRCAisle*)aisle atIndex:(NSUInteger)aisleIndex error:(NSError* __autoreleasing *)error;
- (BOOL)deleteAisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error;
- (BOOL)saveAisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error;

- (GRCAisle*)aisleForDatabaseIdentifier:(NSInteger)databaseIdentifier;

@end

@interface GRCShoppingListStore(Units)

@property(nonatomic, readonly, strong) NSArray* units;
@property(nonatomic, readonly, strong) GRCUnit* defaultUnit;

- (GRCUnit*)newUnit;

- (BOOL)insertUnit:(GRCUnit*)unit atIndex:(NSUInteger)unitIndex error:(NSError* __autoreleasing *)error;
- (BOOL)deleteUnit:(GRCUnit*)unit error:(NSError* __autoreleasing *)error;
- (BOOL)saveUnit:(GRCUnit*)unit error:(NSError* __autoreleasing *)error;

- (GRCUnit*)unitForDatabaseIdentifier:(NSInteger)databaseIdentifier;

@end

@interface GRCShoppingListStore(Organize)

- (BOOL)moveShoppingListItems:(NSSet*)items intoShoppingList:(GRCShoppingList*)shoppingList aisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error;
- (BOOL)copyShoppingListItems:(NSSet*)items intoShoppingList:(GRCShoppingList*)shoppingList aisle:(GRCAisle*)aisle error:(NSError* __autoreleasing *)error;

@end

@interface GRCShoppingListStore(RecentItems)

@property(nonatomic, readonly, strong) NSArray* recentItems;
- (BOOL)markShoppingListItemAsRecentlyUsed:(GRCShoppingListItem*)shoppingListItem;

@end

@interface GRCShoppingListStore(UIAdditions)

- (NSString*)preferredTitleForNewShoppingList;

@end

@interface GRCShoppingListStore(RemainingItems)

@property(nonatomic, readonly) NSUInteger numberOfRemainingShoppingListItems;
- (void)updateRemainingItemsBadgeIfNeeded;

@end
