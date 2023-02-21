//
//  GenerateSchema.m
//  GroceriesAdmin
//
//  Created by Sophia Teutschler on 08.01.09.
//  Copyright 2009 Sophiestication Software. All rights reserved.
//

#import "GenerateSchema.h"

@implementation GenerateSchema

- (void)dealloc {
	[_out release];
	[super dealloc];
}

- (void)execute:(NSArray*)arguments {
	// Open the output file
	NSString* outputFile = [[arguments objectAtIndex:0] stringByExpandingTildeInPath];
	_out = [[NSOutputStream outputStreamToFileAtPath:outputFile append:NO] retain];
	
	[_out open];
	
/*	[self generateRecreateStatements:arguments];
	[self generateIndexStatements:arguments];
	return; */
	
	// Generate all drop statements
//	[self generateWithTemplate:@"DROP TABLE __%@_autocomplete_%@_%@;\n" arguments:arguments];
	
	// And now all create statements
	NSString* createTemplate = @""
		@"CREATE TABLE __%@_autocomplete_%@_%@ ("
		@"name TEXT, "
		@"grocery_id TEXT);\n";
	[self generateWithTemplate:createTemplate arguments:arguments];
	
	// Generate the index statements
	[self generateIndexStatements:arguments];
}

- (void)generateWithTemplate:(NSString*)templateString arguments:(NSArray*)arguments {
	// Generate tables for groceries and brands
	NSArray* tables = [NSArray arrayWithObjects:@"grocery", nil];
	
	for(NSString* table in tables) {
		// Generate tables for each language
		NSArray* languages = [arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)];
	
		for(NSString* language in languages) {
			// And each section index title
			for(NSString* letter in [self letters]) {
				NSString* schema = [NSString stringWithFormat:templateString, table, language, letter];
				
				[self writeString:schema];
			}
		}
	}
}

- (void)generateRecreateStatements:(NSArray*)arguments {
	// Generate tables for groceries and brands
	NSArray* tables = [NSArray arrayWithObjects:@"grocery", @"brand", nil];
	
	NSString* templateString = @"CREATE TABLE __%@_autocomplete_%@_%@_2 AS SELECT * FROM __%@_autocomplete_%@_%@ ORDER BY name, grocery_id;\n";
	NSString* templateString2 = @"DROP TABLE __%@_autocomplete_%@_%@;\n";
	NSString* templateString3 = @"ALTER TABLE __%@_autocomplete_%@_%@_2 RENAME TO __%@_autocomplete_%@_%@;\n";
	
	for(NSString* table in tables) {
		// Generate tables for each language
		NSArray* languages = [arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)];
	
		for(NSString* language in languages) {
			// And each section index title
			for(NSString* letter in [self letters]) {
				NSString* recreate = [NSString stringWithFormat:templateString, table, language, letter, table, language, letter];
				[self writeString:recreate];
				
				NSString* drop = [NSString stringWithFormat:templateString2, table, language, letter];
				[self writeString:drop];
				
				NSString* index = [NSString stringWithFormat:templateString3, table, language, letter, table, language, letter];
				[self writeString:index];
			}
		}
	}
}

- (void)generateIndexStatements:(NSArray*)arguments {
	// Generate tables for groceries and brands
	NSArray* tables = [NSArray arrayWithObjects:@"grocery", nil];
	
	NSString* templateString = @"CREATE INDEX __%@_autocomplete_%@_%@_index ON __%@_autocomplete_%@_%@(name);\n";
	
	for(NSString* table in tables) {
		// Generate tables for each language
		NSArray* languages = [arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)];
	
		for(NSString* language in languages) {
			// And each section index title
			for(NSString* letter in [self letters]) {
				NSString* schema = [NSString stringWithFormat:templateString, table, language, letter, table, language, letter];
				
				[self writeString:schema];
			}
		}
	}
}

- (void)writeString:(NSString*)string {
	NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[_out write:[data bytes] maxLength:[data length]];
}

- (NSArray*)letters {
	NSMutableArray* letters = [NSMutableArray array];
	
	for(unichar c='a'; c<='z'; ++c) {
		[letters addObject:[NSString stringWithCharacters:&c length:1]];
	}
	
	[letters addObject:@"0"];
	
	return letters;
}

@end