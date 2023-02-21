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

#import "GRCURLUnarchiver.h"

#import "GRCAisle.h"

#import "GRCUnit.h"
#import "GRCUnitStore.h"
#import "GRCUnitFormatter.h"

#import "GRCDefaultStore.h"

#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSURL+Groceries.h"

@interface GRCURLUnarchiver()

@property(nonatomic, copy) NSURL* archiveURL;

@property(nonatomic, strong, readwrite) NSDictionary* payload;
@property(nonatomic, strong, readwrite) NSArray* shoppingLists;
@property(nonatomic, strong, readwrite) NSArray* aisles;
@property(nonatomic, strong, readwrite) NSArray* units;

@property(nonatomic, copy) NSDate* modificationDate;

@property(nonatomic, strong) NSMutableDictionary* aisleByDatabaseIdentifier;
@property(nonatomic, strong) NSMutableSet* appliedAisleIdentifiers;

@property(nonatomic, strong) NSMutableDictionary* unitsByIdentifier;
@property(nonatomic, strong) GRCUnitFormatter* unitFormatter;

@end

@implementation GRCURLUnarchiver

#pragma mark - Construction & Destruction

- (id)initWithContentsOfURL:(NSURL*)archiveURL {
	if((self = [super init])) {
		self.archiveURL = archiveURL;
		self.modificationDate = [NSDate date];
	}

	return self;
}

#pragma mark - GRCShoppingListURLUnarchiver

+ (BOOL)canUnarchiveURL:(NSURL*)URL {
	if(![URL isGroceriesURL]) { return NO; }
	if(!SUIEqualCaseInsensitiveStrings(@"import", [URL host])) { return NO; }
	return YES;
}

- (BOOL)unarchiveWithOptions:(NSDictionary*)options error:(NSError* __autoreleasing *)error {
	NSDictionary* dictionary = [self dictionaryFromURL:[self archiveURL]];

	[self unarchiveAislesForDictionary:dictionary];
	[self unarchiveUnitsForDictionary:dictionary];
	[self unarchiveShoppingListForDictionary:dictionary];

	[self removeObsoleteAisles];

	return YES;
}

#pragma mark - Aisles

- (void)unarchiveAislesForDictionary:(NSDictionary*)dictionary {
	NSArray* aisles = dictionary[@"data"][@"aisles"];

	NSMutableArray* unarchivedAisles = [NSMutableArray arrayWithCapacity:[aisles count]];

	NSArray* standardAisles = [GRCAisle standardAisles];

	for(NSDictionary* aisle in aisles) {
		NSDictionary* unarchivedAisle = [self unarchiveAisle:aisle standardAisles:standardAisles];
		if(unarchivedAisle) { [unarchivedAisles addObject:unarchivedAisle]; }
	}

	self.aisles = unarchivedAisles;
}

- (NSDictionary*)unarchiveAisle:(NSDictionary*)aisle standardAisles:(NSArray*)standardAisles {
	NSMutableDictionary* unarchivedAisle = [NSMutableDictionary dictionary];

	NSString* image = aisle[@"imageName"];
	if(SUIEqualCaseInsensitiveStrings(image, @"cigarettes")) { image = @"generic"; } // application quit smoking

	[unarchivedAisle setValue:image forKey:@"image"];

	NSUInteger databaseIdentifier = [[aisle objectForKey:@"id"] integerValue];
	GRCAisle* standardAisle = [self aisleForDatabaseIdentifier:databaseIdentifier inArray:standardAisles];

	if(standardAisle) {
		[unarchivedAisle setValue:@(databaseIdentifier) forKey:@"database-identifier"];
		[unarchivedAisle setValue:[standardAisle aisleIdentifier] forKey:@"identifier"];
		[unarchivedAisle setValue:@(0) forKey:@"custom"];
	} else {
		[unarchivedAisle setValue:@(databaseIdentifier) forKey:@"database-identifier"];

		NSString* identifier = [NSString stringWithUUID];
		[unarchivedAisle setValue:identifier forKey:@"identifier"];
		
		[unarchivedAisle setValue:@(1) forKey:@"custom"];

		NSString* customTitle = aisle[@"name"];
		[unarchivedAisle setValue:customTitle forKey:@"custom-title"];
	}

	if(!self.aisleByDatabaseIdentifier) {
		self.aisleByDatabaseIdentifier = [NSMutableDictionary dictionary];
	}

	[[self aisleByDatabaseIdentifier] setObject:unarchivedAisle forKey:@(databaseIdentifier)];

	return unarchivedAisle;
}

- (GRCAisle*)aisleForDatabaseIdentifier:(NSUInteger)databaseIdentifier inArray:(NSArray*)aisles {
	if(databaseIdentifier == GRCAisleInvalidDatabaseIdentifier) { return nil; }

	for(GRCAisle* aisle in aisles) {
		if(aisle.aisleDatabaseIdentifier == databaseIdentifier) {
			return aisle;
		}
	}

	return nil;
}

- (void)removeObsoleteAisles {
	NSMutableArray* newAisles = [NSMutableArray arrayWithCapacity:[[self aisles] count]];

	for(NSDictionary* aisle in self.aisles) {
		NSString* identifier = aisle[@"identifier"];
		if(![[self appliedAisleIdentifiers] containsObject:identifier]) { continue; }

		[newAisles addObject:aisle];
	}

	self.aisles = newAisles;
}

#pragma mark - Units

- (void)unarchiveUnitsForDictionary:(NSDictionary*)dictionary {
	NSMutableArray* unarchivedUnits = [NSMutableArray array];
	NSSet* existingUnits = [self existingUnits];

	for(NSDictionary* item in dictionary[@"data"][@"items"]) {
		NSDictionary* unit = item[@"unit"];
		if(!unit) { continue; }
		
		NSDictionary* unarchivedUnit = [self unarchiveUnit:unit existingUnits:existingUnits];
		if(!unarchivedUnit) { continue; }

		[unarchivedUnits addObject:unarchivedUnit];
	}

	self.units = unarchivedUnits;
}

- (NSSet*)existingUnits {
	NSSet* existingUnits;

	@autoreleasepool {
		SQLiteStore* sqliteStore = GRCNewDefaultStore();
		GRCUnitStore* unitStore = [[GRCUnitStore alloc] initWithSQLiteStore:sqliteStore];
	
		existingUnits = [unitStore units];
		[sqliteStore close]; // to prevent database locks in a different thread
	}

	return existingUnits;
}

- (NSDictionary*)unarchiveUnit:(NSDictionary*)unit existingUnits:(NSSet*)existingUnits {
	NSString* unitIdentifier = [self unitIdentifierForUnit:unit];

	if(!unitIdentifier) { return nil; }
	if([[self unitsByIdentifier] objectForKey:unitIdentifier]) { return nil; }
	
	NSDictionary* existingUnarchivedUnit = [self unarchiveFromExistingUnit:unit inSet:existingUnits];
	if(existingUnarchivedUnit) { return existingUnarchivedUnit; }

	NSMutableDictionary* unarchivedUnit = [NSMutableDictionary dictionary];

	NSString* abbreviation = unit[@"displayShortName"];
	if(abbreviation.length != 0) { unarchivedUnit[@"custom-abbreviation"] = abbreviation; }

	NSString* singularTitle = unit[@"displayName"];
	if(singularTitle.length != 0) { unarchivedUnit[@"custom-singular-title"] = singularTitle; }

//	NSString* pluralTitle = unit[@"displayPluralShortName"];
//	if(pluralTitle.length != 0) { unarchivedUnit[@"custom-plural-title"] = pluralTitle; }

	if(YES) { 
		unarchivedUnit[@"identifier"] = [NSString stringWithUUID];
		unarchivedUnit[@"custom"] = @(YES);
	}

	if(!self.unitsByIdentifier) { self.unitsByIdentifier = [NSMutableDictionary dictionary]; }
	[[self unitsByIdentifier] setObject:unarchivedUnit forKey:unitIdentifier];

	return unarchivedUnit;
}

- (NSDictionary*)unarchiveFromExistingUnit:(NSDictionary*)unit inSet:(NSSet*)set {
	GRCUnit* existingUnit = [self bestMatchForUnit:unit inSet:set];
	if(!existingUnit) { return nil; }
	if(!existingUnit.unitIdentifier) { return nil; }
	
	NSDictionary* unarchivedUnit = @{
		@"identifier": existingUnit.unitIdentifier,
		@"custom": @(existingUnit.custom),
		@"modification-date": [self modificationDate] };
	
	return unarchivedUnit;
}

- (GRCUnit*)bestMatchForUnit:(NSDictionary*)unit inSet:(NSSet*)set {
	NSString* abbreviation = unit[@"displayShortName"];
	if(abbreviation.length == 0) { abbreviation = nil; }

	NSString* singularTitle = unit[@"displayName"];
	if(singularTitle.length == 0) { abbreviation = nil; }

	NSString* pluralTitle = unit[@"displayPluralShortName"];
	if(pluralTitle.length == 0) { abbreviation = nil; }

	for(GRCUnit* existingUnit in set) {
		NSString* string = [self stringForUnit:existingUnit formatterStyle:GRCUnitFormatterStyleAbbreviation];
		if(SUIEqualCaseInsensitiveStrings(abbreviation, string)) { return existingUnit; }
		
		string = [self stringForUnit:existingUnit formatterStyle:GRCUnitFormatterStyleSingular];
		if(SUIEqualCaseInsensitiveStrings(singularTitle, string)) { return existingUnit; }
		
		string = [self stringForUnit:existingUnit formatterStyle:GRCUnitFormatterStylePlural];
		if(SUIEqualCaseInsensitiveStrings(pluralTitle, string)) { return existingUnit; }
	}
	
	return nil;
}

- (NSString*)stringForUnit:(GRCUnit*)unit formatterStyle:(GRCUnitFormatterStyle)style {
	if(!self.unitFormatter) {
		self.unitFormatter = [[GRCUnitFormatter alloc] initWithUnitStyle:0];
	}
	
	self.unitFormatter.unitStyle = style;
	return [[self unitFormatter] stringForUnit:unit];
}

- (NSString*)unitIdentifierForUnit:(NSDictionary*)unit {
	if(!unit) { return nil; }

	NSString* abbreviation = unit[@"displayShortName"];
	if(abbreviation.length == 0) { abbreviation = @"null"; }

	NSString* singularTitle = unit[@"displayName"];
	if(singularTitle.length == 0) { abbreviation = @"null"; }

	NSString* pluralTitle = unit[@"displayPluralShortName"];
	if(pluralTitle.length == 0) { abbreviation = @"null"; }

	NSString* identifier = [NSString stringWithFormat:@"%@-%@-%@", abbreviation, singularTitle, pluralTitle];
	return identifier;
}

#pragma mark - Shopping List

- (void)unarchiveShoppingListForDictionary:(NSDictionary*)dictionary {
	NSArray* items = dictionary[@"data"][@"items"];
	NSMutableArray* unarchivedItems = [NSMutableArray arrayWithCapacity:[items count]];

	for(NSDictionary* item in items) {
		NSDictionary* unarchivedItem = [self unarchiveShoppingListItemForDictionary:item];
		if(unarchivedItem) { [unarchivedItems addObject:unarchivedItem]; }
	}

	NSMutableDictionary* shoppingList = [NSMutableDictionary dictionaryWithCapacity:3];

	NSString* title = dictionary[@"data"][@"name"];
	[shoppingList setValue:title forKey:@"title"];

	[shoppingList setObject:[NSString stringWithUUID] forKey:@"identifier"];

	[shoppingList setObject:unarchivedItems forKey:@"items"];

	[shoppingList setObject:[self modificationDate] forKey:@"modification-date"];

	self.shoppingLists = @[ shoppingList ];
}

- (NSDictionary*)unarchiveShoppingListItemForDictionary:(NSDictionary*)item {
	NSMutableDictionary* unarchivedShoppingList = [NSMutableDictionary dictionaryWithCapacity:5];

	[unarchivedShoppingList setObject:[NSString stringWithUUID] forKey:@"identifier"];

	NSString* title = item[@"name"];
	[unarchivedShoppingList setValue:title forKey:@"title"];

	NSString* notes = item[@"note"];
	[unarchivedShoppingList setValue:notes forKey:@"notes"];

	[unarchivedShoppingList setObject:[self modificationDate] forKey:@"modification-date"];

	// completed
	BOOL completed = [[item objectForKey:@"crossed"] boolValue];
	[unarchivedShoppingList setValue:@(completed) forKey:@"completed"];
	[unarchivedShoppingList setObject:[self modificationDate] forKey:@"completed-modification-date"];

	// aisle
	NSUInteger aisleDatabaseIdentifier = [[item objectForKey:@"aisle"] integerValue];
	NSDictionary* aisle = [[self aisleByDatabaseIdentifier] objectForKey:@(aisleDatabaseIdentifier)];

	NSString* aisleIdentifier = aisle[@"identifier"];
	[unarchivedShoppingList setValue:aisleIdentifier forKey:@"aisle-identifier"];
	[unarchivedShoppingList setObject:[self modificationDate] forKey:@"aisle-modification-date"];

	if(aisleIdentifier) {
		if(!self.appliedAisleIdentifiers) { self.appliedAisleIdentifiers = [NSMutableSet set]; }
		[[self appliedAisleIdentifiers] addObject:aisleIdentifier];
	}

	// quantity
	id quantity = item[@"quantity"];
	[unarchivedShoppingList setValue:quantity forKey:@"quantity"];
	[unarchivedShoppingList setObject:[self modificationDate] forKey:@"quantity-modification-date"];

	// unit
	NSString* unitIdentifier = [self unitIdentifierForUnit:[item objectForKey:@"unit"]];
	unitIdentifier = [[[self unitsByIdentifier] objectForKey:unitIdentifier] objectForKey:@"identifier"];
	[unarchivedShoppingList setValue:unitIdentifier forKey:@"unit-identifier"];

	return unarchivedShoppingList;
}

#pragma mark -

- (NSDictionary*)dictionaryFromURL:(NSURL*)URL {
	NSString* query = [URL query];
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	
	for(NSString* component in [query componentsSeparatedByString:@"&"]) {
		NSArray* parameter = [component componentsSeparatedByString:@"="];
		[parameters setObject:[parameter lastObject] forKey:[parameter firstObject]];
	}
	
	NSString* data = [parameters objectForKey:@"data"];
	
	if(data) {
		data = [data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

		NSDictionary* jsonData = [NSJSONSerialization
			JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding]
			options:NSJSONReadingAllowFragments
			error:nil];

		if(jsonData) {
			[parameters setObject:jsonData forKey:@"data"];
		}
	}
	
	return parameters;
}

@end
