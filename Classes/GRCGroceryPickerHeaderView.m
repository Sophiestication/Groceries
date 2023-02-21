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

#import "GRCGroceryPickerHeaderView.h"

#import "UIColor+Tint.h"

@interface GRCGroceryPickerHeaderView()

@property(nonatomic, readwrite, strong) UIButton* insertAccessoryView;
@property(nonatomic, readwrite, strong) UISearchBar* searchBar;
@property(nonatomic, strong) UIButton* doneButton;

@end

@implementation GRCGroceryPickerHeaderView

#pragma mark - Construction & Destruction

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		[self initIvars];
		[self initSearchBar];
		[self initInsertAccessoryView];
		[self initDoneButton];
    }

    return self;
}

#pragma mark GRCGroceryPickerHeaderView

- (void)selectSearchText:(id)sender showMenu:(BOOL)showMenu {
	UITextField* textfield = [[self searchBar] valueForKeyPath:@"searchField"];
	
	if(textfield) {
		UIMenuController* menuController = [UIMenuController sharedMenuController];
		BOOL menuWasVisible = menuController.menuVisible;
		
		[textfield selectAll:sender];
		
		// make sure the menu never gets visible
		if(!menuWasVisible && !showMenu) {
			[self hideMenuIfNeeded];
			[self performSelector:@selector(hideMenuIfNeeded) withObject:nil afterDelay:0.2];
		}
	}
}

#pragma mark - UIView

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(size.width, 44.0); // fixed height
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect contentRect = self.bounds;
	CGFloat const margin = 12.0;
	
	CGSize insertAccessoryButtonSize = [[self insertAccessoryView]
		sizeThatFits:contentRect.size];
	insertAccessoryButtonSize.height = CGRectGetHeight(contentRect);
	
	CGRect insertAccessoryButtonRect = CGRectMake(
		CGRectGetMinX(contentRect) + margin,
		round(CGRectGetMidY(contentRect) - insertAccessoryButtonSize.height * 0.5 + 1.0),
		insertAccessoryButtonSize.width,
		insertAccessoryButtonSize.height);
	self.insertAccessoryView.frame = insertAccessoryButtonRect;
	
	CGSize doneButtonSize = [[self doneButton]
		sizeThatFits:contentRect.size];
	doneButtonSize.width = MAX(doneButtonSize.width, 60.0);
		
	CGRect doneButtonRect = CGRectMake(
		CGRectGetMaxX(contentRect) - doneButtonSize.width,
		round(CGRectGetMidY(contentRect) - doneButtonSize.height * 0.5),
		doneButtonSize.width,
		doneButtonSize.height);
	self.doneButton.frame = doneButtonRect;
	
	CGRect searchBarRect = contentRect;
	searchBarRect.origin.x = CGRectGetMaxX(insertAccessoryButtonRect) + 5.0;
	searchBarRect.size.width = (CGRectGetMinX(doneButtonRect) - CGRectGetMinX(searchBarRect));
	self.searchBar.frame = searchBarRect;
}

#pragma mark - Private

- (void)initIvars {
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (void)initSearchBar {
	UISearchBar* searchBar = [[UISearchBar alloc] initWithFrame:[self bounds]];
	
	searchBar.showsCancelButton = NO;
	searchBar.searchBarStyle = UISearchBarStyleMinimal;

	if(YES /*|| [[UIScreen mainScreen] scale] > 1.0*/) {
		UIOffset offset = UIOffsetMake(0.0, 1.0);
	
		[searchBar setPositionAdjustment:offset forSearchBarIcon:UISearchBarIconSearch];
		[searchBar setPositionAdjustment:offset forSearchBarIcon:UISearchBarIconClear];
		[searchBar setPositionAdjustment:offset forSearchBarIcon:UISearchBarIconResultsList];
	
		searchBar.searchTextPositionAdjustment = offset;
	}
	
	searchBar.translatesAutoresizingMaskIntoConstraints = NO;
	
	self.searchBar = searchBar;
	[self addSubview:searchBar];
}

- (void)initInsertAccessoryView {
	UIButton* insertAccessoryView = [UIButton buttonWithType:UIButtonTypeContactAdd];
	
	// insertAccessoryView.tintColor = [UIColor greenTintColor];
	// insertAccessoryView.selected = YES;
	
	insertAccessoryView.translatesAutoresizingMaskIntoConstraints = NO;
	
	self.insertAccessoryView = insertAccessoryView;
	[self insertSubview:insertAccessoryView aboveSubview:[self searchBar]];
}

- (void)initDoneButton {
	UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
	
	[doneButton addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
	
	[doneButton setTitle:NSLocalizedString(@"DONE_BUTTONITEM", nil) forState:UIControlStateNormal];
	
	doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
	
	doneButton.translatesAutoresizingMaskIntoConstraints = NO;
	
	self.doneButton = doneButton;
	[self addSubview:doneButton];
}

- (void)done:(id)sender {
	UISearchBar* searchBar = self.searchBar;
	
	if([[searchBar delegate] respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
		// delay the call to prevent a possible and rather weird crash if the delegate dismisses the current view controller
		[(NSObject*)[searchBar delegate] performSelector:@selector(searchBarCancelButtonClicked:) withObject:searchBar afterDelay:0.0];
	}
}

- (void)hideMenuIfNeeded {
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:NO];
}

@end
