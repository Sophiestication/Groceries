//
//  GRCReminderMetadataMigration.h
//  Groceries
//
//  Created by Sophia Teutschler on 01.01.13.
//  Copyright (c) 2013 Sophia Teutschler. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GRCShoppingListStore;

@interface GRCReminderMetadataMigration : NSObject

- (id)initWithShoppingListStore:(GRCShoppingListStore*)store;
- (BOOL)migrateFromReminders:(NSArray*)reminders error:(NSError**)error;

@end