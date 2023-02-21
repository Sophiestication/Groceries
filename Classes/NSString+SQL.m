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

#import "NSString+SQL.h"
#import	<sqlite3.h>

@implementation NSString(SQL)

+ (NSString*)stringWithSQLFormat:(NSString*)format, ... {
	va_list args;
	va_start(args, format);
	
	char* SQLString = sqlite3_vmprintf([format UTF8String], args);

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

@end
