//
//  XXTExplorerEntryParser.m
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryReader.h"
#import "XXTExplorerEntryXPPReader.h"
#import "XXTExplorerEntryService.h"
#import "XXTEViewer.h"

static NSString * const kXXTEFileTypeImageNameFormat = @"XXTEFileType-%@";

@interface XXTExplorerEntryParser ()
@property (nonatomic, strong, readonly) NSFileManager *parserFileManager;

@end

@implementation XXTExplorerEntryParser {
    
}

+ (NSDateFormatter *)entryDateFormatter {
    static NSDateFormatter *entryDateFormatter = nil;
    if (!entryDateFormatter) {
        entryDateFormatter = ({
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            dateFormatter;
        });
    }
    return entryDateFormatter;
}

+ (XXTExplorerEntryService *)parserEntryService {
    static XXTExplorerEntryService *parserEntryService = nil;
    if (!parserEntryService) {
        parserEntryService = [XXTExplorerEntryService sharedInstance];
    }
    return parserEntryService;
}

+ (NSArray <Class> *)registeredReaders {
    static NSArray <Class> *registeredReaders = nil;
    if (!registeredReaders) {
        NSArray <NSString *> *registeredNames = XXTEBuiltInDefaultsObject(@"AVAILABLE_ENTRY_READER");
        NSMutableArray <Class> *registeredMutableReaders = [[NSMutableArray alloc] initWithCapacity:registeredNames.count];
        for (NSString *className in registeredNames) {
            [registeredMutableReaders addObject:NSClassFromString(className)];
        }
        registeredReaders = [[NSArray alloc] initWithArray:registeredMutableReaders];
    }
    return registeredReaders;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _parserFileManager = [[NSFileManager alloc] init];
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
    NSString *entryDescription = [self.class.entryDateFormatter stringFromDate:entrySubdirectoryAttributes[NSFileCreationDate]];
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
      XXTExplorerViewEntryAttributeDescription: entryDescription,
      XXTExplorerViewEntryAttributeExtensionDescription: entryBaseKind,
      XXTExplorerViewEntryAttributeViewerDescription: @"None"
      };
    NSDictionary *newEntryAttributes = [self parseInternalEntry:entryAttributes];
    NSDictionary *extraEntryAttributes = [self parseExternalEntry:newEntryAttributes];
    return extraEntryAttributes;
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
            newEntry[XXTExplorerViewEntryAttributeExtensionDescription] = @"LUA Script File";
            newEntry[XXTExplorerViewEntryAttributeViewerDescription] = @"Launcher";
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
            newEntry[XXTExplorerViewEntryAttributeExtensionDescription] = @"XXTouch Script File";
            newEntry[XXTExplorerViewEntryAttributeViewerDescription] = @"Launcher";
            UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, @"xxt"]];
            if (iconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = iconImage;
            }
        }
        // Archive
        else if ([entryBaseExtension isEqualToString:@"zip"])
        {
            newEntry[XXTExplorerViewEntryAttributeInternalExtension] = XXTExplorerViewEntryAttributeInternalExtensionArchive;
            newEntry[XXTExplorerViewEntryAttributeExtensionDescription] = @"ZIP Archive";
            newEntry[XXTExplorerViewEntryAttributeViewerDescription] = @"Archiver";
            UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, @"zip"]];
            if (iconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = iconImage;
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
            newEntry[XXTExplorerViewEntryAttributeExtensionDescription] = @"XXTouch Bundle";
            newEntry[XXTExplorerViewEntryAttributeViewerDescription] = @"Launcher";
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
    NSDictionary *bindingDictionary = [self.class.parserEntryService bindingDictionary];
    NSMutableDictionary *newEntry = [entry mutableCopy];
    NSString *entryMaskType = entry[XXTExplorerViewEntryAttributeMaskType];
    NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
    NSString *entryBaseExtension = [entry[XXTExplorerViewEntryAttributeExtension] lowercaseString];
    if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular])
    {
        // Find binded viewers
        NSString *bindedViewerName = bindingDictionary[entryBaseExtension];
        if (bindedViewerName) {
            Class bindedViewerClass = NSClassFromString(bindedViewerName);
            if (bindedViewerClass) {
                Class relatedReaderClass = [((Class <XXTEViewer>)bindedViewerClass) relatedReader];
                if (relatedReaderClass) {
                    id <XXTExplorerEntryReader> relatedReader = [[relatedReaderClass alloc] initWithPath:entryPath];
                    newEntry[XXTExplorerViewEntryAttributeEntryReader] = relatedReader;
                }
            }
        }
        {
            // Common Icon Images
            UIImage *extensionIconImage = [UIImage imageNamed:[NSString stringWithFormat:kXXTEFileTypeImageNameFormat, entryBaseExtension]];
            if (extensionIconImage) {
                newEntry[XXTExplorerViewEntryAttributeIconImage] = extensionIconImage;
            }
        }
    } else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle])
    {
        for (Class readerClass in [self.class registeredReaders]) {
            BOOL supported = NO;
            for (NSString *supportedExtension in [readerClass supportedExtensions]) {
                if ([supportedExtension isEqualToString:entryBaseExtension]) {
                    supported = YES;
                    break;
                }
            }
            if (supported) {
                id <XXTExplorerEntryReader> bundleReader = [[readerClass alloc] initWithPath:entryPath];
                newEntry[XXTExplorerViewEntryAttributeEntryReader] = bundleReader;
                break;
            }
        }
    }
    return [[NSDictionary alloc] initWithDictionary:newEntry];
}

@end
