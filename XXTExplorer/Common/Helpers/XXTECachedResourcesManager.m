//
//  XXTECachedResourcesManager.m
//  XXTExplorer
//
//  Created by Darwin on 8/29/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTECachedResourcesManager.h"


@implementation XXTECachedResourcesManager

+ (NSDateFormatter *)cachedResourcesDateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        formatter.timeZone = [NSTimeZone localTimeZone];
        formatter.locale = [NSLocale currentLocale];
    });
    return formatter;
}

+ (instancetype)sharedManager {
    static XXTECachedResourcesManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (NSString *)dateCachesPathAtCachesPath:(NSString *)resourcesPath {
    NSString *datePath = [resourcesPath stringByAppendingPathComponent:[[[self class] cachedResourcesDateFormatter] stringFromDate:[NSDate date]]];
    [self.fileManager createDirectoryAtPath:datePath withIntermediateDirectories:YES attributes:nil error:nil];
    return datePath;
}

- (void)cleanOutdatedManagedResourcesAtCachesPath:(NSString *)resourcesPath limitType:(NSInteger)type {
    NSURL *historyRootURL = [NSURL fileURLWithPath:resourcesPath];
    
    NSTimeInterval historyLimit;
    switch (type) {
        case 0:
            historyLimit = 604800;
            break;
        case 1:
            historyLimit = 604800 * 2;
            break;
        case 2:
            historyLimit = 2592000;
            break;
        case 3:
            historyLimit = 7776000;
            break;
        case 4:
            historyLimit = 15552000;
            break;
        case 5:
            historyLimit = 31536000;
            break;
        case 6:
            historyLimit = INT_MAX;
            break;
        default:
            historyLimit = 7776000;
            break;
    }
    
    NSDirectoryEnumerator *enumerator = [self.fileManager enumeratorAtURL:historyRootURL
                                               includingPropertiesForKeys:@[ NSURLPathKey, NSURLIsDirectoryKey ]
                                                                  options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                             errorHandler:^BOOL(NSURL *url, NSError *error) {
#ifdef DEBUG
                                                                 NSLog(@"[Error] %@ (%@)", error, url);
#endif
                                                                 return YES;
                                                             }];
    
    NSDateFormatter *dateFormatter = [[self class] cachedResourcesDateFormatter];
    for (NSURL *dateDirectoryURL in enumerator) {
        NSNumber *isPathDirectory = nil;
        [dateDirectoryURL getResourceValue:&isPathDirectory forKey:NSURLIsDirectoryKey error:nil];
        if (![isPathDirectory boolValue]) {
            continue;
        }
        
        NSString *dateDirectoryPath = nil;
        [dateDirectoryURL getResourceValue:&dateDirectoryPath forKey:NSURLPathKey error:nil];
        
        NSString *dateDirectoryName = [dateDirectoryPath lastPathComponent];
        NSDate *dateDirectoryDate = [dateFormatter dateFromString:dateDirectoryName];
        if (!dateDirectoryDate) {
            continue;
        }
        
        if (fabs([dateDirectoryDate timeIntervalSinceNow]) > historyLimit)
        {
            [self.fileManager removeItemAtURL:dateDirectoryURL error:nil];
        }
    }
}

@end
