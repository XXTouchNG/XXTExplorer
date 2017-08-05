//
//  XXTEPackageExtractor.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/5.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XXTEPackageExtractor;

@protocol XXTEPackageExtractorDelegate <NSObject>

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFinishFetchingMetaData:(NSData *)metaData;
- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFailFetchingMetaDataWithError:(NSError *)error;

- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFinishInstalling:(NSString *)outputLog;
- (void)packageExtractor:(XXTEPackageExtractor *)extractor didFailInstallingWithError:(NSError *)error;

@end

@interface XXTEPackageExtractor : NSObject

@property (nonatomic, weak) id <XXTEPackageExtractorDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *packagePath;
- (instancetype)initWithPath:(NSString *)path;

- (void)extractMetaData;
- (void)installPackage;

@end
