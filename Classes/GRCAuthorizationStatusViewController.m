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

#import "GRCAuthorizationStatusViewController.h"

@interface GRCAuthorizationStatusViewController()

@property(nonatomic, strong) UIImageView* backgroundView;

@property(nonatomic, strong) UIImageView* imageView;

@property(nonatomic, strong) UILabel* textLabel;
@property(nonatomic, strong) UILabel* detailTextLabel;

@end

@implementation GRCAuthorizationStatusViewController

#pragma mark - Construction & Destruction

+ (instancetype)viewController {
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    }

    return self;
}

#pragma mark - GRCAuthorizationStatusViewController

- (void)presentContentViewAnimated:(BOOL)animated {
	UIScrollView* scrollView = (id)self.view;
	CGSize contentSize = scrollView.contentSize;
	
	CGFloat insetHeight = contentSize.height / 3.0;
	UIEdgeInsets contentInset = UIEdgeInsetsMake(-insetHeight, 0.0, -insetHeight, 0.0);
	
	if(animated) {
		[UIView
			animateWithDuration:1.0
			delay:0.2
			options:UIViewAnimationOptionLayoutSubviews
			animations:^() { scrollView.contentInset = contentInset; }
			completion:nil];
	} else {
		scrollView.contentInset = contentInset;
	}
}

#pragma mark - UIViewController

- (void)loadView {
	UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
	
	scrollView.alwaysBounceVertical = YES;
	scrollView.showsVerticalScrollIndicator = NO;
	
	self.view = scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self loadBackgroundView];
	[self loadContentViews];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	
	UIScrollView* scrollView = (id)self.view;
	CGSize contentSize = scrollView.contentSize;
	
	if(!CGSizeEqualToSize(contentSize, CGSizeZero)) { return; }
	
	// background view
	CGRect contentRect = scrollView.frame;
	contentSize = CGSizeMake(CGRectGetWidth(contentRect), CGRectGetHeight(contentRect) * 3.0);
	scrollView.contentSize = contentSize;
	
	self.backgroundView.frame = CGRectMake(0.0, 0.0, contentSize.width, contentSize.height);
	
	// image view
	CGRect imageViewRect = self.imageView.bounds;
	imageViewRect.origin = CGPointMake(
		contentSize.width * 0.5 - CGRectGetWidth(imageViewRect) * 0.5,
		contentSize.height * 0.5 - CGRectGetHeight(imageViewRect) * 0.5 - 60.0);
	self.imageView.frame = CGRectIntegral(imageViewRect);
	
	// text label
	contentRect = self.backgroundView.frame;
	contentRect = CGRectInset(contentRect, 10.0, 0.0);
	
	CGSize textLabelSize = [[self textLabel]
		sizeThatFits:contentRect.size];
	CGRect textLabelRect = CGRectMake(
		CGRectGetMidX(contentRect) - textLabelSize.width * 0.5,
		CGRectGetMaxY(imageViewRect) + 5.0,
		textLabelSize.width,
		textLabelSize.height);
	self.textLabel.frame = textLabelRect;
	
	// detail text label
	CGSize detailTextLabelSize = [[self detailTextLabel]
		sizeThatFits:contentRect.size];
	CGRect detailTextLabelRect = CGRectMake(
		CGRectGetMidX(contentRect) - detailTextLabelSize.width * 0.5,
		CGRectGetMaxY(textLabelRect) + 1.0,
		detailTextLabelSize.width,
		detailTextLabelSize.height);
	self.detailTextLabel.frame = detailTextLabelRect;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self presentContentViewAnimated:YES];
}

#pragma mark - Private

- (void)loadBackgroundView {
	UIImage* backgroundImage = [[UIImage imageNamed:@"cork"]
		resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
		resizingMode:UIImageResizingModeTile];

	UIImageView* backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
	
	self.backgroundView = backgroundView;
	[[self view] addSubview:backgroundView];
}

- (void)loadContentViews {
	// reminders image view
	UIImage* remindersImage = [UIImage imageNamed:@"corkboard-reminders"];
	UIImageView* remindersImageView = [[UIImageView alloc] initWithImage:remindersImage];
	
	self.imageView = remindersImageView;
	[[self view] insertSubview:remindersImageView aboveSubview:[self backgroundView]];
	
	// text label
	UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	textLabel.text = NSLocalizedString(@"AUTHORIZATIONSTATUS_DENIED_LABEL", nil);
	
	textLabel.font = [UIFont boldSystemFontOfSize:17.0];
	
	textLabel.textColor = [UIColor whiteColor];
	textLabel.textAlignment = NSTextAlignmentCenter;
	
	textLabel.layer.shadowOpacity = 1.0;
	textLabel.layer.shadowOffset = CGSizeMake(0.0, 1.0);
	textLabel.layer.shadowRadius = 1.5;
	
	textLabel.backgroundColor = [UIColor clearColor];
	
	self.textLabel = textLabel;
	[[self view] insertSubview:textLabel aboveSubview:remindersImageView];
	
	// detail text label
	UILabel* detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	
	detailTextLabel.text = NSLocalizedString(@"AUTHORIZATIONSTATUS_DENIED_DETAILLABEL", nil);
	
	detailTextLabel.font = [UIFont boldSystemFontOfSize:15.0];
	
	detailTextLabel.textColor = textLabel.textColor;
	detailTextLabel.textAlignment = textLabel.textAlignment;
	
	detailTextLabel.layer.shadowOpacity = textLabel.layer.shadowOpacity;
	detailTextLabel.layer.shadowOffset = textLabel.layer.shadowOffset;
	detailTextLabel.layer.shadowRadius = textLabel.layer.shadowRadius;
	
	detailTextLabel.backgroundColor = textLabel.backgroundColor;
	
	detailTextLabel.numberOfLines = NSIntegerMax;
	
	self.detailTextLabel = detailTextLabel;
	[[self view] insertSubview:detailTextLabel aboveSubview:remindersImageView];
}

@end
