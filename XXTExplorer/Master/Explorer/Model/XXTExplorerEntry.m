//
//  XXTExplorerEntry.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/3/2.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "XXTExplorerEntry.h"
#import "XXTExplorerEntryReader.h"

#import "XXTEAppDefines.h"
#import "XXTExplorerEntryService.h"

NSString * const EntryTypeUnsupported = @"EntryTypeUnsupported";
NSString * const EntryTypeRegular = @"EntryTypeRegular";
NSString * const EntryTypeDirectory = @"EntryTypeDirectory";
NSString * const EntryTypeSymlink = @"EntryTypeSymlink";

NSString * const EntryMaskTypeUnsupported = EntryTypeUnsupported;
NSString * const EntryMaskTypeRegular = EntryTypeRegular;
NSString * const EntryMaskTypeDirectory = EntryTypeDirectory;
NSString * const EntryMaskTypeSymlink = EntryTypeSymlink;
NSString * const EntryMaskTypeBundle = @"EntryMaskTypeBundle";
NSString * const EntryMaskTypeBrokenSymlink = @"EntryMaskTypeBrokenSymlink";

@implementation XXTExplorerEntry

+ (NSString *)sortField2AttributeName:(XXTExplorerViewEntryListSortField)field {
    switch (field) {
        case XXTExplorerViewEntryListSortFieldCreationDate:
            return @"creationDate";
            break;
        case XXTExplorerViewEntryListSortFieldModificationDate:
            return @"modificationDate";
            break;
        case XXTExplorerViewEntryListSortFieldDisplayName:
            return @"displayName";
            break;
        case XXTExplorerViewEntryListSortFieldItemType:
            return @"entryExtension";
            break;
        case XXTExplorerViewEntryListSortFieldItemSize:
            return @"entrySize";
            break;
        default:
            break;
    }
    return @"modificationDate";
}

- (NSString *)entryName {
    return [self.entryPath lastPathComponent];
}

- (NSString *)entryExtension {
    return [[self.entryPath pathExtension] lowercaseString];
}

#pragma mark - Display Icon Image

- (UIImage *)displayIconImage {
    if (self.entryReader.entryIconImage) {
        return self.entryReader.entryIconImage;
    }
    return self.iconImage;
}

- (UIImage *)localizedDisplayIconImage {
    if (self.entryReader.entryIconImage) {
        return self.entryReader.entryIconImage;
    }
    // external processing
    return self.iconImage;
}

#pragma mark - Display Name

- (NSString *)displayName {
    if (self.entryReader.entryDisplayName) {
        return self.entryReader.entryDisplayName;
    }
    if (self.entryReader.entryName) {
        return self.entryReader.entryName;
    }
    return self.entryName;
}

- (NSString *)localizedDisplayName {
    if (self.entryReader.entryDisplayName) {
        return self.entryReader.entryDisplayName;
    }
    if (self.entryReader.entryName) {
        return self.entryReader.entryName;
    }
    BOOL hideNameExtension =
    XXTEDefaultsBool(XXTExplorerViewEntryHideCommonFileExtensionsEnabledKey, YES);
    if (hideNameExtension)
    {
        NSString *nameExtension =
        [self.entryName pathExtension];
        BOOL isKnownExtension =
        [[XXTExplorerEntryService sharedInstance] isRegisteredExtension:nameExtension];
        if (isKnownExtension) {
            return [self.entryName stringByDeletingPathExtension];
        }
    }
    return self.entryName;
}

#pragma mark - Type Getters

- (BOOL)isUnsupported {
    return ([self.entryType isEqualToString:EntryTypeUnsupported]);
}

- (BOOL)isRegular {
    return ([self.entryType isEqualToString:EntryTypeRegular]);
}

- (BOOL)isMaskedRegular {
    return ([self.entryMaskType isEqualToString:EntryTypeRegular]);
}

- (BOOL)isDirectory {
    return ([self.entryType isEqualToString:EntryTypeDirectory]);
}

- (BOOL)isMaskedDirectory {
    return ([self.entryMaskType isEqualToString:EntryMaskTypeDirectory]);
}

- (BOOL)isSymlink {
    return ([self.entryType isEqualToString:EntryTypeSymlink]);
}

- (BOOL)isBundle {
    return ([self.entryType isEqualToString:EntryTypeDirectory] &&
            [self.entryMaskType isEqualToString:EntryMaskTypeBundle]);
}

- (BOOL)isBrokenSymlink {
    return ([self.entryType isEqualToString:EntryTypeSymlink] &&
            [self.entryMaskType isEqualToString:EntryMaskTypeBrokenSymlink]);
}

#pragma mark - Localized Date

+ (NSDateFormatter *)entryDateFormatter {
    static NSDateFormatter *entryDateFormatter = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!entryDateFormatter) {
            entryDateFormatter = ({
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                dateFormatter;
            });
        }
    });
    return entryDateFormatter;
}

- (NSString *)localizedStringOfCreationDate {
    if (!self.creationDate) return nil;
    return [[[self class] entryDateFormatter] stringFromDate:self.creationDate];
}

- (NSString *)localizedStringOfModificationDate {
    if (!self.modificationDate) return nil;
    return [[[self class] entryDateFormatter] stringFromDate:self.modificationDate];
}

#pragma mark - Localized Size

- (NSString *)localizedStringOfEntrySize {
    if (!self.entrySize) return nil;
    NSInteger byteCount = [self.entrySize integerValue];
    NSString *readableSize = [NSByteCountFormatter stringFromByteCount:byteCount countStyle:NSByteCountFormatterCountStyleFile];
    return readableSize;
}

#pragma mark - Localized Description

- (NSString *)localizedDescription {
    if (self.entryReader.entryDescription) {
        return self.entryReader.entryDescription;
    }
    if (self.entryDescription) {
        return self.entryDescription;
    }
    return [self localizedStringOfModificationDate];
}

@end
