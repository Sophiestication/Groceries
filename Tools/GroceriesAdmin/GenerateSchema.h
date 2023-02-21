//
//  GenerateSchema.h
//  GroceriesAdmin
//
//  Created by Sophia Teutschler on 08.01.09.
//  Copyright 2009 Sophiestication Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GenerateSchema : NSObject {
@private
	NSOutputStream* _out;
}

- (void)execute:(NSArray*)arguments;

- (void)generateWithTemplate:(NSString*)templateString arguments:(NSArray*)arguments;
- (void)generateIndexStatements:(NSArray*)arguments;
- (void)generateRecreateStatements:(NSArray*)arguments;

- (void)writeString:(NSString*)string;
- (NSArray*)letters;

@end