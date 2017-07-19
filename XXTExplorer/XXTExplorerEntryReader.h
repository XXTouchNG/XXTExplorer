//
//  XXTExplorerEntryReader.h
//  XXTExplorer
//
//  Created by Zheng on 12/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTExplorerEntryReader_h
#define XXTExplorerEntryReader_h

#import <UIKit/UIKit.h>

static NSString * const kXXTEFileTypeImageNameFormat = @"XXTEFileType-%@";

@protocol XXTExplorerEntryReader <NSObject>

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, copy, readonly) NSArray <NSString *> *displayMetaKeys;
@property (nonatomic, copy, readonly) NSDictionary <NSString *, id> *metaDictionary;

+ (UIImage *)defaultImage;
+ (NSArray <NSString *> *)supportedExtensions;
+ (Class)relatedEditor;
- (instancetype)initWithPath:(NSString *)filePath;

@property (nonatomic, assign, readonly) BOOL executable;
@property (nonatomic, assign, readonly) BOOL editable;

@property (nonatomic, copy, readonly)   NSString *entryName;
@property (nonatomic, copy, readonly)   NSString *entryDisplayName;
@property (nonatomic, strong, readonly) UIImage  *entryIconImage;
@property (nonatomic, copy, readonly)   NSString *entryDescription;
@property (nonatomic, copy, readonly)   NSString *entryExtensionDescription;
@property (nonatomic, copy, readonly)   NSString *entryViewerDescription;

@end

#endif /* XXTExplorerEntryReader_h */
