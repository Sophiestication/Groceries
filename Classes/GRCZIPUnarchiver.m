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

#import "GRCZIPUnarchiver.h"

#import "GRCArchiver.h"

#import "NSString+Additions.h"
#import <zipzap/zipzap.h>

@interface GRCZIPUnarchiver()

@property(nonatomic, copy) NSURL* archiveURL;

@property(nonatomic, strong, readwrite) NSDictionary* payload;
@property(nonatomic, strong, readwrite) NSArray* shoppingLists;
@property(nonatomic, strong, readwrite) NSArray* aisles;
@property(nonatomic, strong, readwrite) NSArray* units;

@end

@implementation GRCZIPUnarchiver

#pragma mark - Construction & Destruction

- (id)initWithContentsOfURL:(NSURL*)archiveURL {
	if((self = [super init])) {
		self.archiveURL = archiveURL;
	}

	return self;
}

#pragma mark - GRCZIPUnarchiver

+ (BOOL)canUnarchiveURL:(NSURL*)URL {
	if(![URL isFileURL] && ![URL isFileReferenceURL]) { return NO; }
	
	NSString* extension = [URL pathExtension];
	if(!SUIEqualCaseInsensitiveStrings(extension, GRCShoppingListDocumentExtension)) { return NO; }
	
	return YES;
}

- (BOOL)unarchiveWithOptions:(NSDictionary*)options error:(NSError* __autoreleasing *)error {
	ZZArchive* archive = [ZZArchive archiveWithContentsOfURL:[self archiveURL]];
	if(!archive) { return NO; }

	for(ZZArchiveEntry* entry in archive.entries) {
		if(![self unarchiveEntry:entry error:error]) { return NO; }
	}

	return YES;
}

#pragma mark - Private

- (BOOL)unarchiveEntry:(ZZArchiveEntry*)entry error:(NSError* __autoreleasing *)error {
	NSString* fileName = entry.fileName;

	if(SUIEqualCaseInsensitiveStrings(fileName, @"payload")) { return [self unarchivePayloadFromEntry:entry error:error]; }
	if(SUIEqualCaseInsensitiveStrings(fileName, @"aisles")) { return [self unarchiveAislesFromEntry:entry error:error]; }
	if(SUIEqualCaseInsensitiveStrings(fileName, @"units")) { return [self unarchiveUnitsFromEntry:entry error:error]; }
	if(SUIEqualCaseInsensitiveStrings(fileName, @"lists")) { return [self unarchiveShoppingListsFromEntry:entry error:error]; }

	return YES;
}

- (BOOL)unarchivePayloadFromEntry:(ZZArchiveEntry*)entry error:(NSError* __autoreleasing *)error {
	NSDictionary* payload = [self unarchiveJSONObjectFromEntry:entry options:0 error:error];
	if(!payload) { return NO; }

	self.payload = payload;

	return YES;
}

- (BOOL)unarchiveAislesFromEntry:(ZZArchiveEntry*)entry error:(NSError* __autoreleasing *)error {
	NSArray* aisles = [self unarchiveJSONObjectFromEntry:entry options:NSJSONReadingMutableContainers error:error];
	if(!aisles) { return NO; }

	[aisles enumerateObjectsUsingBlock:^(NSMutableDictionary* aisle, NSUInteger aisleIndex, BOOL* stop) {
		if(!aisle[@"identifier"]) { aisle[@"identifier"] = [NSString stringWithUUID]; };
	}];

	self.aisles = aisles;

	return YES;
}

- (BOOL)unarchiveUnitsFromEntry:(ZZArchiveEntry*)entry error:(NSError* __autoreleasing *)error {
	NSArray* units = [self unarchiveJSONObjectFromEntry:entry options:0 error:error];
	if(!units) { return NO; }

	self.units = units;

	return YES;
}

- (BOOL)unarchiveShoppingListsFromEntry:(ZZArchiveEntry*)entry error:(NSError* __autoreleasing *)error {
	NSArray* shoppingLists = [self unarchiveJSONObjectFromEntry:entry options:NSJSONReadingMutableContainers error:error];
	if(!shoppingLists) { return NO; }

	[shoppingLists enumerateObjectsUsingBlock:^(NSDictionary* shoppingList, NSUInteger shoppingListIndex, BOOL* stop) {
		[[shoppingList objectForKey:@"items"] enumerateObjectsUsingBlock:^(NSMutableDictionary* item, NSUInteger itemIndex, BOOL* stop) {
			[self unarchiveDateValue:item forKey:@"modification-date"];
			[self unarchiveDateValue:item forKey:@"completed-modification-date"];
			[self unarchiveDateValue:item forKey:@"aisle-modification-date"];
			[self unarchiveDateValue:item forKey:@"quantity-modification-date"];
		}];
	}];

	self.shoppingLists = shoppingLists;

	return YES;
}

- (id)unarchiveJSONObjectFromEntry:(ZZArchiveEntry*)entry options:(NSJSONReadingOptions)options error:(NSError* __autoreleasing *)error {
	NSData* data = [entry data];

	options |= NSJSONReadingAllowFragments;

	id object = [NSJSONSerialization JSONObjectWithData:data options:options error:error];
	if(*error) { return nil; }

	return object;
}

- (void)unarchiveDateValue:(NSMutableDictionary*)dictionary forKey:(NSString*)key {
	id value = [dictionary objectForKey:key];
	if(!value) { return; }

	NSDate* date = [self dateForJSONValue:value];
	[dictionary setValue:date forKey:key];
}

- (NSDate*)dateForJSONValue:(id)JSONValue {
	if([JSONValue respondsToSelector:@selector(doubleValue)]) {
		NSTimeInterval timeInterval = [JSONValue doubleValue];
		return [NSDate dateWithTimeIntervalSince1970:timeInterval];
	}
	
	return nil;
}

@end
