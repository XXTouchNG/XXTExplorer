//
//  XXTEPackageExtractor.h
//  XXTExplorer
//
//  Created by Zheng on 2018/4/12.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XXTEPackageExtractorDelegate;

@protocol XXTEPackageExtractor <NSObject>

@property (nonatomic, weak) id <XXTEPackageExtractorDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *packagePath;
- (instancetype)initWithPath:(NSString *)path;

- (void)extractMetaData;
- (void)installPackage;

@optional
- (void)killBackboardd;

@end

@protocol XXTEPackageExtractorDelegate <NSObject>

- (void)packageExtractor:(id <XXTEPackageExtractor>)extractor didFinishFetchingMetaData:(NSData *)metaData;
- (void)packageExtractor:(id <XXTEPackageExtractor>)extractor didFailFetchingMetaDataWithError:(NSError *)error;

- (void)packageExtractor:(id <XXTEPackageExtractor>)extractor didFinishInstallation:(NSString *)outputLog;
- (void)packageExtractor:(id <XXTEPackageExtractor>)extractor didFailInstallationWithError:(NSError *)error;

@end
