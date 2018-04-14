//
//  XXTEDebianPackageExtractor.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/5.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <spawn.h>
#import <sys/stat.h>
#import "XXTEDebianPackageExtractor.h"


@interface XXTEDebianPackageExtractor ()

@property (nonatomic, strong, readonly) NSString *temporarilyLocation;

@end

@implementation XXTEDebianPackageExtractor

@synthesize packagePath = _packagePath;
@synthesize delegate = _delegate;

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _packagePath = path;
        NSString *temporarilyLocation = [[XXTERootPath() stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"_XXTEDebianPackageExtractor"];
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
    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);
    posix_spawn_file_actions_addopen(&action, STDOUT_FILENO, [temporarilyPath fileSystemRepresentation], O_WRONLY, 0);
    int status = 0;
    pid_t pid = 0;
    const char *binary = add1s_binary();
    const char *args[] = { binary, "/usr/bin/dpkg", "-i", [packagePath fileSystemRepresentation], NULL };
    posix_spawn(&pid, binary, &action, NULL, (char* const*)args, (char* const*)XXTESharedEnvp());
    posix_spawn_file_actions_destroy(&action);
    if (pid == 0) {
        [self callbackInstallationErrorWithReason:NSLocalizedString(@"Cannot launch installer process.", nil)];
        return;
    }
    waitpid(pid, &status, 0);
    struct stat temporarilyControlStat;
    if (0 != lstat([temporarilyPath fileSystemRepresentation], &temporarilyControlStat)) {
        [self callbackInstallationErrorWithReason:[NSString stringWithFormat:NSLocalizedString(@"Cannot find log file \"%@\".", nil), temporarilyPath]];
        return;
    }
    NSData *logData = [[NSData alloc] initWithContentsOfFile:temporarilyPath];
    if (!logData) {
        [self callbackInstallationErrorWithReason:[NSString stringWithFormat:NSLocalizedString(@"Cannot open log file \"%@\".", nil), temporarilyPath]];
        return;
    }
    NSString *logString = [[NSString alloc] initWithData:logData encoding:NSUTF8StringEncoding];
    if (status != 0) {
        [self callbackInstallationErrorWithReason:logString];
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFinishInstallation:)]) {
        [_delegate packageExtractor:self didFinishInstallation:logString];
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
    NSString *packagePath = self.packagePath;
    NSString *randomUUIDString = [[NSUUID UUID] UUIDString];
    NSString *temporarilyName = [NSString stringWithFormat:@".tmp_%@_%@", [packagePath lastPathComponent], randomUUIDString];
    NSString *temporarilyPath = [self.temporarilyLocation stringByAppendingPathComponent:temporarilyName];
    struct stat temporarilyStat;
    if (0 == lstat([temporarilyPath fileSystemRepresentation], &temporarilyStat)) {
        [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Temporarily directory \"%@\" already exists.", nil), temporarilyPath]];
        return;
    }
    int status = 0;
    pid_t pid = 0;
    const char *binary = add1s_binary();
    const char *args[] = { binary, "/usr/bin/dpkg", "-e", [packagePath fileSystemRepresentation], [temporarilyPath fileSystemRepresentation], NULL };
    posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)XXTESharedEnvp());
    if (pid == 0) {
        [self callbackFetchingMetaDataWithErrorReason:NSLocalizedString(@"Cannot launch installer process.", nil)];
        return;
    }
    waitpid(pid, &status, 0);
    if (status != 0) {
        [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Installer process returned non-zero code (%d).", nil), status]];
        return;
    }
    NSString *temporarilyControlPath = [temporarilyPath stringByAppendingPathComponent:@"control"];
    struct stat temporarilyControlStat;
    if (0 != lstat([temporarilyControlPath fileSystemRepresentation], &temporarilyControlStat)) {
        [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Cannot find control file \"%@\".", nil), temporarilyControlPath]];
        return;
    }
    NSData *controlData = [[NSData alloc] initWithContentsOfFile:temporarilyControlPath];
    if (!controlData) {
        [self callbackFetchingMetaDataWithErrorReason:[NSString stringWithFormat:NSLocalizedString(@"Cannot open control file \"%@\".", nil), temporarilyControlPath]];
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFinishFetchingMetaData:)]) {
        [_delegate packageExtractor:self didFinishFetchingMetaData:controlData];
    }
}

- (void)killBackboardd {
    __block int status = 0;
    double delayInSeconds = 1.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        pid_t pid = 0;
        const char *binary = add1s_binary();
        const char *args[] = {binary, "/usr/bin/killall", "-9", "SpringBoard", "backboardd", NULL};
        posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)XXTESharedEnvp());
        waitpid(pid, &status, 0);
        dispatch_async(dispatch_get_main_queue(), ^{
            // DO NOTHING
        });
    });
    
}

@end