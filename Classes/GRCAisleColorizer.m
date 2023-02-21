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

#import "GRCAisleColorizer.h"
#import "GRCShoppingListStore.h"

@interface GRCAisleColorizer()

@property(nonatomic, strong) GRCShoppingListStore* shoppingListStore;
@property(nonatomic, copy) NSArray* tintColors;
@property(nonatomic, strong) UIColor* grayTintColor;

@end

@implementation GRCAisleColorizer

#pragma mark - Construction & Destruction

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore {
	if((self = [super init])) {
		self.shoppingListStore = shoppingListStore;
		[self initTintColors];
	}

	return self;
}

#pragma mark - GRCAisleColorizer

- (UIColor*)tintColorForAisle:(GRCAisle*)aisle {
	if(!aisle) { return nil /*self.grayTintColor*/; }

	BOOL aisleGroupingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GRCShoppingListAisleGroupingEnabled"];
	if(!aisleGroupingEnabled) { return nil; }

	NSArray* aisles = [[self shoppingListStore] aisles];
	NSInteger aisleIndex = [aisles indexOfObject:aisle];

	NSInteger const shift = 1; // easier than adjusting the array
	aisleIndex += shift;

	NSInteger tintIndex = aisleIndex % self.tintColors.count;

	return [[self tintColors] objectAtIndex:tintIndex];
}

#pragma mark - Private

- (void)initTintColors {
	self.tintColors = @[
		[UIColor colorWithRed:0.986 green:0.050 blue:0.266 alpha:1.000], // red
		[UIColor colorWithRed:0.991 green:0.563 blue:0.034 alpha:1.000], // orange
		[UIColor colorWithRed:0.995 green:0.764 blue:0.037 alpha:1.000], // yellow
		[UIColor colorWithRed:0.228 green:0.782 blue:0.022 alpha:1.000], // green
		[UIColor colorWithRed:0.281 green:0.655 blue:0.930 alpha:1.000], // light blue
		[UIColor colorWithRed:0.041 green:0.375 blue:0.998 alpha:1.000], // blue
		[UIColor colorWithRed:0.272 green:0.234 blue:0.801 alpha:1.000]]; // purple

//	self.grayTintColor = [UIColor colorWithRed:0.484 green:0.483 blue:0.504 alpha:1.000];
}

@end
