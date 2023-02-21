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

#import "GRCUnitFormatter.h"

#import "NSBundle+Localization.h"
#import "NSLocale+Additions.h"

@interface GRCUnitFormatter()

@property(nonatomic, strong) NSNumberFormatter* quantityFormatter;

@end

@implementation GRCUnitFormatter

#pragma mark - Construction & Destruction

- (id)init {
	return [self initWithUnitStyle:GRCUnitFormatterStyleAbbreviation];
}

- (id)initWithUnitStyle:(GRCUnitFormatterStyle)unitStyle {
	if((self = [super init])) {
		self.unitStyle = unitStyle;
		self.locale = [NSLocale localeWithPreferredLanguageCode];
	}

	return self;
}

#pragma mark - GRCUnitFormatter

+ (NSString*)localizedStringForUnit:(GRCUnit*)unit unitStyle:(GRCUnitFormatterStyle)unitStyle {
	GRCUnitFormatter* formatter = [[[self class] alloc] initWithUnitStyle:unitStyle];
	return [formatter stringForUnit:unit];
}

+ (NSSet*)possibleStringsForUnit:(GRCUnit*)unit locale:(NSLocale*)locale {
	NSMutableSet* possibleStrings = [NSMutableSet setWithCapacity:3];

	GRCUnitFormatter* formatter = [[[self class] alloc] init];
	formatter.locale = locale;

	formatter.unitStyle = GRCUnitFormatterStyleAbbreviation;
	NSString* string = [formatter stringForUnit:unit];
	if(string.length > 0) { [possibleStrings addObject:string]; }

	formatter.unitStyle = GRCUnitFormatterStyleSingular;
	string = [formatter stringForUnit:unit];
	if(string.length > 0) { [possibleStrings addObject:string]; }

	formatter.unitStyle = GRCUnitFormatterStylePlural;
	string = [formatter stringForUnit:unit];
	if(string.length > 0) { [possibleStrings addObject:string]; }
	
	return possibleStrings;
}

- (NSString*)stringForUnit:(GRCUnit*)unit {
	NSString* string = [self stringForObjectValue:unit];
	return string;
}

- (void)setLocale:(NSLocale*)locale {
	if([[self locale] isEqual:locale]) { return; }

	_locale = locale;
	self.quantityFormatter.locale = locale;
}

#pragma mark - NSFormatter

- (NSString*)stringForObjectValue:(id)object {
	GRCUnitFormatterStyle unitStyle = self.unitStyle;

	if(unitStyle == GRCUnitFormatterStyleQuantity) {
		return [self quantityStringForUnit:object];
	} else if(unitStyle == GRCUnitFormatterStyleTitleForDisplaying) {
		NSString* string = [self stringForUnit:object unitStyle:GRCUnitFormatterStyleSingular];
		if(string.length == 0) { string = [self stringForUnit:object unitStyle:GRCUnitFormatterStylePlural]; }
		if(string.length == 0) { string = [self stringForUnit:object unitStyle:GRCUnitFormatterStyleAbbreviation]; }

		return string;
	} else {
		return [self stringForUnit:object unitStyle:unitStyle];
	}
}

#pragma mark - Private

- (NSString*)quantityStringForUnit:(GRCUnit*)unit {
	if(!self.quantity) { return nil; }
	if([[self quantity] floatValue] == 0.0) { return nil; }

	NSString* unitString;
	
	if(unit && unit.unitDatabaseIdentifier != GRCDefaultUnitDatabaseIdentifier) {
		unitString = [self stringForUnit:unit unitStyle:GRCUnitFormatterStyleAbbreviation];

		if(unitString.length <= 0) {
			GRCUnitFormatterStyle unitStyle = [[self quantity] floatValue] == 1.0 ?
				GRCUnitFormatterStyleSingular :
				GRCUnitFormatterStylePlural;
			unitString = [self stringForUnit:unit unitStyle:unitStyle];
		}
	}

	[self initQuantityFormatterIfNeeded];

	NSNumber* quantity = @([[self quantity] floatValue]); // workaround for some number formatter bug
	NSString* quantityString = [[self quantityFormatter] stringFromNumber:quantity];
		
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	NSLocale* locale = self.locale;

	NSString* string;
		
	if(unitString.length > 0) {
		NSString* formatString = [self stringNeedsAbbreviationFormat:unitString] ?
			[bundle localizedStringForKey:@"QUANTITY_WITH_UNITABBREVIATION_FORMAT" value:nil table:@"units" locale:locale] :
			[bundle localizedStringForKey:@"QUANTITY_WITH_UNIT_FORMAT" value:nil table:@"units" locale:locale];
		string = [NSString stringWithFormat:formatString, quantityString, unitString];
	} else {
		string = [NSString stringWithFormat:
			[bundle localizedStringForKey:@"QUANTITY_FORMAT" value:nil table:@"units" locale:locale],
			quantityString];
	}
		
	return string;
}

- (NSString*)stringForUnit:(GRCUnit*)unit unitStyle:(GRCUnitFormatterStyle)unitStyle {
	// check for a custom title first
	if(unitStyle == GRCUnitFormatterStyleAbbreviation && unit.customAbbreviation != nil) { return unit.customAbbreviation; }
	if(unitStyle == GRCUnitFormatterStyleSingular && unit.customSingularTitle != nil) { return unit.customSingularTitle; }
	if(unitStyle == GRCUnitFormatterStylePlural && unit.customPluralTitle != nil) { return unit.customPluralTitle; }

	// determine the title by looking up the aisle.strings file
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];

	NSString* unitIdentifier = [unit unitIdentifier];
	
	NSString* styleString;
	if(unitStyle == GRCUnitFormatterStyleAbbreviation) { styleString = @"abbreviation"; }
	if(unitStyle == GRCUnitFormatterStyleSingular) { styleString = @"singular"; }
	if(unitStyle == GRCUnitFormatterStylePlural) { styleString = @"plural"; }

	NSString* localizationKey = [NSString stringWithFormat:@"%@.%@", unitIdentifier, styleString];

	NSLocale* locale = self.locale;

	NSString* string = [bundle localizedStringForKey:localizationKey value:nil table:@"units" locale:locale];
	if([string isEqualToString:localizationKey]) { return nil; }

	return string;
}

- (void)initQuantityFormatterIfNeeded {
	if(self.quantityFormatter) { return; }
	
	NSNumberFormatter* quantityFormatter = [[NSNumberFormatter alloc] init];
	
	quantityFormatter.numberStyle = NSNumberFormatterDecimalStyle;
	quantityFormatter.locale = self.locale;

	self.quantityFormatter = quantityFormatter;
}

- (BOOL)stringNeedsAbbreviationFormat:(NSString*)string {
	if(string.length == 0) { return YES; }

	unichar character = [string characterAtIndex:0];
	return [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:character];
}

@end
