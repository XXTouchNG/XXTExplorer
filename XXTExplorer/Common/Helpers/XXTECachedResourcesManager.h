//
//  XXTECachedResourcesManager.h
//  XXTExplorer
//
//  Created by Darwin on 8/29/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XXTECachedResourcesManager : NSObject

@property (nonatomic, strong, readonly) NSFileManager *fileManager;

+ (instancetype)sharedManager;
- (NSString *)dateCachesPathAtCachesPath:(NSString *)resourcesPath;
- (void)cleanOutdatedManagedResourcesAtCachesPath:(NSString *)resourcesPath limitType:(NSInteger)type;

@end

NS_ASSUME_NONNULL_END
