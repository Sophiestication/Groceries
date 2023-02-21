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

#import "GRCShoppingListActivityItemProvider.h"

#import "GRCArchiver.h"
#import "GRCShoppingList.h"

@interface GRCShoppingListActivityItemProvider()

@property(nonatomic, copy) NSString* shoppingListTitle;
@property(nonatomic, copy, readwrite) NSString* shoppingListIdentifier;

@end

@implementation GRCShoppingListActivityItemProvider

#pragma mark - Construction & Destruction

- (id)initWithShoppingList:(GRCShoppingList*)shoppingList {
	NSURL* placeholderURL = [NSURL URLWithString:@"file://placeholder.groceries"];

	if((self = [super initWithPlaceholderItem:placeholderURL])) {
		self.shoppingListIdentifier = shoppingList.shoppingListIdentifier;
		self.shoppingListTitle = shoppingList.title;
	}

	return self;
}

#pragma mark - UIActivityItemProvider

- (id)item {
	NSSet* identifiers = [NSSet setWithObject:[self shoppingListIdentifier]];
	NSString* archiveTitle = self.shoppingListTitle;

	GRCArchiver* archiver = [[GRCArchiver alloc]
		initWithArchiveTitle:archiveTitle
		shoppingListIdentifiers:identifiers];

	NSError* error;
	NSURL* archiveURL = [archiver archiveWithOptions:nil error:&error];

	if(error) {
		// TODO: 
	}

	return archiveURL;
}

- (NSString*)activityViewController:(UIActivityViewController*)activityViewController subjectForActivityType:(NSString*)activityType {
	return self.shoppingListTitle;
}

#pragma mark - Private

@end
