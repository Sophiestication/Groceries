//
//  NSString+Additions.m
//  Groceries
//
//  Created by Sophia Teutschler on 04.04.08.
//  Copyright 2008 Sophiestication Software. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString(Additions)

+ (NSString*)stringWithUUID {
	CFUUIDRef UUID = CFUUIDCreate(NULL);
	NSString* string = NSMakeCollectable(CFUUIDCreateString(NULL, UUID));
    CFRelease(UUID);
    
	return [string autorelease];
}

- (NSString*)stringByStrippingDiacritics {
	if(self.length > 0) {
		NSMutableString* string = [NSMutableString stringWithString:self];
	
		[string stripDiacritics];
	
		return string;
	}
	
	return self;
}

- (NSArray*)searchExpressions {
	NSMutableCharacterSet* separators = nil;
	
	separators = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
	[separators addCharactersInString:@"-"];
	
	return [self searchExpressionsSeparatedByCharactersInSet:separators];
}

- (NSArray*)searchExpressionsSeparatedByCharactersInSet:(NSCharacterSet*)separator {
	NSArray* components = [self componentsSeparatedByCharactersInSet:separator];
	
	NSMutableArray* searchExpressions = [NSMutableArray arrayWithCapacity:[components count]];
	
	NSMutableCharacterSet* allowedCharacters = [NSMutableCharacterSet letterCharacterSet];
	[allowedCharacters formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
	
	NSCharacterSet* forbiddenCharacters = [allowedCharacters invertedSet];
	
	for(NSString* component in components) {
		component = [component stringByStrippingDiacritics];
		component = [component lowercaseString];
		component = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		// Remove none allowed characters
		if(component.length > 0) {
			component = [component stringByTrimmingCharactersInSet:forbiddenCharacters];
		}

		if(component.length > 0) {
			[searchExpressions addObject:component];
		}
	}
	
	if(searchExpressions.count > 1) {
		NSArray* sortDescriptors = [NSArray arrayWithObjects:
			[[[NSSortDescriptor alloc] initWithKey:@"length" ascending:NO] autorelease],
			nil];
		return [searchExpressions sortedArrayUsingDescriptors:sortDescriptors];
	}
	
	return searchExpressions;
}

- (NSString*)sectionIndexString {
	if(self.length > 0) {
		NSString* strippedString = [[[self substringWithRange:NSMakeRange(0, 1)] uppercaseString] stringByStrippingDiacritics];
		unichar firstChar = [strippedString characterAtIndex:0];
		
		if([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:firstChar]) {
			return [NSString stringWithCharacters:&firstChar length:1];
		}
	}

	return @"#"; // TODO
}

- (NSString*)searchIndexString {
	NSString* strippedString = [[self lowercaseString] stringByStrippingDiacritics];
	
	if(strippedString.length == 0) {
		return nil;
	}

	unichar firstChar = [strippedString characterAtIndex:0];
	NSString* searchIndexString = nil;
	
	if([[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:firstChar]) {
		searchIndexString = [NSString stringWithCharacters:&firstChar length:1];
	} else {
		searchIndexString = @"0";
	}
	
	return searchIndexString;
}

@end

@implementation NSMutableString(Additions)

- (void)stripDiacritics {
	if(self.length > 0) {
		NSRange range = NSMakeRange(0, [self length]);
		[self stripDiacriticsInRange:range];
	}
}

- (void)stripDiacriticsInRange:(NSRange)range {
	CFRange aRange = CFRangeMake(range.location, range.length);
	
	if(!CFStringTransform((CFMutableStringRef)self, &aRange, kCFStringTransformStripDiacritics, NO)) {
		// TODO
	}
}

@end