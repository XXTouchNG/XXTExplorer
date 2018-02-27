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
#import "XXTExplorerEntryLauncher.h"
#import "XXTExplorerEntryUnarchiver.h"

@interface XXTExplorerEntryParser ()
@property (nonatomic, strong, readonly) NSFileManager *parserFileManager;

@end

@implementation XXTExplorerEntryParser {
    
}

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

+ (XXTExplorerEntryService *)parserEntryService {
    static XXTExplorerEntryService *parserEntryService = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!parserEntryService) {
            parserEntryService = [XXTExplorerEntryService sharedInstance];
        }
    });
    return parserEntryService;
}

+ (NSArray <Class> *)bundleReaders {
    static NSArray <Class> *bundleReaders = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!bundleReaders) {
            NSArray <NSString *> *registeredNames = uAppDefine(@"AVAILABLE_BUNDLE_READER");
            NSMutableArray <Class> *registeredMutableReaders = [[NSMutableArray alloc] initWithCapacity:registeredNames.count];
            for (NSString *className in registeredNames) {
                [registeredMutableReaders addObject:NSClassFromString(className)];
            }
            bundleReaders = [[NSArray alloc] initWithArray:registeredMutableReaders];
        }
    });
    return bundleReaders;
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
    if (localError)
    {
        if (error) {
            *error = localError;
        }
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
    NSString *entryDescription = [self.class.entryDateFormatter stringFromDate:entrySubdirectoryAttributes[NSFileModificationDate]];
    NSDictionary *entryDetail =
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
      XXTExplorerViewEntryAttributeDescription: entryDescription,
      };
    NSDictionary *extraEntryDetail = [self parseExternalEntry:entryDetail];
    return extraEntryDetail;
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
            if ([bindedViewerClass respondsToSelector:@selector(relatedReader)]) {
                Class relatedReaderClass = [((Class <XXTEViewer>)bindedViewerClass) relatedReader];
                if (relatedReaderClass) {
                    XXTExplorerEntryReader *relatedReader = [[relatedReaderClass alloc] initWithPath:entryPath];
                    newEntry[XXTExplorerViewEntryAttributeEntryReader] = relatedReader;
                }
            }
        }
    }
    else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
    {
        for (Class readerClass in [self.class bundleReaders]) {
            BOOL supported = NO;
            for (NSString *supportedExtension in [readerClass supportedExtensions]) {
                if ([supportedExtension isEqualToString:entryBaseExtension]) {
                    supported = YES;
                    break;
                }
            }
            if (supported) {
                XXTExplorerEntryReader *bundleReader = [[readerClass alloc] initWithPath:entryPath];
                newEntry[XXTExplorerViewEntryAttributeMaskType] = XXTExplorerViewEntryAttributeMaskTypeBundle;
                newEntry[XXTExplorerViewEntryAttributeEntryReader] = bundleReader;
                UIImage *bundleIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeMaskTypeBundle];
                if (bundleIconImage) {
                    newEntry[XXTExplorerViewEntryAttributeIconImage] = bundleIconImage;
                }
                break;
            }
        }
    }
    return [[NSDictionary alloc] initWithDictionary:newEntry];
}

@end
