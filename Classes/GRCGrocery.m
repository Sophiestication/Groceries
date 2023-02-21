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

#import "GRCGrocery.h"

#import "GRCGroceryStore.h"

#import "GRCUnit.h"
#import "GRCAisle.h"

#import "GRCDetector.h"

#import "NSString+Additions.h"

@interface GRCGrocery()
@end

@implementation GRCGrocery

NSUInteger const GRCGroceryInvalidDatabaseIdentifier = NSNotFound;

#pragma mark - Construction & Destruction

- (id)init {
	if((self = [super init])) {
		self.groceryIdentifier = [NSString stringWithUUID];
		self.groceryDatabaseIdentifier = GRCGroceryInvalidDatabaseIdentifier;
		self.aisleDatabaseIdentifier = GRCAisleInvalidDatabaseIdentifier;
		self.unitDatabaseIdentifier = GRCUnitInvalidDatabaseIdentifier;
		self.languageDatabaseIdentifier = NSNotFound;
		
		self.generic = NO;
		self.custom = YES;
	}

	return self;
}

#pragma mark - GRCGrocery

/*
- (void)setUnit:(GRCUnit*)unit {
	self.unitDatabaseIdentifier = unit ? unit.unitDatabaseIdentifier : GRCUnitInvalidDatabaseIdentifier;
	_unit = unit;
}
*/

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if(self == object) { return YES; }
	if(![object isKindOfClass:[self class]]) { return NO; }
	return [[self groceryIdentifier] isEqual:[object groceryIdentifier]];
}

- (NSUInteger)hash {
	return [[self groceryIdentifier] hash];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ {id = %@, title = %@}",
		[super description],
		[self groceryIdentifier],
		[self title]];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)coder {
	if((self = [self init])) {
		self.groceryIdentifier = [coder decodeObjectForKey:@"persistent_id"];
		self.groceryDatabaseIdentifier = [coder decodeIntegerForKey:@"id"];

		self.title = [coder decodeObjectForKey:@"name"];
		self.notes = [coder decodeObjectForKey:@"note"];
		
		if([coder containsValueForKey:@"aisle_id"]) {
			self.aisleDatabaseIdentifier = [coder decodeIntegerForKey:@"aisle_id"];
		}
		
		if([coder containsValueForKey:@"language"]) {
			self.languageDatabaseIdentifier = [coder decodeIntegerForKey:@"language"];
		}

		if([coder containsValueForKey:@"quantity"]) {
			self.quantity = @([coder decodeDoubleForKey:@"quantity"]);
		}

		if([coder containsValueForKey:@"unit_id"]) {
			self.unitDatabaseIdentifier = [coder decodeIntegerForKey:@"unit_id"];
		}

		self.generic = [coder decodeBoolForKey:@"generic"];
		self.custom = [coder decodeBoolForKey:@"custom"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder*)aCoder {
	[NSException raise:@"encodeWithCoder not implemented" format:@""];
}

@end

#pragma mark - Detector

@implementation GRCGrocery(Detector)

- (id)initWithDetectorValue:(GRCDetectorValue*)detectorValue {
	if((self = [self init])) {
		self.title = detectorValue.groceryTitle;
		self.notes = detectorValue.notes;

		self.quantity = detectorValue.quantity;
		self.unit = detectorValue.unit;

		self.generic = NO;
		self.custom = YES;

		NSLocale* locale = detectorValue.locale;
		self.languageDatabaseIdentifier = [GRCGroceryStore languageDatabaseIdentifierForLocale:locale];
	}

	return self;
}

@end
