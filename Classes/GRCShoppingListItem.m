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

#import "GRCShoppingListItem.h"
#import "GRCShoppingListItem+Private.h"

#import "GRCShoppingList+Private.h"

#import "GRCGroceryStore.h"
#import "GRCGrocery.h"

#import "GRCDetector.h"
#import "GRCInflector.h"
#import "GRCUnitFormatter.h"

#import "GRCReminderMetadata.h"

#import "NSLocale+Additions.h"
#import "NSString+Additions.h"

@implementation GRCShoppingListItem

NSUInteger const GRCShoppingListItemInvalidDatabaseIdentifier = NSNotFound;

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		self.shoppingListItemDatabaseIdentifier = GRCShoppingListItemInvalidDatabaseIdentifier;
		self.shoppingListItemIdentifier = [NSString stringWithUUID];
	}

	return self;
}

- (id)initWithCoder:(NSCoder*)coder store:(GRCShoppingListStore*)store; {
	if((self = [self init])) {
		self.shoppingListItemIdentifier = [coder decodeObjectForKey:@"persistent_id"];
		self.shoppingListItemDatabaseIdentifier = [coder decodeIntegerForKey:@"id"];

		self.title = [coder decodeObjectForKey:@"name"];
		self.notes = [coder decodeObjectForKey:@"note"];

		self.completed = [coder decodeBoolForKey:@"checked"];

		// aisle
		if([coder containsValueForKey:@"aisle_id"]) {
			NSUInteger aisleDatabaseIdentifier = [coder decodeIntegerForKey:@"aisle_id"];
			self.aisle = [store aisleForDatabaseIdentifier:aisleDatabaseIdentifier];
		}

		// quantity and unit
		if([coder containsValueForKey:@"quantity"]) {
			self.quantity = @([coder decodeDoubleForKey:@"quantity"]);
		}
		
		if([coder containsValueForKey:@"unit_id"]) {
			NSUInteger unitDatabaseIdentifier = [coder decodeIntegerForKey:@"unit_id"];
			self.unit = [store unitForDatabaseIdentifier:unitDatabaseIdentifier];
		}
		
		if(!self.unit) {
			self.unit = [store defaultUnit];
		}

		// grocery
		if([coder containsValueForKey:@"grocery_id"]) {
			NSUInteger groceryDatabaseIdentifier = [coder decodeIntegerForKey:@"grocery_id"];
			self.grocery = [[store groceryStore] groceryForDatabaseIdentifier:groceryDatabaseIdentifier];
		}
	}
	
	return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(![object isKindOfClass:[self class]]) { return NO; }
	return [[self shoppingListItemIdentifier] isEqual:[object shoppingListItemIdentifier]];
}

- (NSUInteger)hash {
	return [[self shoppingListItemIdentifier] hash];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {id = %@, title = %@}",
		[super description],
		[self shoppingListItemIdentifier],
		[self title]];
}

#pragma mark - Private

- (NSString*)localizedTitleSuitableForReminders {
	if(!self.quantity) { return self.title; }

	GRCUnitFormatter* unitFormatter = [[GRCUnitFormatter alloc] initWithUnitStyle:GRCUnitFormatterStyleQuantity];
	unitFormatter.quantity = self.quantity;

	NSString* quantityString = [unitFormatter stringForUnit:[self unit]];

	NSString* localizedString = [NSString stringWithFormat:@"%@ %@",
		quantityString,
		[self title]];

	return localizedString;
}

@end
