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

#import "GRCAisle.h"

#import "NSString+Additions.h"

@implementation GRCAisle

NSString* const GRCAisleImageNameGeneric = @"generic";
NSUInteger const GRCAisleInvalidDatabaseIdentifier = NSNotFound;

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		self.aisleDatabaseIdentifier = GRCAisleInvalidDatabaseIdentifier;
		self.aisleIdentifier = [NSString stringWithUUID];
		self.image = GRCAisleImageNameGeneric;
		self.custom = YES;
	}

	return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(![object isKindOfClass:[self class]]) { return NO; }
	return [[self aisleIdentifier] isEqual:[object aisleIdentifier]];
}

- (NSUInteger)hash {
	return [[self aisleIdentifier] hash];
}

- (NSString*)description {
	if(self.customTitle.length) {
		return [NSString stringWithFormat:@"%@ {id = %@, title = %@}",
			[super description],
			[self aisleIdentifier],
			[self customTitle]];
	}

	return [NSString stringWithFormat:@"%@ {id = %@, database-id = %ld}",
		[super description],
		[self aisleIdentifier],
		(long)[self aisleDatabaseIdentifier]];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)coder {
	if((self = [self init])) {
		self.aisleDatabaseIdentifier = [coder decodeIntegerForKey:@"id"];

		self.aisleIdentifier = [coder decodeObjectForKey:@"persistent_id"];

		self.customTitle = [coder decodeObjectForKey:@"name"];
		self.image = [coder decodeObjectForKey:@"image"];

		self.custom = [coder decodeBoolForKey:@"custom"];
		
		self.sortOrder = [coder decodeIntegerForKey:@"sort_order"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder {
	[NSException raise:@"encodeWithCoder not implemented" format:@""];
}

@end

@implementation GRCAisle(Serialization)

- (id)initWithDictionary:(NSDictionary*)dictionary {
	if((self = [super init])) {
		NSNumber* databaseIdentifier = [dictionary objectForKey:@"database-identifier"];
		if(databaseIdentifier) { self.aisleDatabaseIdentifier = [databaseIdentifier integerValue]; }

		self.aisleIdentifier = dictionary[@"identifier"];

		self.image = dictionary[@"image"];
		self.customTitle = dictionary[@"custom-title"];
	}

	return self;
}

- (NSDictionary*)dictionaryRepresentation {
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:5];

	if(self.aisleDatabaseIdentifier != GRCAisleInvalidDatabaseIdentifier) {
		[dictionary setObject:@([self aisleDatabaseIdentifier]) forKey:@"database-identifier"];
	}

	[dictionary setObject:[self aisleIdentifier] forKey:@"identifier"];
	[dictionary setObject:[self image] forKey:@"image"];

	if(self.customTitle.length > 0) {
		[dictionary setObject:[self customTitle] forKey:@"custom-title"];
	}

	return dictionary;
}

@end

@implementation GRCAisle(StandardAisles)

+ (NSArray*)standardAisles {
	NSURL* standardAislesURL = [[NSBundle bundleForClass:[self class]]
		URLForResource:@"standard-aisles"
		withExtension:@"plist"];
	NSArray* array = [NSArray arrayWithContentsOfURL:standardAislesURL];

	NSMutableArray* standardAisles = [NSMutableArray arrayWithCapacity:[array count]];

	for(NSDictionary* dictionary in array) {
		GRCAisle* aisle = [[GRCAisle alloc] initWithDictionary:dictionary];
		if(aisle) { [standardAisles addObject:aisle]; }
	}

	return standardAisles;
}

@end
