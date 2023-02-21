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

#import "GRCUnit.h"

#import "NSString+Additions.h"

@implementation GRCUnit

NSUInteger const GRCUnitInvalidDatabaseIdentifier = NSNotFound;
NSUInteger const GRCDefaultUnitDatabaseIdentifier = 10016;

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		self.unitDatabaseIdentifier = GRCUnitInvalidDatabaseIdentifier;
		self.unitIdentifier = [NSString stringWithUUID];
		self.custom = YES;
	}

	return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(![object isKindOfClass:[self class]]) { return NO; }
	return [[self unitIdentifier] isEqual:[object unitIdentifier]];
}

- (NSUInteger)hash {
	return [[self unitIdentifier] hash];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {id = %@, database-id = %ld}",
		[super description],
		[self unitIdentifier],
		(long)[self unitDatabaseIdentifier]];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)coder {
	if((self = [self init])) {
		self.unitDatabaseIdentifier = [coder decodeIntegerForKey:@"id"];

		self.unitIdentifier = [coder decodeObjectForKey:@"persistent_id"];

		self.customSingularTitle = [coder decodeObjectForKey:@"name"];
		self.customPluralTitle = [coder decodeObjectForKey:@"plural_name"];
		self.customAbbreviation = [coder decodeObjectForKey:@"plural_short_name"];
		
		self.custom = [coder decodeBoolForKey:@"custom"];
		
		self.sortOrder = [coder decodeIntegerForKey:@"sort_order"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder {
	[NSException raise:@"encodeWithCoder not implemented" format:@""];
}

@end

@implementation GRCUnit(Serialization)

- (id)initWithDictionary:(NSDictionary*)dictionary {
	if((self = [super init])) {
		NSNumber* databaseIdentifier = [dictionary objectForKey:@"database-identifier"];
		if(databaseIdentifier) { self.unitDatabaseIdentifier = [databaseIdentifier integerValue]; }

		self.unitIdentifier = dictionary[@"identifier"];
		
		self.customSingularTitle = dictionary[@"custom-singular"];
		if(self.customSingularTitle.length == 0) { self.customSingularTitle = nil; }

		self.customPluralTitle = dictionary[@"custom-plural"];
		if(self.customPluralTitle.length == 0) { self.customPluralTitle = nil; }

		self.customAbbreviation = dictionary[@"custom-abbreviation"];
		if(self.customAbbreviation.length == 0) { self.customAbbreviation = nil; }
	}

	return self;
}

- (NSDictionary*)dictionaryRepresentation {
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:3];

	if(self.unitDatabaseIdentifier != GRCUnitInvalidDatabaseIdentifier) {
		[dictionary setObject:@([self unitDatabaseIdentifier]) forKey:@"database-identifier"];
	}

	if(self.customSingularTitle.length > 0) {
		[dictionary setValue:[self customSingularTitle] forKey:@"custom-singular"];
	}

	if(self.customPluralTitle.length > 0) {
		[dictionary setValue:[self customPluralTitle] forKey:@"custom-plural"];
	}

	if(self.customAbbreviation.length > 0) {
		[dictionary setValue:[self customAbbreviation] forKey:@"custom-abbreviation"];
	}

	[dictionary setObject:[self unitIdentifier] forKey:@"identifier"];

	return dictionary;
}

@end

@implementation GRCUnit(StandardAisles)

+ (NSArray*)standardUnits {
	NSURL* standardUnitsURL = [[NSBundle bundleForClass:[self class]]
		URLForResource:@"standard-units"
		withExtension:@"plist"];
	NSArray* array = [NSArray arrayWithContentsOfURL:standardUnitsURL];

	NSMutableArray* standardUnits = [NSMutableArray arrayWithCapacity:[array count]];

	for(NSDictionary* dictionary in array) {
		GRCUnit* unit = [[GRCUnit alloc] initWithDictionary:dictionary];
		if(unit) { [standardUnits addObject:unit]; }
	}

	return standardUnits;
}

@end
