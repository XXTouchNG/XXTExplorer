//
//  XXTPickerSnippet.h
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XUI/XUIAdapter.h>


@protocol XUIAdapter;

@interface XXTPickerSnippet : NSObject

@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *output;
@property (nonatomic, strong, readonly) id <XUIAdapter> adapter;
@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *flags;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithContentsOfFile:(NSString *)path Error:(NSError **)errorPtr;
- (instancetype)initWithContentsOfFile:(NSString *)path Adapter:(id <XUIAdapter>)adapter Error:(NSError **)errorPtr;

- (id)generateWithResults:(NSArray *)results Error:(NSError **)error;

@end
