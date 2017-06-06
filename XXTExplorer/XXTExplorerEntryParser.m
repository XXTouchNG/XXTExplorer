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
    if ([entryNSFileType isEqualToString:NSFileTypeRegular])
    {
        entryBaseType = XXTExplorerViewEntryAttributeTypeRegular;
    }
    else if ([entryNSFileType isEqualToString:NSFileTypeDirectory])
    {
        entryBaseType = XXTExplorerViewEntryAttributeTypeDirectory;
    }
    else if ([entryNSFileType isEqualToString:NSFileTypeSymbolicLink])
    {
        entryBaseType = XXTExplorerViewEntryAttributeTypeSymlink;
    }
    else
    {
        entryBaseType = XXTExplorerViewEntryAttributeTypeUnsupported;
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
      XXTExplorerViewEntryAttributePermission: @[]
      };
    entryAttributes = [self parseInternalEntry:entryAttributes];
    entryAttributes = [self parseExternalEntry:entryAttributes];
    return entryAttributes;
}

- (NSDictionary *)parseInternalEntry:(NSDictionary *)entry {
    NSMutableDictionary *newEntry = [entry mutableCopy];
    NSString *entryMaskType = entry[XXTExplorerViewEntryAttributeMaskType];
    NSString *entryBaseExtension = entry[XXTExplorerViewEntryAttributeExtension];
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
        }
        else if ([entryBaseExtension isEqualToString:@"xxt"])
        {
            newEntry[XXTExplorerViewEntryAttributePermission] =
            @[XXTExplorerViewEntryAttributePermissionExecuteable,
              ];
            newEntry[XXTExplorerViewEntryAttributeInternalExtension] = XXTExplorerViewEntryAttributeInternalExtensionExecutable;
        }
        // Archive
        else if ([entryBaseExtension isEqualToString:@"zip"])
        {
            newEntry[XXTExplorerViewEntryAttributeInternalExtension] = XXTExplorerViewEntryAttributeInternalExtensionArchive;
            newEntry[XXTExplorerViewEntryAttributeIconImage] = [UIImage imageNamed:@"XXTExplorerViewEntryAttributeExtensionZIP"];
        }
    }
    else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
    {
        // Bundle
        if ([entryBaseExtension isEqualToString:@"xpp"])
        {
            newEntry[XXTExplorerViewEntryAttributePermission] =
            @[XXTExplorerViewEntryAttributePermissionExecuteable,
              ];
            newEntry[XXTExplorerViewEntryAttributeMaskType] = XXTExplorerViewEntryAttributeTypeBundle;
            newEntry[XXTExplorerViewEntryAttributeInternalExtension] = XXTExplorerViewEntryAttributeInternalExtensionExecutable;
        }
    }
    return [[NSDictionary alloc] initWithDictionary:newEntry];
}

- (NSDictionary *)parseExternalEntry:(NSDictionary *)entry {
    return entry;
}

@end
