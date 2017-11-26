//
//  XXTEXPAPackageExtractor.h
//  XXTExplorer
//
//  Created by Zheng on 26/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XXTEXPAPackageExtractor;

@protocol XXTEXPAPackageExtractorDelegate <NSObject>

- (void)packageExtractor:(XXTEXPAPackageExtractor *)extractor didFinishFetchingMetaData:(NSData *)metaData;
- (void)packageExtractor:(XXTEXPAPackageExtractor *)extractor didFailFetchingMetaDataWithError:(NSError *)error;

@end

@interface XXTEXPAPackageExtractor : NSObject

@property (nonatomic, assign) BOOL busyOperationProgressFlag;
@property (nonatomic, weak) id <XXTEXPAPackageExtractorDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *packagePath;
@property (nonatomic, strong, readonly) NSString *metaPath;
- (instancetype)initWithPath:(NSString *)path;

- (void)extractMetaData;

@end

