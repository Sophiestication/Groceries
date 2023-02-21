//
//  GRCGroceryPickerViewController.h
//  Groceries
//
//  Created by Sophia Teutschler on 29.09.12.
//  Copyright (c) 2012 Sophia Teutschler. All rights reserved.
//

#import "GRCGroceryPickerViewController.h"

@class GRCShoppingListStore;

@interface GRCGroceryPickerRootViewController : UITableViewController

@property(nonatomic, strong) GRCShoppingListStore* shoppingListStore;

@end