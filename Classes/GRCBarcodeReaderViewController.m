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

#import "GRCBarcodeReaderViewController.h"

#import "GRCBarcodeFormatter.h"

#import <AVFoundation/AVFoundation.h>

@interface GRCBarcodeReaderViewController()/*<ZBarReaderViewDelegate>*/

@property(nonatomic, strong) UIView* zbarReaderView;

@property(nonatomic, strong) AVAudioPlayer* barcodeDetectedSound;
@property(nonatomic, strong) AVAudioPlayer* barcodeUnknownSound;

@end

@implementation GRCBarcodeReaderViewController

#pragma mark - Construction & Destruction

- (id)init {
    if((self = [self initWithNibName:nil bundle:nil])) {
		self.title = NSLocalizedString(@"FINDBYBARCODE_NAVIGATIONITEM_TITLE", nil);
	}

    return self;
}

#pragma mark - GRCBarcodeReaderViewController

+ (BOOL)isBarcodeReaderAvailable {
	return NO; // [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//	[self loadZBarReaderView];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
//	[[self zbarReaderView] start];
	
	// self.title = self.zbarReaderView.device.localizedName;
}

- (void)viewDidDisappear:(BOOL)animated	{
	[super viewDidDisappear:animated];
//	[[self zbarReaderView] stop];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	CGRect contentRect = self.view.bounds;
	self.zbarReaderView.frame = contentRect;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	
	self.barcodeDetectedSound = self.barcodeUnknownSound = nil;
}

/*
#pragma mark - ZBarReaderViewDelegate

- (void)readerView:(ZBarReaderView*)readerView didReadSymbols:(ZBarSymbolSet*)symbols fromImage:(UIImage*)image {
	NSMutableArray* array = [NSMutableArray arrayWithCapacity:[symbols count]];
	
	for(ZBarSymbol* symbol in symbols) {
		NSDictionary* dictionary = @{
			@"string": symbol.data,
			@"type": @([self zBarSymbolTypeToBarcodeFormatterStyle:symbol.type]),
			@"typeString": symbol.typeName,
			@"quality": @(symbol.quality) };
		[array addObject:dictionary];
	}
	
	if([[self delegate] respondsToSelector:@selector(barcodeReaderView:didRecognizeSymbols:)]) {
		BOOL result = [[self delegate] barcodeReaderView:self didRecognizeSymbols:array];

		if(result) {
			[self loadBarcodeSoundsIfNeeded];
			[[self barcodeDetectedSound] play];
		}
	}
}

- (void)readerViewDidStart:(ZBarReaderView*)readerView {
}

- (void)readerView:(ZBarReaderView*)readerView didStopWithError:(NSError*)error {
	if(!error) { return; }
	NSLog(@"Barcode reader error: %@", error);
}

#pragma mark - Private

- (void)loadZBarReaderView {
	ZBarReaderView* zbarReaderView = [[ZBarReaderView alloc] init];
	
	[[zbarReaderView scanner] setSymbology:ZBAR_PDF417
		config:ZBAR_CFG_ENABLE
		to:0];
	[[zbarReaderView scanner] setSymbology:ZBAR_QRCODE
		config:ZBAR_CFG_ENABLE
		to:0];
	[[zbarReaderView scanner] setSymbology:ZBAR_CODE93
		config:ZBAR_CFG_ENABLE
		to:0];
	[[zbarReaderView scanner] setSymbology:ZBAR_CODE128
		config:ZBAR_CFG_ENABLE
		to:0];
		
	zbarReaderView.readerDelegate = self;

	// zbarReaderView.showsFPS = NO;
	zbarReaderView.trackingColor = [UIColor whiteColor];
	
	self.zbarReaderView = zbarReaderView;
	[[self view] addSubview:zbarReaderView];
}
*/

- (void)loadBarcodeSoundsIfNeeded {
	if(self.barcodeDetectedSound) { return; }
	
	[[AVAudioSession sharedInstance]
		setCategory:AVAudioSessionCategoryAmbient
		error:nil];
	
	NSURL* URL = [[NSBundle mainBundle] URLForResource:@"barcode-detected" withExtension:@"aif"];
	AVAudioPlayer* barcodeDetectedSound = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:nil];
	[barcodeDetectedSound prepareToPlay];
	self.barcodeDetectedSound = barcodeDetectedSound;
	
/*	URL = [[NSBundle mainBundle] URLForResource:@"barcode-unknown" withExtension:@"wav"];
	AVAudioPlayer* barcodeUnknownSound = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:nil];
	[barcodeUnknownSound prepareToPlay];
	self.barcodeUnknownSound = barcodeUnknownSound; */
}

/*
- (GRCBarcodeFormatterStyle)zBarSymbolTypeToBarcodeFormatterStyle:(zbar_symbol_type_t)type {
	if(type == ZBAR_EAN13) { return GRCBarcodeFormatterStyleEAN13; }
	if(type == ZBAR_EAN8) { return GRCBarcodeFormatterStyleEAN8; }
	if(type == ZBAR_EAN5) { return GRCBarcodeFormatterStyleEAN5; }
	if(type == ZBAR_EAN2) { return GRCBarcodeFormatterStyleEAN2; }
	
	if(type == ZBAR_ISBN10) { return GRCBarcodeFormatterStyleISBN10; }
	if(type == ZBAR_ISBN13) { return GRCBarcodeFormatterStyleISBN13; }
	
	if(type == ZBAR_UPCE) { return GRCBarcodeFormatterStyleUPCE; }
	if(type == ZBAR_UPCA) { return GRCBarcodeFormatterStyleUPCA; }
	
	if(type == ZBAR_COMPOSITE) { return GRCBarcodeFormatterStyleComposite; }

	return GRCBarcodeFormatterStyleNone;
}
*/

@end
