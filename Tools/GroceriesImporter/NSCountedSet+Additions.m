//
//  NSCountedSet+Additions.m
//  Groceries Importer
//
//  Created by Sophia Teutschler on 28.01.09.
//  Copyright 2009 Sophiestication Software. All rights reserved.
//

#import "NSCountedSet+Additions.h"

@implementation NSCountedSet(Additions)

- (id)objectWithHighestCount {
	NSInteger count = 1;
	id object = nil;
	
	for(id o in self) {
		if([self countForObject:o] > count) {
			object = o;
		}
	}
	
	return object;
}

@end