//
//  GRCReminderMetadataMigration.m
//  Groceries
//
//  Created by Sophia Teutschler on 01.01.13.
//  Copyright (c) 2013 Sophia Teutschler. All rights reserved.
//

#import "GRCReminderMetadataMigration.h"

#import "GRCReminderMetadata.h"
#import "GRCShoppingListStore.h"

#import "NSString+Additions.h"

#import <EventKit/EventKit.h>

@interface GRCReminderMetadataMigration()

@property(nonatomic, strong) GRCShoppingListStore* store;

@property(nonatomic, strong) NSMutableDictionary* aisleMetadata;
@property(nonatomic, strong) NSMutableDictionary* unitMetadata;

@end

@implementation GRCReminderMetadataMigration

#pragma mark - Construction & Destruction

- (id)initWithShoppingListStore:(GRCShoppingListStore*)store {
	if((self = [super init])) {
		self.store = store;

		self.aisleMetadata = [NSMutableDictionary dictionary];
		self.unitMetadata = [NSMutableDictionary dictionary];
	}

	return self;
}

#pragma mark - GRCReminderMetadataMigration

- (BOOL)migrateFromReminders:(NSArray*)reminders error:(NSError**)error {
	[self parseMetadataForReminders:reminders];

	[self migrateAisles:[[self aisleMetadata] allValues]];

	return YES;
}

#pragma mark - Private

- (void)parseMetadataForReminders:(NSArray*)reminders {
	for(EKReminder* reminder in reminders) {
		NSDictionary* metadata = GRCReminderMetadataFromURL(reminder.URL);
		if(!metadata) { continue; }

		NSDictionary* aisleMetadata = metadata[@"aisle"];
		[self insertOrReplaceAisleMetadataIfNeeded:aisleMetadata];

		// TODO: Insert and replace units too
	}
}

- (void)insertOrReplaceAisleMetadataIfNeeded:(NSDictionary*)aisleMetadata {
	NSString* identifier = aisleMetadata[@"id"];
	if(identifier.length == 0) { return; }

	NSDictionary* otherAisleMetadata = self.aisleMetadata[identifier];

	if(otherAisleMetadata) {
		NSDate* modifiedDate = [self dateForObject:[aisleMetadata objectForKey:@"timestamp"]];
		NSDate* otherModifiedDate = [self dateForObject:[otherAisleMetadata objectForKey:@"timestamp"]];

		if(!modifiedDate && otherModifiedDate) {
			aisleMetadata = nil;
		}

		if(modifiedDate && otherModifiedDate && [modifiedDate compare:otherModifiedDate] < NSOrderedDescending) {
			aisleMetadata = nil;
		}
	}

	if(aisleMetadata) {
		[[self aisleMetadata] setObject:aisleMetadata forKey:identifier];
	}
}

- (NSDate*)dateForObject:(id)object {
	if([object isKindOfClass:[NSDate class]]) {
		return object;
	}

	if([object respondsToSelector:@selector(doubleValue)]) {
		NSTimeInterval timestamp = [object doubleValue];
		return [NSDate dateWithTimeIntervalSince1970:timestamp];
	}

	return nil;
}

#pragma mark - 

- (void)migrateAisles:(NSArray*)aisleMetadataArray {
	NSArray* aisles = self.store.aisles;

	for(NSDictionary* metadata in aisleMetadataArray) {
		GRCAisle* aisle = [self aisleInArray:aisles forMetadata:metadata];

		if(!aisle) {
			// create new
			aisle = [[self store] newAisle];

			NSString* identifier = metadata[@"id"];
			if(identifier.length > 0) { aisle.aisleIdentifier = identifier; }

			NSString* title = metadata[@"title"];
			if(title.length > 0) { aisle.customTitle = title; }

			// NSDate* modificationDate = [self dateForObject:[metadata objectForKey:@"timestamp"]];
			// if(modificationDate) { aisle.modificationDate = modificationDate; }

			[[self store] saveAisle:aisle error:nil]; // TODO:

			NSLog(@"new aisle: %@", aisle);
		} else {
			// udpate
			NSLog(@"update %@", aisle);
		}
	}
}

- (GRCAisle*)aisleInArray:(NSArray*)aisles forMetadata:(NSDictionary*)metadata {
	// find by identifier
	NSString* identifier = metadata[@"id"];

	NSUInteger aisleIndex = [aisles indexOfObjectPassingTest:^BOOL(GRCAisle* aisle, NSUInteger index, BOOL* stop) {
		if(!SUIEqualCaseInsensitiveStrings(aisle.aisleIdentifier, identifier)) { return NO; }
		*stop = YES; return YES;
	}];

	if(aisleIndex != NSNotFound) {
		return aisles[aisleIndex];
	}

	// find by title
	NSString* title = metadata[@"title"];
	if(title.length == 0) { return nil; }

	aisleIndex = [aisles indexOfObjectPassingTest:^BOOL(GRCAisle* aisle, NSUInteger index, BOOL* stop) {
		if(!SUIEqualCaseInsensitiveStrings(aisle.customTitle, title)) { return NO; }
		*stop = YES; return YES;
	}];

	if(aisleIndex != NSNotFound) {
		return aisles[aisleIndex];
	}

	return nil;
}

@end