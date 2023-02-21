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

#import "GRCShoppingListStore.h"
#import "GRCShoppingList.h"

@protocol GRCShoppingListPickerViewDelegate;

@interface GRCShoppingListPickerViewController : UITableViewController

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore;
- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore style:(UITableViewStyle)style;

@property(nonatomic, readonly, strong) GRCShoppingListStore* shoppingListStore;
@property(nonatomic, weak) GRCShoppingList* selectedShoppingList;

@property(nonatomic, weak) id<GRCShoppingListPickerViewDelegate> delegate;

@property(nonatomic) BOOL allowsModifications;

@end

@protocol GRCShoppingListPickerViewDelegate<NSObject>

@optional
- (void)shoppingListPicker:(GRCShoppingListPickerViewController*)picker didFinishPickingShoppingList:(GRCShoppingList*)shoppingList;
- (void)shoppingListPickerDidCancel:(GRCShoppingListPickerViewController*)picker;

@end

@protocol GRCShoppingListPickerViewDelegateAccessory<GRCShoppingListPickerViewDelegate>

@optional
- (BOOL)shoppingListPicker:(GRCShoppingListPickerViewController*)picker shouldShowAccessoryButtonForShoppingList:(GRCShoppingList*)shoppingList;
- (void)shoppingListPicker:(GRCShoppingListPickerViewController*)picker accessoryButtonTappedForShoppingList:(GRCShoppingList*)shoppingList;

@end
