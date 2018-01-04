//
//  XXTEXPAPackageExtractor.m
//  XXTExplorer
//
//  Created by Zheng on 26/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import "XXTEXPAPackageExtractor.h"
#import "XXTEAppDefines.h"
#import "XXTEDispatchDefines.h"

#import "zip.h"

@interface XXTEXPAPackageExtractor ()
@property (nonatomic, strong, readonly) NSString *temporarilyLocation;

@end

@implementation XXTEXPAPackageExtractor

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _packagePath = path;
        
        NSString *cachesLocation = [[XXTEAppDelegate sharedRootPath] stringByAppendingPathComponent:@"caches"];
        
        NSString *temporarilyLocation = [cachesLocation stringByAppendingPathComponent:@"_XXTEXPAPackageExtractor"];
        _temporarilyLocation = temporarilyLocation;
        [self cleanTemporarilyFilesAtLocation:temporarilyLocation];
        
        struct stat temporarilyLocationStat;
        if (0 != lstat([temporarilyLocation fileSystemRepresentation], &temporarilyLocationStat)) {
            if (0 != mkdir([temporarilyLocation fileSystemRepresentation], 0755)) {
                [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Cannot create temporarily directory \"%@\".", nil), temporarilyLocation]];
                return nil;
            }
        }
        
        NSString *randomUUIDString = [[NSUUID UUID] UUIDString];
        NSString *temporarilyName = [NSString stringWithFormat:@".tmp_%@_%@", [path lastPathComponent], randomUUIDString];
        NSString *temporarilyPath = [temporarilyLocation stringByAppendingPathComponent:temporarilyName];
        struct stat temporarilyStat;
        if (0 == lstat([temporarilyPath UTF8String], &temporarilyStat)) {
            [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Temporarily directory \"%@\" already exists.", nil), temporarilyPath]];
            return nil;
        }
        if (0 != mkdir([temporarilyPath UTF8String], 0755)) {
            [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Cannot create temporarily directory \"%@\".", nil), temporarilyPath]];
            return nil;
        }
        _metaPath = temporarilyPath;
    }
    return self;
}

- (void)callbackFetchingMetaDataWithErrorReason:(NSString *)exceptionReason {
    if (!exceptionReason) {
        return;
    }
    NSError *exceptionError = [NSError errorWithDomain:kXXTErrorDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
    if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFailFetchingMetaDataWithError:)]) {
        [_delegate packageExtractor:self didFailFetchingMetaDataWithError:exceptionError];
    }
}

- (void)extractMetaData {
    if (!self.packagePath) {
        return;
    }
    NSString *packagePath = self.packagePath;
    NSString *temporarilyPath = self.metaPath;
    int (^will_extract)(const char *, void *) = ^int(const char *filename, void *arg) {
        return zip_extract_override;
    };
    @weakify(self);
    int (^did_extract)(const char *, void *) = ^int(const char *filename, void *arg) {
        @strongify(self);
        if (!self.busyOperationProgressFlag) {
            dispatch_async_on_main_queue(^{
                [self callbackFetchingMetaDataWithErrorReason:NSLocalizedString(@"Operation aborted.", nil)];
            });
            return -1;
        }
        return 0;
    };
    self.busyOperationProgressFlag = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @strongify(self);
        int arg = 2;
        int status = zip_extract([packagePath UTF8String], [temporarilyPath UTF8String], will_extract, did_extract, &arg);
        dispatch_async_on_main_queue(^{
            if (status == 0) {
                if ([_delegate respondsToSelector:@selector(packageExtractor:didFinishFetchingMetaData:)]) {
                    NSData *pathData = [self.metaPath dataUsingEncoding:NSUTF8StringEncoding];
                    [_delegate packageExtractor:self didFinishFetchingMetaData:pathData];
                }
            } else {
                [self callbackFetchingMetaDataWithErrorReason:NSLocalizedString(@"Cannot extract package.", nil)];
            }
        });
    });
}

- (void)cleanTemporarilyFilesAtLocation:(NSString *)pathClean {
    if (!pathClean) return;
    NSError *cleanError = nil;
    BOOL cleanStatus =
    [[NSFileManager defaultManager] removeItemAtPath:pathClean error:&cleanError];
    if (cleanStatus) {
//        [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Temporarily XPP Bundle cleaned: \"%@\".", nil), pathClean]];
    } else {
        if (cleanError) {
//            [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Cannot clean temporarily XPP Bundle: \"%@\", reason: %@.", nil), pathClean, cleanError.localizedDescription]];
        }
    }
}

- (void)dealloc {
    [self cleanTemporarilyFilesAtLocation:self.temporarilyLocation];
}

@end
