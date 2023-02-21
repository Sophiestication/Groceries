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

#import "Groceries.h"

#import "GRCShoppingListStore.h"

#import "NSArray+Additions.h"
#import "NSLocale+Additions.h"

#import "GRCLaunchViewController.h"
#import "GRCShoppingListViewController.h"
#import "GRCShoppingListPickerViewController.h"

#import "GRCImportController.h"


#import <AVFoundation/AVFoundation.h>

NSString* const GRCSelectedShoppingListUserDefaultsKey = @"GRCSelectedShoppingList";

@interface Groceries()<UINavigationControllerDelegate, GRCShoppingListPickerViewDelegate>

@property(nonatomic, strong) GRCShoppingListStore* shoppingListStore;
@property(nonatomic, strong) NSSet* shoppingLists;

@property(nonatomic, strong) GRCShoppingListPickerViewController* shoppingListPickerViewController;
@property(nonatomic, strong) GRCShoppingListViewController* shoppingListViewController;

@end

@implementation Groceries

#pragma mark - Construction & Destruction

+ (instancetype)self {
	return (id)[[UIApplication sharedApplication] delegate];
}

+ (void)initialize {
	NSString* pathToUserDefaultsValues = [[NSBundle mainBundle]
		pathForResource:@"user-defaults" 
		ofType:@"plist"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:
		[NSDictionary dictionaryWithContentsOfFile:pathToUserDefaultsValues]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];   
}

#pragma mark - Groceries

- (void)presentShoppingList:(GRCShoppingList*)shoppingList animated:(BOOL)animated {
	GRCShoppingListViewController* shoppingListViewController = self.shoppingListViewController;

	if(!shoppingListViewController) {
		shoppingListViewController = [GRCShoppingListViewController viewController];
		self.shoppingListViewController = shoppingListViewController;
	}

	shoppingListViewController.shoppingList = shoppingList;

	[[NSUserDefaults standardUserDefaults]
		setValue:[shoppingList shoppingListIdentifier]
		forKey:GRCSelectedShoppingListUserDefaultsKey];

	UINavigationController* navigationController = (UINavigationController*)self.window.rootViewController;

	BOOL needsToPushViewController = ![[navigationController viewControllers]
		containsObject:shoppingListViewController];

	if(needsToPushViewController) {
		[navigationController pushViewController:shoppingListViewController animated:animated];
	}
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
	// User Defaults
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(userDefaultsDidChange:)
		name:NSUserDefaultsDidChangeNotification
		object:nil];

	// Importer
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(importerControllerWillStartImporting:)
		name:GRCImportControllerWillStartImportingNotification
		object:nil];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(importerControllerDidFinishImporting:)
		name:GRCImportControllerDidFinishImportingNotification
		object:nil];

	return YES;
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
	[[AVAudioSession sharedInstance]
		setCategory:AVAudioSessionCategoryAmbient
		error:nil];
	[[AVAudioSession sharedInstance] setActive:YES error:nil];

	[self migrateUserDefaultsIfNeeded];

	// Setup window and root view controller
	CGRect windowRect = [[UIScreen mainScreen] bounds];
	UIWindow* window = [[UIWindow alloc] initWithFrame:windowRect];

	GRCLaunchViewController* launchViewController = [[GRCLaunchViewController alloc] init];

	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:launchViewController];
	navigationController.toolbarHidden = NO;
	navigationController.delegate = self;

	window.rootViewController = navigationController;
	
	self.window = window;
	[window makeKeyAndVisible];

	[self loadShoppingListStoreIfNeeded];

	// open sample file
//	NSURL* sampleURL = [[NSBundle mainBundle] URLForResource:@"Einkäufe" withExtension:@"groceries"];
//	[self application:application openURL:sampleURL sourceApplication:nil annotation:nil];

	return YES;
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
	// TODO:
}

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)URL sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
	if([self importGroceriesFromURLIfNeeded:URL]) { return YES; }
	
	return NO;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController*)navigationController didShowViewController:(UIViewController*)viewController animated:(BOOL)animated {
	if(self.shoppingListPickerViewController) { return; }
	if(viewController != self.shoppingListViewController) { return; }

	GRCShoppingListPickerViewController* shoppingListPickerViewController = [[GRCShoppingListPickerViewController alloc] initWithShoppingListStore:[self shoppingListStore]];
	shoppingListPickerViewController.delegate = self;

	navigationController.viewControllers = @[ shoppingListPickerViewController, viewController ];
}

#pragma mark - GRCShoppingListPickerViewDelegate

- (void)shoppingListPicker:(GRCShoppingListPickerViewController*)picker didFinishPickingShoppingList:(GRCShoppingList*)shoppingList {
	[self presentShoppingList:shoppingList animated:YES];
}

#pragma mark - User Defaults

- (void)userDefaultsDidChange:(NSNotification*)notification {
}

#pragma mark - Shopping List Store

- (void)loadShoppingListStoreIfNeeded {
	if(self.shoppingListStore) { return; }
	
	[GRCShoppingListStore requestStore:^(GRCShoppingListStore* store, NSError* error) {
		self.shoppingListStore = store;

		[store addConsumer:self callback:^(NSSet* shoppingLists, NSArray* changes) {
			GRCShoppingListViewController* viewController = self.shoppingListViewController;

			if(viewController.shoppingList) {
				if(![shoppingLists containsObject:[viewController shoppingList]]) {
					viewController.shoppingList = nil;
				}
			}

			NSString* identifier = [[NSUserDefaults standardUserDefaults]
				stringForKey:GRCSelectedShoppingListUserDefaultsKey];
			GRCShoppingList* shoppingList = [self shoppingListForIdentifier:identifier inSet:shoppingLists];

			BOOL importing = [[GRCImportController sharedImportController] isImporting];

			UINavigationController* navigationController = (UINavigationController*)self.window.rootViewController;
			BOOL launching = [[navigationController topViewController] isKindOfClass:[GRCLaunchViewController class]];

			if(!shoppingList) { shoppingList = [shoppingLists anyObject]; }
			if(!shoppingList && !importing && launching) { shoppingList = [self newShoppingList]; }

			if(shoppingList) {
				shoppingLists = [shoppingLists setByAddingObject:shoppingList];
			}

			self.shoppingLists = shoppingLists;

			if(importing) {
				return; // wait for the import to complete
			}

			// Present the shopping list if needed
			if(launching) {
				[self presentShoppingList:shoppingList animated:YES];
			}
		}];
	}];
}

#pragma mark - Importer

- (void)importerControllerWillStartImporting:(NSNotification*)notification {
	UINavigationController* navigationController = (UINavigationController*)self.window.rootViewController;

	if([[navigationController topViewController] isKindOfClass:[GRCLaunchViewController class]]) {
		return;
	}

	GRCLaunchViewController* launchViewController = [[GRCLaunchViewController alloc] init];
	navigationController.viewControllers = @[ launchViewController ];

	self.shoppingListViewController.shoppingList = nil;
}

- (void)importerControllerDidFinishImporting:(NSNotification*)notification {
	GRCImportController* importerController = [notification object];
	if(importerController.importing) { return; }

	GRCImporter* importer = [[notification userInfo] objectForKey:@"importer"];

	NSString* identifier = [[importer identifiersForImportedShoppingLists] anyObject];
	GRCShoppingList* shoppingList = [self shoppingListForIdentifier:identifier inSet:[self shoppingLists]];

	if(shoppingList) {
		[self presentShoppingList:shoppingList animated:YES];
	} else {
		// Beware: Ugly hack ahead!
		// Set the imported shopping list as the new selection and let the consumer
		// block handle the view controller presentation as soon as the store is ready.
		[[NSUserDefaults standardUserDefaults]
			setValue:identifier
			forKey:GRCSelectedShoppingListUserDefaultsKey];
	}
}

#pragma mark - Private

- (GRCShoppingList*)shoppingListForIdentifier:(NSString*)identifier inSet:(NSSet*)shoppingLists {
	for(GRCShoppingList* shoppingList in shoppingLists) {
		if([[shoppingList shoppingListIdentifier] isEqual:identifier]) {
			return shoppingList;
		}
	}

	return nil;
}

- (GRCShoppingList*)newShoppingList {
	GRCShoppingListStore* shoppingListStore = self.shoppingListStore;

	GRCShoppingList* shoppingList = [shoppingListStore newShoppingList];
	shoppingList.title = [shoppingListStore preferredTitleForNewShoppingList];

	NSError* error;
	if(![shoppingListStore saveShoppingList:shoppingList error:&error]) {
		NSLog(@"Could not save initial shopping list: %@", error);
	}

	return shoppingList;
}

#pragma mark -

- (void)migrateUserDefaultsIfNeeded {
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

	// migrate aisle grouping setting
	NSNumber* aisleGroupingEnabled = [userDefaults objectForKey:@"aisleGroupingEnabled"];

	if(aisleGroupingEnabled) {
		[userDefaults removeObjectForKey:@"aisleGroupingEnabled"];
		[userDefaults setBool:[aisleGroupingEnabled boolValue] forKey:@"GRCShoppingListAisleGroupingEnabled"];
	}

	// preferred language
	NSString* preferredLanguage = [userDefaults objectForKey:@"preferredLanguage"];

	if(preferredLanguage.length > 0) {
		[userDefaults removeObjectForKey:@"preferredLanguage"];
		[userDefaults setObject:preferredLanguage forKey:@"GRCPreferredLanguageCode"];
	}

	[userDefaults synchronize];
}

- (BOOL)importGroceriesFromURLIfNeeded:(NSURL*)URL {
	if(![GRCImporter canImportFromURL:URL]) { return NO; }

	GRCImporter* importer = [[GRCImporter alloc] initWithURL:URL];
	[[GRCImportController sharedImportController] addImporter:importer];

	return YES;
}

@end
