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

#import "GRCImportController.h"

#import "GRCShoppingListStore+Private.h"

NSString* const GRCImportControllerWillStartImportingNotification = @"GRCImportControllerWillStartImporting";
NSString* const GRCImportControllerDidFinishImportingNotification = @"GRCImportControllerDidFinishImporting";

@interface GRCImportController()

@property(nonatomic, readwrite) NSInteger numberOfImporters;
@property(nonatomic, strong) NSOperationQueue* operationQueue;

@end

@implementation GRCImportController

@dynamic importing;

#pragma mark Construction & Destruction

+ (instancetype)sharedImportController {
	static dispatch_once_t once;
    static GRCImportController* sharedImportController;
	
    dispatch_once(&once, ^{
		sharedImportController = [[self alloc] init];
	});

    return sharedImportController;
}

- (id)init {
	if((self = [super init])) {
		NSOperationQueue* operationQueue = [[NSOperationQueue alloc] init];
		
		[operationQueue setMaxConcurrentOperationCount:1];
		[operationQueue setName:@"com.sophiestication.groceries.importer"];

		self.operationQueue = operationQueue;
	}

	return self;
}

#pragma mark GRCImportController

- (BOOL)isImporting {
	return self.numberOfImporters > 0;
}

- (void)addImporter:(GRCImporter*)importer {
	NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^() {
		NSError* error;

		// [NSThread sleepForTimeInterval:5.0];

		if(![importer importAndReturnError:&error]) {
			// TODO
		}
	}];

	[operation setCompletionBlock:^() {
		[self operationDidFinishWithImporter:importer];
	}];

	self.numberOfImporters++;

	NSDictionary* userInfo = @{
		@"importer": importer };
	[[NSNotificationCenter defaultCenter]
		postNotificationName:GRCImportControllerWillStartImportingNotification
		object:self
		userInfo:userInfo];

	[[self operationQueue] addOperation:operation];
}

#pragma mark - Private

- (void)operationDidFinishWithImporter:(GRCImporter*)importer {
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[[NSNotificationCenter defaultCenter]
			postNotificationName:GRCShoppingListStoreDidReceiveExternalChangeNotification
			object:nil
			userInfo:nil];

		--self.numberOfImporters;

		NSDictionary* userInfo = @{
			@"importer": importer };
		[[NSNotificationCenter defaultCenter]
			postNotificationName:GRCImportControllerDidFinishImportingNotification
			object:self
			userInfo:userInfo];
	});
}

@end
