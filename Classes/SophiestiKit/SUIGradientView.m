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

#import "SUIGradientView.h"

@implementation SUIGradientView

@synthesize colors = colors_;

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
    }

    return self;
}

#pragma mark - SUIGradientView

- (CAGradientLayer*)gradientLayer {
	return (CAGradientLayer*)[self layer];
}

- (void)setColors:(NSArray*)colors {
	if(colors == self.colors) { return; }
	
	colors_ = [colors copy];
	
	NSMutableArray* layerColors = [[NSMutableArray alloc] initWithCapacity:[colors count]];
	
	for(UIColor* color in colors) {
		[layerColors addObject:(id)[color CGColor]];
	}
	
	[[self gradientLayer] setColors:layerColors];
}

#pragma mark - UIView

+ (Class)layerClass {
	return [CAGradientLayer class];
}

#pragma mark - Private

@end

@implementation SUIGradientView(SystemGradients)

+ (SUIGradientView*)tableViewSelectionGradient {
	SUIGradientView* gradient = [[SUIGradientView alloc] initWithFrame:CGRectZero];
	
	gradient.colors = [NSArray arrayWithObjects:
		[UIColor colorWithRed:0.02 green:0.55 blue:0.96 alpha:1.00],
		[UIColor colorWithRed:0.04 green:0.37 blue:0.91 alpha:1.00],
		nil];
	
	return gradient;
}

@end
