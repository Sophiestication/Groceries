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

#import "GRCDefaultStore.h"

#import "GRCStoreMigration.h"
#import "GRCGroceryStore.h"

#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"

SQLiteStore* GRCNewDefaultStore(void) {
	SQLiteStore* store;
	NSError* error;

	int storeOptions = SQLITE_OPEN_READWRITE|SQLITE_OPEN_SHAREDCACHE;
	
	BOOL needsMigration = NO;

	NSURL* groceryStoreURL = [GRCDefaultStoreUtilities groceryStoreURL];
	store = [[SQLiteStore alloc] initWithContentsOfURL:groceryStoreURL options:storeOptions error:&error];
	
	// cannot open file
	if([[error domain] isEqualToString:SQLiteErrorDomain] && error.code == SQLiteErrorCannotOpenFile) {
		// make the application support directory if needed
		NSURL* applicationSupportURL = [groceryStoreURL URLByDeletingLastPathComponent];
		if(![[NSFileManager defaultManager] createDirectoryAtURL:applicationSupportURL withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Could not create application support directory: %@", error);
		}
		
		NSURL* legacyGroceryStoreURL = [GRCDefaultStoreUtilities legacyGroceryStoreURL2];
		
		if([legacyGroceryStoreURL checkResourceIsReachableAndReturnError:nil]) {
			// migrate the legacy grocery store if needed
			if(![[NSFileManager defaultManager] moveItemAtURL:legacyGroceryStoreURL toURL:groceryStoreURL error:&error]) {
				NSLog(@"Could not move legacy store: %@", error);
				groceryStoreURL = nil;
			}
			
			needsMigration = YES;
		} else {
			// make a working copy of our standard grocery store
			if(![[NSFileManager defaultManager] copyItemAtURL:[GRCDefaultStoreUtilities standardGroceryStoreURL] toURL:groceryStoreURL error:&error]) {
				NSLog(@"Could not copy standard store: %@", error);
				groceryStoreURL = nil;
			}
		}
	}
	
	// try again
	if(!store && groceryStoreURL) {
		store = [[SQLiteStore alloc] initWithContentsOfURL:groceryStoreURL options:storeOptions error:&error];
		
		if(error) {
			NSLog(@"Could not open default store: %@", error);
			return nil;
		}
		
		if(needsMigration) {
			// TODO:
		}
	}
	
	if(!store) { return nil; }
	
	// migrate if needed
	/* NSURL* source = [[NSBundle mainBundle] URLForResource:@"groceries-233" withExtension:@"sqlite"];
	NSURL* destination = [[[GRCDefaultStoreUtilities groceryStoreURL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"migration-233.sqlite"];
	[[NSFileManager defaultManager] moveItemAtURL:source toURL:destination error:nil];
	store = [[SQLiteStore alloc] initWithContentsOfURL:destination options:storeOptions error:&error]; */

//	GRCStoreMigration* migration = [[GRCStoreMigration alloc] initWithSQLiteStore:store];
//
//	if(![migration migrateIfNeeded:&error]) {
//		NSLog(@"Could not migrate default store: %@", error);
//		return nil;
//	}

	return store;
}

@implementation GRCDefaultStoreUtilities

+ (NSURL*)standardGroceryStoreURL {
	return [[NSBundle mainBundle] URLForResource:@"standard-groceries" withExtension:@"sqlite"];
}

+ (NSURL*)groceryStoreURL {
	NSURL* applicationSupportURL = [[[NSFileManager defaultManager]
		URLsForDirectory:NSApplicationSupportDirectory
		inDomains:NSUserDomainMask] firstObject];
		
	NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:bundleIdentifier];
	
	NSURL* groceryStoreURL = [applicationSupportURL URLByAppendingPathComponent:@"groceries.sqlite"];
	return groceryStoreURL;
}

+ (NSURL*)legacyGroceryStoreURL2 {
	NSURL* applicationDocumentsURL = [[[NSFileManager defaultManager]
		URLsForDirectory:NSDocumentDirectory
		inDomains:NSUserDomainMask] firstObject];
	
	NSURL* legacyGroceryStoreURL = [applicationDocumentsURL URLByAppendingPathComponent:@"My Groceries"];
	return legacyGroceryStoreURL;
}

+ (NSURL*)legacyGroceryStoreURL {
	NSURL* applicationSupportURL = [[[NSFileManager defaultManager]
		URLsForDirectory:NSApplicationSupportDirectory
		inDomains:NSUserDomainMask] firstObject];
		
	NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	applicationSupportURL = [applicationSupportURL URLByAppendingPathComponent:bundleIdentifier];
	
	NSURL* legacyGroceryStoreURL = [applicationSupportURL URLByAppendingPathComponent:@"My Groceries"];
	return legacyGroceryStoreURL;
}

@end

NSOperationQueue* GRCDefaultStoreOperationQueue(void) {
	static dispatch_once_t once;
    static NSOperationQueue* operationQueue;
	
    dispatch_once(&once, ^{
		operationQueue = [[NSOperationQueue alloc] init];
		
		[operationQueue setMaxConcurrentOperationCount:1];
		[operationQueue setName:@"com.sophiestication.groceries.store"];
	});

    return operationQueue;
}
