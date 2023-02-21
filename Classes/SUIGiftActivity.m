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

#import "SUIGiftActivity.h"

@implementation SUIGiftActivity

NSString* const SUIGiftActivityTitleLocalizationKey = @"com.sophiestication.activity.giftApplication.title";

#pragma mark - Construction & Destruction

- (id)initWithApplicationIdentifier:(NSString*)applicationIdentifier {
	if((self = [super init])) {
		self.applicationIdentifier = applicationIdentifier;
	}
	
	return self;
}

#pragma mark - UIActivity

- (NSString*)activityType {
	return @"com.sophiestication.activity.giftApplication";
}

- (NSString*)activityTitle {
	NSString* applicationTitle = [[[NSBundle
		mainBundle]
		localizedInfoDictionary]
       objectForKey:@"CFBundleDisplayName"];
	
	NSString* activityTitle = [NSString stringWithFormat:
		NSLocalizedString(SUIGiftActivityTitleLocalizationKey, nil),
		applicationTitle];
	
	return activityTitle;
}

- (UIImage*)activityImage {
	return [UIImage imageNamed:@"activity-giftapplication"];
}

- (BOOL)canPerformWithActivityItems:(NSArray*)activityItems {
	if(![[UIApplication sharedApplication] canOpenURL:[self applicationGiftURL]]) { return NO; }

	NSString* localizedTitle = NSLocalizedString(SUIGiftActivityTitleLocalizationKey, nil);
	if([localizedTitle isEqualToString:SUIGiftActivityTitleLocalizationKey]) { return NO; }

	return YES;
}

- (void)performActivity {
	NSURL* URL = [self applicationGiftURL];
	BOOL result = [[UIApplication sharedApplication] openURL:URL];
	[self activityDidFinish:result];
}

#pragma mark - Private

- (NSURL*)applicationGiftURL {
	NSString* URLString = [NSString stringWithFormat:
		@"itms-appss://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/giftSongsWizard?gift=1&salableAdamId=%@&productType=C&pricingParameter=STDQ",
		[self applicationIdentifier]];
	return [NSURL URLWithString:URLString];
}

@end
