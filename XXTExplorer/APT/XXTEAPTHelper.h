//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XXTEAPTHelper;
@class XXTEAPTPackage;

@protocol XXTEAPTHelperDelegate <NSObject>

- (void)aptHelperDidSyncReady:(XXTEAPTHelper *)helper;

@end

@interface XXTEAPTHelper : NSObject

@property (nonatomic, weak) id <XXTEAPTHelperDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *repositoryURL;
- (instancetype)initWithRepositoryURL:(NSURL *)repositoryURL;
- (void)sync;

@property (nonatomic, strong, readonly) NSDictionary <NSString *, XXTEAPTPackage *> *packageMap;

@end