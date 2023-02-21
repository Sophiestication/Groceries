//
//  GRCGroceryPickerViewController.m
//  Groceries
//
//  Created by Sophia Teutschler on 08.11.12.
//  Copyright (c) 2012 Sophia Teutschler. All rights reserved.
//

#import "GRCGroceryPickerViewController.h"
#import "GRCGroceryPickerRootViewController.h"
#import "GRCGroceryPickerHeaderView.h"

#import "GRCBarcodeReaderViewController.h"

@interface GRCGroceryPickerNavigationBar : UINavigationBar
@end

@interface GRCGroceryPickerViewController()

@property(nonatomic, readwrite, strong) GRCShoppingListStore* shoppingListStore;

@property(nonatomic, strong) GRCGroceryPickerRootViewController* rootViewController;

@property(nonatomic, strong) GRCBarcodeReaderViewController* barcodeReaderViewController;
@property(nonatomic, strong) UIImageView* barcodeReaderShadowView;
@property(nonatomic, getter=isBarcodeReaderViewShown) BOOL barcodeReaderViewShown;

@end

@implementation GRCGroceryPickerViewController

#pragma mark - Construction & Destruction

- (id)initWithShoppingListStore:(GRCShoppingListStore*)shoppingListStore {
	GRCGroceryPickerRootViewController* rootViewController = [[GRCGroceryPickerRootViewController alloc] initWithStyle:UITableViewStylePlain];
	rootViewController.shoppingListStore = shoppingListStore;

	if((self = [self initWithNavigationBarClass:[GRCGroceryPickerNavigationBar class] toolbarClass:[UIToolbar class]])) {
		self.shoppingListStore = shoppingListStore;
		self.viewControllers = @[ rootViewController ];
	}

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

/*	CGRect contentRect = self.view.bounds;

	// navigation bar
	CGSize navigationBarSize = [[self searchBar]
		sizeThatFits:contentRect.size];

	CGRect navigationBarRect = contentRect;
	navigationBarRect.size.height = navigationBarSize.height;
	navigationBarRect.origin.y = 20.0;

	// root view controller
	CGRect rootViewRect = contentRect;
	rootViewRect.origin.y += navigationBarSize.height;
	rootViewRect.size.height -= navigationBarSize.height;

	// barcode reader view controller
	CGRect barcodeReaderViewRect = CGRectZero;
	CGFloat const barcodeReaderViewHeight = CGRectGetHeight(contentRect) * 0.75;

	if(self.barcodeReaderViewShown) {
		barcodeReaderViewRect = contentRect;
		barcodeReaderViewRect.size.height = barcodeReaderViewHeight;

		rootViewRect.size.height = CGRectGetMaxY(rootViewRect) - CGRectGetMaxY(barcodeReaderViewRect);
		rootViewRect.origin.y = CGRectGetMaxY(barcodeReaderViewRect);
	} else {
		barcodeReaderViewRect = contentRect;
		barcodeReaderViewRect.size.height = 0.0;
	}
	
	// barcode reader shadow
	CGSize barcodeReaderShadowViewSize = [[self barcodeReaderShadowView]
		sizeThatFits:contentRect.size];
	CGRect barcodeReaderShadowViewRect = rootViewRect;
	barcodeReaderShadowViewRect.size.height = barcodeReaderShadowViewSize.height;
	
	self.barcodeReaderShadowView.alpha = self.barcodeReaderViewShown ? 1.0 : 0.0;

	self.searchBar.frame = navigationBarRect;
	self.rootViewController.view.frame = rootViewRect;
	self.barcodeReaderViewController.view.frame = barcodeReaderViewRect;
	self.barcodeReaderShadowView.frame = barcodeReaderShadowViewRect;*/
}

#pragma mark - Private

- (void)initBarcodeReaderShadowView {
	UIImage* image = [UIImage imageNamed:@"corkboard-navigationbar-shadow"];
	
	UIImageView* barcodeReaderShadowView = [[UIImageView alloc] initWithImage:image];
	barcodeReaderShadowView.alpha = 0.0;
	
	self.barcodeReaderShadowView = barcodeReaderShadowView;
	[[self view] insertSubview:barcodeReaderShadowView aboveSubview:[[self rootViewController] view]];
}

@end

#pragma mark - BarcodeReader

@implementation GRCGroceryPickerViewController(BarcodeReader)

- (void)presentBarcodeReaderViewController:(GRCBarcodeReaderViewController*)viewController animated:(BOOL)animated completion:(void (^)(void))completion {
/*	if(self.barcodeReaderViewController) { return; } // do nothing

	UIView* barcodeReaderView = viewController.view; // make sure the view is loaded
	self.barcodeReaderViewController = viewController;

	[self addChildViewController:viewController];
	[viewController beginAppearanceTransition:YES animated:animated];

	GRCGroceryPickerNavigationBar* searchBar = (id)self.searchBar;
	[searchBar pushNavigationItem:[viewController navigationItem] animated:NO];

	[[self view] setNeedsLayout];

	void (^animations)(void) = ^() {
		self.barcodeReaderViewShown = YES;

		[[searchBar searchBar] resignFirstResponder];
		[[self view] insertSubview:barcodeReaderView belowSubview:[self searchBar]];

		[searchBar setTranslucentStyle:YES animated:animated];

		[[self view] layoutIfNeeded];
	};

	void (^animationCompletion)(BOOL finished) = ^(BOOL finished) {
		[viewController endAppearanceTransition];
		[viewController didMoveToParentViewController:self];

		if(completion) { completion(); }
	};

	if(animated) {
		[UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0 options:0 animations:animations completion:animationCompletion];
	} else {
		animations();
		animationCompletion(YES);
	}*/
}

- (void)dismissBarcodeReaderViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
/*	if(!self.barcodeReaderViewController) { return; }

	GRCBarcodeReaderViewController* viewController = self.barcodeReaderViewController;
	[viewController willMoveToParentViewController:nil];

	GRCGroceryPickerNavigationBar* navigationBar = (id)self.searchBar;
	[navigationBar popNavigationItemAnimated:NO];

	[[self view] setNeedsLayout];

	void (^animations)(void) = ^() {
		self.barcodeReaderViewShown = NO;

		[navigationBar setTranslucentStyle:NO animated:animated];

		[[self view] layoutIfNeeded];
	};

	void (^animationCompletion)(BOOL finished) = ^(BOOL finished) {
		[[viewController view] removeFromSuperview];
		self.barcodeReaderViewController = nil;

		if(completion) { completion(); }
	};

	if(animated) {
		[UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0.0 options:0 animations:animations completion:animationCompletion];
	} else {
		animations();
		animationCompletion(YES);
	}*/
}

@end

@implementation GRCGroceryPickerNavigationBar

- (void)layoutSubviews {
	[super layoutSubviews];

	GRCGroceryPickerHeaderView* headerView = (id)self.topItem.titleView;
	if(![headerView isKindOfClass:[GRCGroceryPickerHeaderView class]]) { headerView = nil; }
	if(!headerView) { return;}

	headerView.frame = self.bounds;
}

@end