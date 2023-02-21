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

#import "SUIImageStyles.h"

#import "UIColor+Interface.h"
#import "UIImage+Styles.h"

NSMapTable* SUIGetImageStyles(void) {
	static dispatch_once_t once;
    static NSMapTable* sharedImageStyles;
	
    dispatch_once(&once, ^{
		//sharedImageStyles = [[NSMutableDictionary alloc] initWithCapacity:6];
		sharedImageStyles = [NSMapTable strongToStrongObjectsMapTable];
		
		NSDictionary* style;
		
		// SUIGroupedTableViewHeaderImageStyle
		style = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor groupTableViewHeaderTextColor], SUIImageStyleFillColor,
			[UIColor whiteColor], SUIImageStyleShadowColor,
			nil];
		[sharedImageStyles setObject:style forKey:SUIGroupedTableViewHeaderImageStyle];
	
		// SUITableViewCellImageStyle
		style = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor colorWithWhite:0.251 alpha:1.000], SUIImageStyleFillColor,
			nil];
		[sharedImageStyles setObject:style forKey:SUITableViewCellImageStyle];

        // SUITableViewCellDarkImageStyle
		style = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor darkTextColor], SUIImageStyleFillColor,
			nil];
		[sharedImageStyles setObject:style forKey:SUITableViewCellDarkImageStyle];
	
		// SUITableViewCellSelectedImageStyle
		style = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor selectedTableViewCellTextColor], SUIImageStyleFillColor,
			nil];
		[sharedImageStyles setObject:style forKey:SUITableViewCellSelectedImageStyle];
	
		// SUITableViewCellGrayImageStyle
		style = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor grayTableViewCellTextColor], SUIImageStyleFillColor,
			nil];
		[sharedImageStyles setObject:style forKey:SUITableViewCellGrayImageStyle];
	
		// SUITableViewCellBlueImageStyle
		style = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor blueTableViewCellTextColor], SUIImageStyleFillColor,
			nil];
		[sharedImageStyles setObject:style forKey:SUITableViewCellBlueImageStyle];
	
		// SUIToolbarItemImageStyle
		style = [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor whiteColor], SUIImageStyleFillColor,
			[[UIColor blackColor] colorWithAlphaComponent:0.5], SUIImageStyleShadowColor,
			[NSValue valueWithCGPoint:CGPointMake(0.0, 1.0)], SUIImageStyleShadowOffset,
			nil];
		[sharedImageStyles setObject:style forKey:SUIToolbarItemImageStyle];
	});

    return sharedImageStyles;
}
