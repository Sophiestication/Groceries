//
//  NSString+SQL.h
//  Groceries
//
//  Created by Sophia Teutschler on 13.01.09.
//  Copyright 2009 Sophiestication Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
    @category	 NSString(SQL)
    @abstract    <#(brief description)#>
    @discussion  <#(comprehensive description)#>
*/
@interface NSString(SQL)

+ (NSString*)stringWithSQLFormat:(NSString*)format, ...;

- (NSString*)stringByEscapingSQLCharacters;
- (NSString*)stringByConvertingToSQLInsertString;

@end