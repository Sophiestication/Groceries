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

#import "GRCInflector.h"

#import "NSLocale+Additions.h"

@interface GRCInflector()

@property(nonatomic, strong) NSLocale* locale;

@property(nonatomic, strong) NSMutableSet* uncountableWords;
@property(nonatomic, strong) NSMutableArray* pluralRules;
@property(nonatomic, strong) NSMutableArray* singularRules;

@end

@implementation GRCInflector

#pragma mark - Construction & Destruction

- (id)init {
	return [self initWithLocale:[NSLocale autoupdatingCurrentLocale]];
}

- (id)initWithLocale:(NSLocale*)locale {
	if((self = [super init])) {
		self.locale = locale;

		[self initIvars];
		[self initInflections];
	}
	
	return self;
}

#pragma mark - GRCInflector

- (NSString*)pluralize:(NSString*)singular {
	return [self applyRules:[self pluralRules] toString:singular];
}

- (NSString*)singularize:(NSString*)plural {
	return [self applyRules:[self singularRules] toString:plural];
}

#pragma mark - Private

- (void)initIvars {
	self.uncountableWords = [NSMutableSet set];
    self.pluralRules = [NSMutableArray array];
    self.singularRules = [NSMutableArray array];
}

- (void)initInflections {
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	NSString* languageCode = [[self locale] preferredLanguageCode];
	NSURL* inflectionsURL = [bundle URLForResource:@"inflections" withExtension:@"plist" subdirectory:nil localization:languageCode];
	
	NSDictionary* inflections = [NSDictionary dictionaryWithContentsOfURL:inflectionsURL];
	
	for(NSArray* pluralRule in inflections[@"pluralRules"]) {
		[self addPluralRuleFor:pluralRule[0] replacement:pluralRule[1]];
	}
  
	for(NSArray* singularRule in inflections[@"singularRules"]) {
		[self addSingularRuleFor:singularRule[0] replacement:singularRule[1]];
	}

	for(NSArray* irregularRule in inflections[@"irregularRules"]) {
		[self addIrregularRuleForSingular:irregularRule[0] plural:irregularRule[1]];
	}
  
	for(NSString* uncountableWord in inflections[@"uncountableWords"]) {
		[self addUncountableWord:uncountableWord];
	}
}

- (void)addUncountableWord:(NSString*)string {
	[[self uncountableWords] addObject:string];
}

- (void)addIrregularRuleForSingular:(NSString*)singular plural:(NSString*)plural {
	NSString* singularRule = [NSString stringWithFormat:@"%@$", plural];
	[self addSingularRuleFor:singularRule replacement:singular];
  
	NSString* pluralRule = [NSString stringWithFormat:@"%@$", singular];
	[self addPluralRuleFor:pluralRule replacement:plural];  
}

- (void)addPluralRuleFor:(NSString*)rule replacement:(NSString*)replacement {
	NSDictionary* dictionary = @{
		@"rule": rule,
		@"replacement": replacement };
	[[self pluralRules] insertObject:dictionary atIndex:0];
}

- (void)addSingularRuleFor:(NSString*)rule replacement:(NSString*)replacement {
	NSDictionary* dictionary = @{
		@"rule": rule,
		@"replacement": replacement };
	[[self singularRules] insertObject:dictionary atIndex:0];
}

- (NSString*)applyRules:(NSArray*)rules toString:(NSString*)string {
	if(string.length == 0) { return string; }
	if([[self uncountableWords] containsObject:string]) { return string; }
  
	for(NSDictionary* rule in rules) {
		NSString* ruleString = rule[@"rule"];
		NSString* replacementString = rule[@"replacement"];
	
		NSRange range = NSMakeRange(0, [string length]);
		NSError* error;
		
		NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:ruleString options:NSRegularExpressionCaseInsensitive error:&error];
		
		if(!regex) {
			NSLog(@"Could not create regular expression with pattern: %@", error);
			continue;
		}
		
		if([regex firstMatchInString:string options:0 range:range]) {
			return [regex
				stringByReplacingMatchesInString:string
				options:NSRegularExpressionCaseInsensitive
				range:range
				withTemplate:replacementString];
		}
	}
    
	return string;
}

@end
