//
//  XXTEPackageExtractor.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/5.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <spawn.h>
#import <sys/stat.h>
#import "XXTEPackageExtractor.h"
#import "XXTEAppDefines.h"

@interface XXTEPackageExtractor ()

@property (nonatomic, strong, readonly) NSString *temporarilyLocation;

@end

@implementation XXTEPackageExtractor

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _packagePath = path;
        NSString *temporarilyLocation = [[[sharedDelegate() sharedRootPath] stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"_XXTEPackageExtractor"];
        struct stat temporarilyLocationStat;
        if (0 != lstat([temporarilyLocation UTF8String], &temporarilyLocationStat))
            if (0 != mkdir([temporarilyLocation UTF8String], 0755))
                NSLog(@"%@", [NSString stringWithFormat:@"Cannot create temporarily directory \"%@\".", temporarilyLocation]);
        _temporarilyLocation = temporarilyLocation;
    }
    return self;
}

- (void)installPackage {
    @try {
        NSString *packagePath = self.packagePath;
        NSString *randomUUIDString = [[NSUUID UUID] UUIDString];
        NSString *temporarilyName = [NSString stringWithFormat:@".tmp_%@_%@.log", [packagePath lastPathComponent], randomUUIDString];
        NSString *temporarilyPath = [self.temporarilyLocation stringByAppendingPathComponent:temporarilyName];
        struct stat temporarilyStat;
        if (0 == lstat([temporarilyPath UTF8String], &temporarilyStat))
            @throw [NSString stringWithFormat:@"Temporarily file \"%@\" already exists.", temporarilyPath];
        [[NSData data] writeToFile:temporarilyPath atomically:YES];
        posix_spawn_file_actions_t action;
        posix_spawn_file_actions_init(&action);
        posix_spawn_file_actions_addopen(&action, STDOUT_FILENO, [temporarilyPath UTF8String], O_WRONLY, 0);
        int status = 0;
        pid_t pid = 0;
        const char* binary = [uAppDefine(@"ADD1S_PATH") UTF8String];
        const char* args[] = { binary, "/usr/bin/dpkg", "-i", [packagePath UTF8String], NULL };
        posix_spawn(&pid, binary, &action, NULL, (char* const*)args, (char* const*)sharedEnvp);
        posix_spawn_file_actions_destroy(&action);
        if (pid == 0)
            @throw @"Cannot launch installer process.";
        waitpid(pid, &status, 0);
        struct stat temporarilyControlStat;
        if (0 != lstat([temporarilyPath UTF8String], &temporarilyControlStat))
            @throw [NSString stringWithFormat:@"Cannot find log file \"%@\".", temporarilyPath];
        NSData *logData = [[NSData alloc] initWithContentsOfFile:temporarilyPath];
        if (!logData)
            @throw [NSString stringWithFormat:@"Cannot open log file \"%@\".", temporarilyPath];
        NSString *logString = [[NSString alloc] initWithData:logData encoding:NSUTF8StringEncoding];
        if (status != 0)
            @throw logString;
        if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFinishInstalling:)]) {
            [_delegate packageExtractor:self didFinishInstalling:logString];
        }
    } @catch (NSString *exceptionReason) {
        NSError *exceptionError = [NSError errorWithDomain:kXXTErrorDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
        if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFailInstallingWithError:)]) {
            [_delegate packageExtractor:self didFailInstallingWithError:exceptionError];
        }
    } @finally {
        
    }
}

- (void)extractMetaData {
    @try {
        NSString *packagePath = self.packagePath;
        NSString *randomUUIDString = [[NSUUID UUID] UUIDString];
        NSString *temporarilyName = [NSString stringWithFormat:@".tmp_%@_%@", [packagePath lastPathComponent], randomUUIDString];
        NSString *temporarilyPath = [self.temporarilyLocation stringByAppendingPathComponent:temporarilyName];
        struct stat temporarilyStat;
        if (0 == lstat([temporarilyPath UTF8String], &temporarilyStat))
            @throw [NSString stringWithFormat:@"Temporarily directory \"%@\" already exists.", temporarilyPath];
        int status = 0;
        pid_t pid = 0;
        const char* binary = [uAppDefine(@"ADD1S_PATH") UTF8String];
        const char* args[] = { binary, "/usr/bin/dpkg", "-e", [packagePath UTF8String], [temporarilyPath UTF8String], NULL };
        posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)sharedEnvp);
        if (pid == 0)
            @throw @"Cannot launch installer process.";
        waitpid(pid, &status, 0);
        if (status != 0)
            @throw @"Installer process returned non-zero code.";
        NSString *temporarilyControlPath = [temporarilyPath stringByAppendingPathComponent:@"control"];
        struct stat temporarilyControlStat;
        if (0 != lstat([temporarilyControlPath UTF8String], &temporarilyControlStat))
            @throw [NSString stringWithFormat:@"Cannot find control file \"%@\".", temporarilyControlPath];
        NSData *controlData = [[NSData alloc] initWithContentsOfFile:temporarilyControlPath];
        if (!controlData)
            @throw [NSString stringWithFormat:@"Cannot open control file \"%@\".", temporarilyControlPath];
        if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFinishFetchingMetaData:)]) {
            [_delegate packageExtractor:self didFinishFetchingMetaData:controlData];
        }
    } @catch (NSString *exceptionReason) {
        NSError *exceptionError = [NSError errorWithDomain:kXXTErrorDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: exceptionReason }];
        if (_delegate && [_delegate respondsToSelector:@selector(packageExtractor:didFailFetchingMetaDataWithError:)]) {
            [_delegate packageExtractor:self didFailFetchingMetaDataWithError:exceptionError];
        }
    } @finally {
        
    }
}


- (void)killBackboardd {
    __block int status = 0;
    double delayInSeconds = 1.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        pid_t pid = 0;
        const char* binary = [uAppDefine(@"ADD1S_PATH") UTF8String];
        const char* args[] = {binary, "/usr/bin/killall", "-9", "backboardd", NULL};
        posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)sharedEnvp);
        waitpid(pid, &status, 0);
        dispatch_async(dispatch_get_main_queue(), ^{
            // DO NOTHING
        });
    });
    
}

@end
