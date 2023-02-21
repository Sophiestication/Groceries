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

#import "UIActionSheet+Additions.h"

#import <objc/runtime.h>

@implementation UIActionSheet(Additions)

static void* const SUIActionSheetBlocksAssocitatedObjectKey;

- (void)addButtonWithTitle:(NSString*)title block:(void (^)())block {
	NSMutableArray* blocks = objc_getAssociatedObject(self, &SUIActionSheetBlocksAssocitatedObjectKey);

	if(!blocks) {
		blocks = [NSMutableArray arrayWithCapacity:2];
		objc_setAssociatedObject(self, &SUIActionSheetBlocksAssocitatedObjectKey, blocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}

	[blocks addObject:[block copy]];
	[self addButtonWithTitle:title];

	self.delegate = (id)self;
}

- (void)setCancelButtonWithTitle:(NSString*)title block:(void (^)())block {
	[self addButtonWithTitle:title block:block];
	self.cancelButtonIndex = self.numberOfButtons - 1;
}

- (void)setDestructiveButtonWithTitle:(NSString*)title block:(void (^)())block {
	[self addButtonWithTitle:title block:block];
	self.destructiveButtonIndex = self.numberOfButtons - 1;
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray* blocks = objc_getAssociatedObject(self, &SUIActionSheetBlocksAssocitatedObjectKey);

	if(buttonIndex >= 0 && buttonIndex < blocks.count) {
        void (^actionBlock)() = [blocks objectAtIndex:buttonIndex];
        if(actionBlock) { actionBlock(); }
    }
}

@end
