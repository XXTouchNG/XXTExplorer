//
//  XXTExplorerEntry.h
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/3/2.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTExplorerDefaults.h"

typedef NSString * XXTExplorerEntryType;
typedef NSString * XXTExplorerEntryMaskType;

extern NSString * const EntryTypeUnsupported;
extern NSString * const EntryTypeRegular;
extern NSString * const EntryTypeDirectory;
extern NSString * const EntryTypeSymlink;

extern NSString * const EntryMaskTypeUnsupported;
extern NSString * const EntryMaskTypeRegular;
extern NSString * const EntryMaskTypeDirectory;
extern NSString * const EntryMaskTypeSymlink;
extern NSString * const EntryMaskTypeBundle;
extern NSString * const EntryMaskTypeBrokenSymlink;

@class XXTExplorerEntryReader;

@interface XXTExplorerEntry : NSObject

+ (NSString *)sortField2AttributeName:(XXTExplorerViewEntryListSortField)field;

@property (nonatomic, strong) UIImage *iconImage; // default image
@property (nonatomic, copy) NSString *entryPath;
//@property (nonatomic, copy) NSString *entryRealPath;
@property (nonatomic, copy, readonly) NSString *entryName;
@property (nonatomic, copy, readonly) NSString *entryExtension;
@property (nonatomic, copy) XXTExplorerEntryType entryType;
@property (nonatomic, copy) XXTExplorerEntryMaskType entryMaskType;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *modificationDate;
@property (nonatomic, strong) NSNumber *entrySize;
@property (nonatomic, strong) XXTExplorerEntryReader *entryReader;
@property (nonatomic, copy) NSString *entryDescription;

#pragma mark - Display Icon Image

- (UIImage *)displayIconImage;
- (UIImage *)localizedDisplayIconImage;

#pragma mark - Display Name

- (NSString *)displayName;
- (NSString *)localizedDisplayName;

#pragma mark - Type Getters

- (BOOL)isUnsupported;
- (BOOL)isRegular;
- (BOOL)isMaskedRegular;
- (BOOL)isDirectory;
- (BOOL)isMaskedDirectory;
- (BOOL)isSymlink;

- (BOOL)isBundle;
- (BOOL)isBrokenSymlink;

#pragma mark - Localized Date

- (NSString *)localizedStringOfCreationDate;
- (NSString *)localizedStringOfModificationDate;

#pragma mark - Localized Size

- (NSString *)localizedStringOfEntrySize;

#pragma mark - Localized Description

- (NSString *)localizedDescription;

@end
