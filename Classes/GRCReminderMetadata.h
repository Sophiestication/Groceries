//
//  GRCReminderMetadata.h
//  Groceries
//
//  Created by Sophia Teutschler on 01.01.13.
//  Copyright (c) 2013 Sophia Teutschler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

#import "GRCAisle.h"

NSDictionary* GRCReminderMetadataForAisle(GRCAisle* aisle);

NSURL* GRCURLForReminderMetadata(NSDictionary* metadata);
NSDictionary* GRCReminderMetadataFromURL(NSURL* URL);

@interface EKReminder(Groceries)

@property(nonatomic, strong, setter=groceries_setAisle:, getter=groceries_aisle) GRCAisle* aisle;

@end