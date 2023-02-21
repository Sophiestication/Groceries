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

#import "GRCAisleImagePickerViewController.h"

#import "GRCAisleImageCollectionViewCell.h"
#import "UIImage+Aisle.h"

@interface GRCAisleImagePickerViewController()

@property(nonatomic, strong) NSArray* images;

@end

@implementation GRCAisleImagePickerViewController

#pragma mark - Construction & Destruction

+ (instancetype)viewController {
	UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];
	return [[self alloc] initWithCollectionViewLayout:layout];
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout	{
	if((self = [super initWithCollectionViewLayout:layout])) {
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
			self.navigationItem.prompt = NSLocalizedString(@"AISLEIMAGE_PICKER_NAVIGATIONITEM_PROMPT", @"");
		} else {
			self.navigationItem.title = NSLocalizedString(@"AISLEIMAGE_PICKER_NAVIGATIONITEM_PROMPT", @"");
		}
	}

	return self;
}

#pragma mark - GRCAisleImagePickerViewController

- (IBAction)selectImage:(id)sender {
	if([[self delegate] respondsToSelector:@selector(aisleImagePicker:didFinishPickingImage:)]) {
		[[self delegate] aisleImagePicker:self didFinishPickingImage:[self selectedImage]];
	}
}

- (IBAction)cancel:(id)sender {
	if([[self delegate] respondsToSelector:@selector(aisleImagePickerDidCancel:)]) {
		[[self delegate] aisleImagePickerDidCancel:self];
	}
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	}
	
	// background view
	UITableView* backgroundView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	backgroundView.userInteractionEnabled = NO;
	self.collectionView.backgroundView = backgroundView;
	
	// configure the flow layout
	UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	
	layout.itemSize = CGSizeMake(56.0, 48.0);

	CGFloat margin = 15.0;

	layout.minimumLineSpacing = margin;
	layout.minimumInteritemSpacing = margin;

	layout.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
	
	// collection view
	[[self collectionView]
		registerClass:[GRCAisleImageCollectionViewCell class]
		forCellWithReuseIdentifier:[[self class] regularCellReuseIdentifier]];
	
	// create a button for each image
	self.images = [[self class] imageNames];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	// scroll to selected image
	NSIndexPath* indexPath = [self indexPathForImage:[self selectedImage]];

	if(indexPath) {
		[[self collectionView] selectItemAtIndexPath:indexPath animated:animated scrollPosition:UICollectionViewScrollPositionCenteredVertically|UICollectionViewScrollPositionCenteredHorizontally];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[self collectionView] flashScrollIndicators];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.images.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
	GRCAisleImageCollectionViewCell* cell = [collectionView
		dequeueReusableCellWithReuseIdentifier:[[self class] regularCellReuseIdentifier]
		forIndexPath:indexPath];
		
	NSString* imageName = [self imageForRowAtIndexPath:indexPath];
	
	UIImage* image = [UIImage aisleImageNamed:imageName size:32 style:nil];
	cell.aisleImage = image;
	
	cell.selected = [[self selectedImage] isEqualToString:imageName];
	
	return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
	self.selectedImage = [self imageForRowAtIndexPath:indexPath];
	[self selectImage:collectionView];
}

#pragma mark - Private

+ (NSString*)regularCellReuseIdentifier { return @"regular"; }

+ (NSArray*)imageNames {
	return @[
		@"generic",
		@"tea",
		@"coffee",
		@"candy",
		@"frozentreats",
		@"cheese",
		@"beef",
		@"poultry",
		@"sale",
		@"gift",
		@"electronics",
		@"filmroll",
		@"clothing",
		@"tie",
		@"briefcase",
		@"travel",
		@"entertainment2",
		@"services",
		@"gas",
		@"spraycan",
		@"beaker",
		@"skull",
		@"pharmacy",
		@"medical",
		@"healthy",
		@"emergency",
		@"alcohol",
		@"beauty",
		@"beverages",
		@"bread",
		@"breakfast",
		@"brezel",
		@"can",
		@"dairy",
		@"deli",
		@"dressings",
		@"entertainment",
		@"frozen",
		@"garden",
		@"infant",
		@"laundry",
		@"meat",
		@"muffin",
		@"natural",
		@"office",
		@"pasta",
		@"pet",
		@"prepared",
		@"produce",
		@"seafood",
		@"spices",
		@"world" ];
}

- (NSIndexPath*)indexPathForImage:(NSString*)imageName {
	NSUInteger imageIndex = [[self images] indexOfObject:imageName];

	if(imageIndex == NSNotFound) { return nil; }

	return [NSIndexPath indexPathForItem:imageIndex inSection:0];
}

- (NSString*)imageForRowAtIndexPath:(NSIndexPath*)indexPath {
	return [[self images] objectAtIndex:[indexPath row]];
}

@end
