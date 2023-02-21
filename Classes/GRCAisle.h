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

#import <Foundation/Foundation.h>

@class GRCShoppingListStore;

NSString* const GRCAisleImageNameGeneric;

NSUInteger const GRCAisleInvalidDatabaseIdentifier;

@interface GRCAisle : NSObject<NSCoding>

@property(nonatomic, copy) NSString* aisleIdentifier;
@property(nonatomic) NSUInteger aisleDatabaseIdentifier;

@property(nonatomic, copy) NSString* customTitle;
@property(nonatomic, copy) NSString* image;

@property(nonatomic, getter=isCustom) BOOL custom;

@property(nonatomic) NSInteger sortOrder;

@end

@interface GRCAisle(Serialization)

- (id)initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*)dictionaryRepresentation;

@end

@interface GRCAisle(StandardAisles)

+ (NSArray*)standardAisles;

@end
