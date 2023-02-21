//
//  NSString+Additions.h
//  Groceries
//
//  Created by Sophia Teutschler on 04.04.08.
//  Copyright 2008 Sophiestication Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @category	 NSString(Additions)
    @abstract    <#(brief description)#>
    @discussion  <#(comprehensive description)#>
*/
@interface NSString(Additions)

+ (NSString*)stringWithUUID;

- (NSString*)stringByStrippingDiacritics;

- (NSArray*)searchExpressions;
- (NSArray*)searchExpressionsSeparatedByCharactersInSet:(NSCharacterSet*)separator;

- (NSString*)sectionIndexString;
- (NSString*)searchIndexString;

@end

/*!
    @category	 NSMutableString(Additions)
    @abstract    <#(brief description)#>
    @discussion  <#(comprehensive description)#>
*/
@interface NSMutableString(Additions)

- (void)stripDiacritics;
- (void)stripDiacriticsInRange:(NSRange)range;

@end