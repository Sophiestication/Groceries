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

#import "NSBundle+Localization.h"
#import "NSLocale+Additions.h"

#import <objc/runtime.h>

@implementation NSBundle(Localization)

volatile static void* const SUILocalizedBundleStringsAssocitatedObjectKey;

- (NSString*)localizedStringForKey:(NSString*)key value:(NSString*)value table:(NSString*)tableName locale:(NSLocale*)locale {
	if(!locale /*|| [locale isEqual:[NSLocale currentLocale]]*/) {
		return [self localizedStringForKey:key value:value table:tableName];
	}
	
	if(!tableName) { tableName = @"Localizable"; } // default .strings file
	
	NSCache* cache = objc_getAssociatedObject(self, &SUILocalizedBundleStringsAssocitatedObjectKey);

	NSString* localeIdentifier = [locale localeIdentifier];

	NSString* cacheKey = [NSString stringWithFormat:@"%@-%@", tableName, localeIdentifier];
	NSDictionary* strings = [cache objectForKey:cacheKey];
	
	if(!strings) {
		NSURL* URL = [self URLForResource:tableName withExtension:@"strings" subdirectory:nil localization:localeIdentifier];
		
		if(!URL) {
			localeIdentifier = [locale objectForKey:NSLocaleLanguageCode];
			URL = [self URLForResource:tableName withExtension:@"strings" subdirectory:nil localization:localeIdentifier];
		}
		
		strings = [NSDictionary dictionaryWithContentsOfURL:URL];

		if(!cache) {
			cache = [[NSCache alloc] init];
			objc_setAssociatedObject(self, &SUILocalizedBundleStringsAssocitatedObjectKey, cache, OBJC_ASSOCIATION_RETAIN);
		}

		if(!strings) { strings = (id)[NSNull null]; } // prevents frequent bundle lookups
		[cache setObject:strings forKey:cacheKey];
	}

	if(!strings || [strings isEqual:[NSNull null]]) { // fallback for unsupported locales
		return [self localizedStringForKey:key value:value table:tableName];
	}

	NSString* localizedString = strings[key];
	if(!localizedString) { return value; }
	
	return localizedString;
}

@end
