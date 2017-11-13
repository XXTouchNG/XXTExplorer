//
//  XXTExplorerEntryReader.h
//  XXTExplorer
//
//  Created by Zheng on 13/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    XXTExplorerEntryReaderEncryptionTypeNone = 0,
    XXTExplorerEntryReaderEncryptionTypeLocal = 1,
    XXTExplorerEntryReaderEncryptionTypeRemote = 2,
} XXTExplorerEntryReaderEncryptionType;

static NSString * const kXXTEFileTypeImageNameFormat = @"XXTEFileType-%@";

@interface XXTExplorerEntryReader : NSObject

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, copy, readonly) NSArray <NSString *> *metaKeys;
@property (nonatomic, copy, readonly) NSDictionary <NSString *, id> *metaDictionary;

+ (UIImage *)defaultImage;
+ (NSArray <NSString *> *)supportedExtensions;
+ (Class)relatedEditor;
- (instancetype)initWithPath:(NSString *)filePath;

@property (nonatomic, assign, readonly) BOOL executable;
@property (nonatomic, assign, readonly) BOOL editable;
@property (nonatomic, assign, readonly) XXTExplorerEntryReaderEncryptionType encryptionType;
@property (nonatomic, copy, readonly)   NSString *encryptionExtension;

@property (nonatomic, copy, readonly)   NSString *entryName;
@property (nonatomic, copy, readonly)   NSString *entryDisplayName;
@property (nonatomic, strong, readonly) UIImage  *entryIconImage;
@property (nonatomic, copy, readonly)   NSString *entryDescription;
@property (nonatomic, copy, readonly)   NSString *entryExtensionDescription;
@property (nonatomic, copy, readonly)   NSString *entryViewerDescription;

@property (nonatomic, assign, readonly) BOOL configurable;
@property (nonatomic, copy, readonly) NSString *configurationName;

@end
