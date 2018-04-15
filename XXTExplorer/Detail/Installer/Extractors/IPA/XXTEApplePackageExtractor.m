//
//  XXTEApplePackageExtractor.m
//  XXTExplorer
//
//  Created by Zheng on 2018/4/11.
//  Copyright © 2018 Zheng. All rights reserved.
//

//#import <spawn.h>
#import <sys/stat.h>
#import "XXTEApplePackageExtractor.h"
#import "XXTEProcessDelegateObject.h"

@interface XXTEApplePackageExtractor ()

@property (nonatomic, strong, readonly) NSString *temporarilyLocation;

@end

@implementation XXTEApplePackageExtractor

@synthesize packagePath = _packagePath;
@synthesize delegate = _delegate;

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _packagePath = path;
        NSString *temporarilyLocation = [[XXTERootPath() stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"_XXTEApplePackageExtractor"];
        struct stat temporarilyLocationStat;
        if (0 != lstat([temporarilyLocation fileSystemRepresentation], &temporarilyLocationStat))
            if (0 != mkdir([temporarilyLocation fileSystemRepresentation], 0755))
                NSLog(@"%@", [NSString stringWithFormat:@"Cannot create temporarily directory \"%@\".", temporarilyLocation]);
        _temporarilyLocation = temporarilyLocation;
    }
    return self;
}

- (void)installPackage {
    NSString *packagePath = self.packagePath;
    NSString *randomUUIDString = [[NSUUID UUID] UUIDString];
    NSString *temporarilyName = [NSString stringWithFormat:@".tmp_%@_%@.log", [packagePath lastPathComponent], randomUUIDString];
    NSString *temporarilyPath = [self.temporarilyLocation stringByAppendingPathComponent:temporarilyName];
    struct stat temporarilyStat;
    if (0 == lstat([temporarilyPath fileSystemRepresentation], &temporarilyStat)) {
        [self callbackInstallationErrorWithReason:[NSString stringWithFormat:NSLocalizedString(@"Temporarily file \"%@\" already exists.", nil), temporarilyPath]];
        return;
    }
    [[NSData data] writeToFile:temporarilyPath atomically:YES];

    int status = 0;
    pid_t pid = 0;
    
    const char *binary = add1s_binary();
    const char *installer = installer_binary();
    const char *args[] = { binary, installer, "-f", [packagePath fileSystemRepresentation], NULL };
    
    XXTEProcessDelegateObject *processObj = [[XXTEProcessDelegateObject alloc] init];
    NSArray <NSValue *> *fps = [processObj processOpen:args pidPointer:&pid];
    FILE *fp1 = [fps[0] pointerValue];
    FILE *fp2 = [fps[1] pointerValue];
    if (fp1 == NULL || fp2 == NULL) {
        [self callbackInstallationErrorWithReason:NSLocalizedString(@"Cannot launch installer process.", nil)];
        return;
    }
    
    int maxSize = BUFSIZ * 4;
    char buf1[maxSize];
    char buf2[maxSize];
    bzero(buf1, maxSize);
    bzero(buf2, maxSize);
    while (fgets(buf1, maxSize, fp1) != NULL || fgets(buf2, maxSize, fp2) != NULL) {
        if (buf1[0] != '\0' && [_delegate respondsToSelector:@selector(packageExtractor:didReceiveStandardOutput:)]) {
            NSString *newOutput = [[NSString alloc] initWithUTF8String:buf1];
            [_delegate packageExtractor:self didReceiveStandardOutput:newOutput];
        }
        if (buf2[0] != '\0' && [_delegate respondsToSelector:@selector(packageExtractor:didReceiveStandardError:)]) {
            NSString *newOutput = [[NSString alloc] initWithUTF8String:buf2];
            [_delegate packageExtractor:self didReceiveStandardError:newOutput];
        }
        bzero(buf1, maxSize);
        bzero(buf2, maxSize);
    }
    status = [processObj processClose:fps pidPointer:&pid];
    
    if (status != 0) {
        [self callbackInstallationErrorWithReason:[NSString stringWithFormat:NSLocalizedString(@"Error code: %d", nil), status]];
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(packageExtractorDidFinishInstallation:)]) {
        [_delegate packageExtractorDidFinishInstallation:self];
    }
}

- (void)callbackInstallationErrorWithReason:(NSString *)exceptionReason {
    if (!exceptionReason) {
        return;
    }
    NSError *exceptionError = [NSError errorWithDomain:kXXTErrorDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
    if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFailInstallationWithError:)]) {
        [_delegate packageExtractor:self didFailInstallationWithError:exceptionError];
    }
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
    NSData *controlData = [NSData data];
    if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFinishFetchingMetaData:)]) {
        [_delegate packageExtractor:self didFinishFetchingMetaData:controlData];
    }
}

@end
