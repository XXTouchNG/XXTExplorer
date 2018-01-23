//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XXTEJSONHelper;
@class XXTEJSONPackage;

@protocol XXTEJSONHelperDelegate <NSObject>

- (void)jsonHelperDidSyncReady:(XXTEJSONHelper *)helper;
- (void)jsonHelper:(XXTEJSONHelper *)helper didSyncFailWithError:(NSError *)error;

@end

@interface XXTEJSONHelper : NSObject

@property (nonatomic, weak) id <XXTEJSONHelperDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *repositoryURL;
- (instancetype)initWithRepositoryURL:(NSURL *)repositoryURL;
- (void)sync;

@property (nonatomic, strong) XXTEJSONPackage *respPackage;

@end
