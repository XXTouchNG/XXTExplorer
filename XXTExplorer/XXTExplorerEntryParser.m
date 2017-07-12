//
//  XXTExplorerEntryParser.m
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerDefaults.h"

static NSString * const kXXTEFileTypeImageNameFormat = @"XXTEFileType-%@";

@interface XXTExplorerEntryParser ()
@property (nonatomic, strong, readonly) NSFileManager *parserFileManager;

@end

@implementation XXTExplorerEntryParser {
    
}

//+ (instancetype)sharedParser {
//    static XXTExplorerEntryParser *parser = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        parser = [[XXTExplorerEntryParser alloc] init];
//    });
//    return parser;
//}

- (instancetype)init {
    if (self = [super init]) {
        _parserFileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (NSDictionary *)entryOfPath:(NSString *)entrySubdirectoryPath withError:(NSError *__autoreleasing *)error {
    NSError *localError = nil;
    NSDictionary <NSString *, id> *entrySubdirectoryAttributes = [self.parserFileManager attributesOfItemAtPath:entrySubdirectoryPath error:&localError];
    if (localError && error)
    {
        *error = localError;
        return nil;
    }
    NSString *entryNSFileType = entrySubdirectoryAttributes[NSFileType];
    NSString *entryBaseName = [entrySubdirectoryPath lastPathComponent];
    NSString *entryBaseExtension = [entryBaseName pathExtension];
    UIImage *entryIconImage = nil;
    NSString *entryBaseType = nil;
    NSString *entryBaseKind = nil;
    if ([entryNSFileType isEqualToString:NSFileTypeRegular])
    {
        entryBaseType = XXTExplorerViewEntryAttributeTypeRegular;
        entryBaseKind = @"Regular";
    }
    else if ([entryNSFileType isEqualToString:NSFileTypeDirectory])
    {
        entryBaseType = XXTExplorerViewEntryAttributeTypeDirectory;
        entryBaseKind = @"Directory";
    }
    else if ([entryNSFileType isEqualToString:NSFileTypeSymbolicLink])
    {
        entryBaseType = XXTExplorerViewEntryAttributeTypeSymlink;
        entryBaseKind = @"Symlink";
    }
    else
    {
        entryBaseType = XXTExplorerViewEntryAttributeTypeUnsupported;
        entryBaseKind = @"Unknown";
    }
    NSString *entryMaskType = entryBaseType;
    if ([entryBaseType isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink])
    {
        const char *entrySubdirectoryPathCString = [entrySubdirectoryPath UTF8String];
        struct stat entrySubdirectoryPathCStatStruct;
        bzero(&entrySubdirectoryPathCStatStruct, sizeof(struct stat));
        if (0 == stat(entrySubdirectoryPathCString, &entrySubdirectoryPathCStatStruct))
        {
            if (S_ISDIR(entrySubdirectoryPathCStatStruct.st_mode))
            {
                entryMaskType = XXTExplorerViewEntryAttributeTypeDirectory;
            }
            else if (S_ISREG(entrySubdirectoryPathCStatStruct.st_mode))
            {
                entryMaskType = XXTExplorerViewEntryAttributeTypeRegular;
            }
            else
            {
                entryMaskType = XXTExplorerViewEntryAttributeTypeUnsupported;
            }
            // MaskType cannot be symlink
        } else {
            if (errno == ENOENT || errno == EMLINK) {
                entryMaskType = XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink;
            }
        }
    }
    if (!entryIconImage) {
        if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular])
        {
            entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeRegular];
        }
        else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
        {
            entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeDirectory];
        }
        else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink])
        {
            entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeSymlink];
        }
        else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink])
        {
            entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink];
        }
        else
        {
            entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeUnsupported];
        }
    }
    NSDictionary *entryAttributes =
    @{
      XXTExplorerViewEntryAttributeIconImage: entryIconImage,
      XXTExplorerViewEntryAttributeDisplayName: entryBaseName,
      XXTExplorerViewEntryAttributeName: entryBaseName,
      XXTExplorerViewEntryAttributePath: entrySubdirectoryPath,
      XXTExplorerViewEntryAttributeCreationDate: entrySubdirectoryAttributes[NSFileCreationDate],
      XXTExplorerViewEntryAttributeModificationDate: entrySubdirectoryAttributes[NSFileModificationDate],
      XXTExplorerViewEntryAttributeSize: entrySubdirectoryAttributes[NSFileSize],
      XXTExplorerViewEntryAttributeType: entryBaseType,
      XXTExplorerViewEntryAttributeMaskType: entryMaskType,
      XXTExplorerViewEntryAttributeExtension: entryBaseExtension,
      XXTExplorerViewEntryAttributeInternalExtension: entryBaseExtension,
      XXTExplorerViewEntryAttributePermission: @[],
      XXTExplorerViewEntryAttributeKind: entryBaseKind,
      XXTExplorerViewEntryAttributeViewer: @"None"
      };
    entryAttributes = [self parseInternalEntry:entryAttributes];
    entryAttributes = [self parseExternalEntry:entryAttributes];
    return entryAttributes;
}

- (NSDictionary *)parseInternalEntry:(NSDictionary *)entry {
    NSMutableDictionary *newEntry = [entry mutableCopy];
    NSString *entryMaskType = entry[XXTExplorerViewEntryAttributeMaskType];
    NSString *entryBaseExtension = [entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    BOOL isBundle = NO;
    if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular])
    {
        // Executable
        if ([entryBaseExtension isEqualToString:@"lua"])
        {
            newEntry[XXTExplorerViewEntryAttributePermission] =
            @[XXTExplorerViewEntryAttributePermissionExecuteable,
              XXTExplorerViewEntryAttributePermissionViewable,
              XXTExplorerViewEntryAttributePermissionEditable,
              ];
            newEntry[XXTExplorerViewEntryAttributeInternalExtension] = XXTExplorerViewEntryAttributeInternalExtensionExecutable;
            newEntry[XXTExplorerViewEntryAttributeKind] = @"LUA Script File";
            newEntry[XXTExplorerViewEntryAttributeViewer] = @"Launcher";
            UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, @"lua"]];
            if (iconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = iconImage;
            }
        }
        else if ([entryBaseExtension isEqualToString:@"xxt"])
        {
            newEntry[XXTExplorerViewEntryAttributePermission] =
            @[XXTExplorerViewEntryAttributePermissionExecuteable,
              ];
            newEntry[XXTExplorerViewEntryAttributeInternalExtension] = XXTExplorerViewEntryAttributeInternalExtensionExecutable;
            newEntry[XXTExplorerViewEntryAttributeKind] = @"XXTouch Script File";
            newEntry[XXTExplorerViewEntryAttributeViewer] = @"Launcher";
            UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, @"xxt"]];
            if (iconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = iconImage;
            }
        }
        // Archive
        else if ([entryBaseExtension isEqualToString:@"zip"])
        {
            newEntry[XXTExplorerViewEntryAttributeInternalExtension] = XXTExplorerViewEntryAttributeInternalExtensionArchive;
            newEntry[XXTExplorerViewEntryAttributeKind] = @"ZIP Archive";
            newEntry[XXTExplorerViewEntryAttributeViewer] = @"Archiver";
            UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, @"zip"]];
            if (iconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = iconImage;
            }
        }
        else {
            // Common Icon Images
            UIImage *extensionIconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, entryBaseExtension]];
            if (extensionIconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = extensionIconImage;
            }
        }
    }
    else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
    {
        if ([entryBaseExtension isEqualToString:@"xpp"])
        {
            isBundle = YES;
        }
    }
    if (isBundle)
    {
        // Bundle
        if ([entryBaseExtension isEqualToString:@"xpp"])
        {
            newEntry[XXTExplorerViewEntryAttributePermission] =
            @[XXTExplorerViewEntryAttributePermissionExecuteable,
              ];
            newEntry[XXTExplorerViewEntryAttributeMaskType] = XXTExplorerViewEntryAttributeMaskTypeBundle;
            newEntry[XXTExplorerViewEntryAttributeInternalExtension] = XXTExplorerViewEntryAttributeInternalExtensionExecutable;
            newEntry[XXTExplorerViewEntryAttributeKind] = @"XXTouch Bundle";
            newEntry[XXTExplorerViewEntryAttributeViewer] = @"Launcher";
            UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, @"xpp"]];
            if (iconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = iconImage;
            }
        }
        else
        {
            UIImage *bundleIconImage = [UIImage imageNamed:@"XXTExplorerViewEntryAttributeMaskTypeBundle"];
            if (bundleIconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = bundleIconImage;
            }
        }
    }
    return [[NSDictionary alloc] initWithDictionary:newEntry];
}

- (NSDictionary *)parseExternalEntry:(NSDictionary *)entry {
    NSMutableDictionary *newEntry = [entry mutableCopy];
    NSString *entryMaskType = entry[XXTExplorerViewEntryAttributeMaskType];
    NSString *entryBaseExtension = [entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular])
    {
        // Regular Preview
    }
    else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle])
    {
        // Bundle Preview
        
        if ([entryBaseExtension isEqualToString:@"xpp"])
        {
            
            NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
            
            
            
        }
        
    }
    return [[NSDictionary alloc] initWithDictionary:newEntry];
}

@end
