//
//  GRCGroceryPickerViewController.h
//  Groceries
//
//  Created by Sophia Teutschler on 08.11.12.
//  Copyright (c) 2012 Sophia Teutschler. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GRCShoppingListStore;
@class GRCShoppingListItem;
@class GRCGrocery;

@class GRCBarcodeReaderViewController;
@class GRCShoppingListItemDetailsViewController;

@protocol GRCGroceryPickerViewDelegate;

@interface GRCGroceryPickerViewController : UINavigationController

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore;
@property(nonatomic, readonly, strong) GRCShoppingListStore* shoppingListStore;

@end

@interface GRCGroceryPickerViewController(BarcodeReader)

- (void)presentBarcodeReaderViewController:(GRCBarcodeReaderViewController*)viewController animated:(BOOL)animated completion:(void (^)(void))completion;
- (void)dismissBarcodeReaderViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion;

@end

@protocol GRCGroceryPickerViewDelegate<UINavigationControllerDelegate>

- (GRCShoppingListItem*)groceryPicker:(GRCGroceryPickerViewController*)picker shoppingListItemForItem:(GRCGrocery*)grocery;

@optional
- (void)groceryPicker:(GRCGroceryPickerViewController*)picker didFinishPickingItems:(NSSet*)items;

- (void)groceryPicker:(GRCGroceryPickerViewController*)picker didSelectItem:(GRCGrocery*)grocery;
- (void)groceryPicker:(GRCGroceryPickerViewController*)picker didDeselectItem:(GRCGrocery*)grocery;

- (GRCShoppingListItemDetailsViewController*)groceryPicker:(GRCGroceryPickerViewController*)picker needsViewControllerForItem:(GRCGrocery*)grocery;

@end