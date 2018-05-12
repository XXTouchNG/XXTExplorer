//
// Created by Zheng on 09/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XXTEUpdateHelper;
@class XXTEUpdatePackage;

@protocol XXTEUpdateHelperDelegate <NSObject>

- (void)jsonHelperDidSyncReady:(XXTEUpdateHelper *)helper;
- (void)jsonHelper:(XXTEUpdateHelper *)helper didSyncFailWithError:(NSError *)error;

@end

@interface XXTEUpdateHelper : NSObject

@property (nonatomic, weak) id <XXTEUpdateHelperDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *repositoryURL;
- (instancetype)initWithRepositoryURL:(NSURL *)repositoryURL;
- (void)sync;

@property (nonatomic, strong) XXTEUpdatePackage *respPackage;
@property (nonatomic, strong, readonly) NSString *temporarilyLocation;

@end
