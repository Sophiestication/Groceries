//
//  GRCReminderMetadata.m
//  Groceries
//
//  Created by Sophia Teutschler on 01.01.13.
//  Copyright (c) 2013 Sophia Teutschler. All rights reserved.
//

#import "GRCReminderMetadata.h"

#import "NSString+Additions.h"
#import "NSURL+Groceries.h"

NSDictionary* GRCReminderMetadataForAisle(GRCAisle* aisle) {
	NSMutableDictionary* metadata = [NSMutableDictionary dictionaryWithCapacity:5];

	[metadata setValue:[aisle aisleIdentifier] forKey:@"id"];
	[metadata setValue:[aisle image] forKey:@"image"];

	[metadata setValue:[aisle customTitle] forKey:@"title"];

//	if(aisle.modificationDate) {
//		NSNumber* modificationDate = @([[aisle modificationDate] timeIntervalSince1970]);
//		[metadata setValue:modificationDate forKey:@"timestamp"];
//	}

	if([[metadata allKeys] count] == 0) { return nil; }

	return metadata;
}

NSURL* GRCURLForReminderMetadata(NSDictionary* metadata) {
	if(!metadata || [[metadata allKeys] count] == 0) { return nil; }

	if(![NSJSONSerialization isValidJSONObject:metadata]) { return nil; }
	NSData* JSON = [NSJSONSerialization dataWithJSONObject:metadata options:0 error:nil];
	NSString* JSONString = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];

	NSDictionary* parameters = @{ @"json": JSONString };

	NSString* queryString = AFQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding);
	if(!queryString) { return nil; }

	NSString* URLString = [NSString stringWithFormat:@"%@://metadata?%@", GRCGroceriesURLScheme, queryString];

	NSURL* URL = [NSURL URLWithString:URLString];
	return URL;
}

NSDictionary* GRCReminderMetadataFromURL(NSURL* URL) {
	if(!URL) { return nil; }
	if(![URL isGroceriesURL]) { return nil; }
	if(!SUIEqualCaseInsensitiveStrings([URL host], @"metadata")) { return nil; }

	NSString* queryString = [URL query];
	NSArray* components = [queryString componentsSeparatedByString:@"="];

	NSUInteger JSONComponentIndex = [components indexOfObject:@"json"];
	if(JSONComponentIndex == NSNotFound) { return nil; }

	if(JSONComponentIndex + 1 >= components.count) { return nil; }
	NSString* JSONComponent = components[JSONComponentIndex + 1];

	NSString* JSONString = [JSONComponent stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSData* JSONData = [JSONString dataUsingEncoding:NSUTF8StringEncoding];

	NSError* error;
	NSDictionary* metadata = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingAllowFragments error:&error];

	if(!metadata) {
		NSLog(@"Could not decode reminder metdata: %@", error);
	}

	if([[metadata allKeys] count] == 0) { return nil; }

	return metadata;
}

#pragma mark -

@implementation EKReminder(Groceries)

@dynamic aisle;
void* const GRCAisleAssocitatedObjectKey;

- (GRCAisle*)groceries_aisle {
	return nil;
}

- (void)groceries_setAisle:(GRCAisle*)aisle {
//	objc_setAssociatedObject(self, &GRCAisleAssocitatedObjectKey, languageCode, OBJC_ASSOCIATION_RETAIN);
}

@end