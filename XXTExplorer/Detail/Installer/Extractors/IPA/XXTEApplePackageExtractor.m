//
//  XXTEApplePackageExtractor.m
//  XXTExplorer
//
//  Created by Zheng on 2018/4/11.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <spawn.h>
#import <sys/stat.h>
#import "XXTEApplePackageExtractor.h"

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
        [self callbackInstallationErrorWithReason:[NSString stringWithFormat:@"Temporarily file \"%@\" already exists.", temporarilyPath]];
        return;
    }
    [[NSData data] writeToFile:temporarilyPath atomically:YES];
    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);
    posix_spawn_file_actions_addopen(&action, STDOUT_FILENO, [temporarilyPath fileSystemRepresentation], O_WRONLY, 0);
    int status = 0;
    pid_t pid = 0;
    const char *binary = add1s_binary();
    const char *installer = installer_binary();
    const char *args[] = { binary, installer, "-f", [packagePath fileSystemRepresentation], NULL };
    posix_spawn(&pid, binary, &action, NULL, (char* const*)args, (char* const*)XXTESharedEnvp());
    posix_spawn_file_actions_destroy(&action);
    if (pid == 0) {
        [self callbackInstallationErrorWithReason:@"Cannot launch installer process."];
        return;
    }
    waitpid(pid, &status, 0);
    struct stat temporarilyControlStat;
    if (0 != lstat([temporarilyPath fileSystemRepresentation], &temporarilyControlStat)) {
        [self callbackInstallationErrorWithReason:[NSString stringWithFormat:@"Cannot find log file \"%@\".", temporarilyPath]];
        return;
    }
    NSData *logData = [[NSData alloc] initWithContentsOfFile:temporarilyPath];
    if (!logData) {
        [self callbackInstallationErrorWithReason:[NSString stringWithFormat:@"Cannot open log file \"%@\".", temporarilyPath]];
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
    NSData *controlData = [NSData data];
    if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFinishFetchingMetaData:)]) {
        [_delegate packageExtractor:self didFinishFetchingMetaData:controlData];
    }
}

@end
