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

#import "GRCShoppingListFormatter.h"

#import "GRCShoppingList+Private.h"
#import "GRCShoppingListItem+Private.h"

@implementation GRCShoppingListFormatter

#pragma mark - GRCShoppingListFormatter

- (NSString*)stringForShoppingList:(GRCShoppingList*)shoppingList sections:(NSArray*)sections {
	if(sections.count == 0) { return nil; }

	NSMutableString* string = [NSMutableString string];
	
	for(NSDictionary* section in sections) {
		NSString* title = section[@"title"];
		if(title.length > 0) { [string appendFormat:@"%@:\n", title]; } // TODO: Localize
		
		NSArray* items = section[@"items"];
		NSString* itemsString = [self stringForItems:items];
		[string appendString:itemsString];
		
		[string appendString:@"\n"];
	}
	
	return string;
}

#pragma mark - Private

- (NSString*)stringForItems:(NSArray*)items {
	NSMutableString* string = [NSMutableString string];
	
	for(GRCShoppingListItem* item in items) {
		[string appendFormat:@"- %@\n", [item localizedTitleSuitableForReminders]];
		
		if(item.notes.length > 0) {
			[string appendFormat:@"%@\n", [item notes]];
		}
	}
	
	return string;
}

@end
