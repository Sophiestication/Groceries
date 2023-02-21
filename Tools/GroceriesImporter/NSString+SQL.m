//
//  NSString+SQL.m
//  Groceries
//
//  Created by Sophia Teutschler on 13.01.09.
//  Copyright 2009 Sophiestication Software. All rights reserved.
//

#import "NSString+SQL.h"

#import "sqlite3.h"

@implementation NSString(SQL)

+ (NSString*)stringWithSQLFormat:(NSString*)format, ... {
	va_list args;
	char* SQLString = sqlite3_mprintf([format UTF8String], args);

	if(SQLString) {
		NSString* newString = [NSString stringWithUTF8String:SQLString];
		sqlite3_free(SQLString);
		return newString;
	}

	return nil;
}

- (NSString*)stringByEscapingSQLCharacters {
	char* escaped = sqlite3_mprintf("%q", [self UTF8String]);
	
	if(escaped) {
		NSString* newString = [NSString stringWithUTF8String:escaped];
		sqlite3_free(escaped);
		return newString;
	}
	
	return nil;
}

- (NSString*)stringByConvertingToSQLInsertString {
	char* escaped = sqlite3_mprintf("%Q", [self UTF8String]);
	
	if(escaped) {
		NSString* newString = [NSString stringWithUTF8String:escaped];
		sqlite3_free(escaped);
		return newString;
	}
	
	return nil;
}

@end