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

#import <UIKit/UIKit.h>

@class GRCAisle;
@class GRCShoppingListStore;
@protocol GRCAislePickerViewDelegate;

@interface GRCAislePickerViewController : UITableViewController

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore;
- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore style:(UITableViewStyle)style;

@property(nonatomic, readonly, strong) GRCShoppingListStore* shoppingListStore;
@property(nonatomic, strong) GRCAisle* selectedAisle;

@property(nonatomic, weak) id<GRCAislePickerViewDelegate> delegate;

@property(nonatomic) BOOL showsSelectionIndicator;
@property(nonatomic) BOOL allowsModifications;

@end

@protocol GRCAislePickerViewDelegate<NSObject>

@optional
- (BOOL)shouldAislePicker:(GRCAislePickerViewController*)picker pickAisle:(GRCAisle*)aisle;
- (void)aislePicker:(GRCAislePickerViewController*)picker didFinishPickingAisle:(GRCAisle*)aisle;

@end
