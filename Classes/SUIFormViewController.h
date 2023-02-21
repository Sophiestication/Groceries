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

NSString* const SUIFormViewControllerObjectKey;
NSString* const SUIFormViewControllerPropertyKey;
NSString* const SUIFormViewControllerDisplayPropertyKey;
NSString* const SUIFormViewControllerPlaceholderKey;
NSString* const SUIFormViewControllerMandatoryKey;
NSString* const SUIFormViewControllerUserInfoKey;
NSString *const SUIFormViewControllerAutoCapitalizationTypeKey;
NSString *const SUIFormViewControllerAutoCorrectionTypeKey;

@protocol SUIFormViewControllerDelegate;

@interface SUIFormViewController : UITableViewController

+ (id)viewController;

@property(nonatomic, weak) id<SUIFormViewControllerDelegate> delegate;
@property(nonatomic, strong) NSArray* fields;

@end

@protocol SUIFormViewControllerDelegate<NSObject>

@optional
- (void)formController:(SUIFormViewController*)controller didFinishEditingField:(NSDictionary*)field;

- (void)formControllerDidSave:(SUIFormViewController*)controller;
- (void)formControllerDidCancel:(SUIFormViewController*)controller;

@end
