//
// Created by Zheng Wu on 10/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <spawn.h>
#import <sys/stat.h>
#import "XXTERespringAgent.h"

#import "XXTEAppDefines.h"
#import "XXTEPermissionDefines.h"

@implementation XXTERespringAgent {

}

+ (BOOL)shouldPerformRespring {
    struct stat flagStat;
    NSString *flagPath = uAppDefine(@"RESPRING_CHECK_PATH");
    return (0 == lstat(flagPath.UTF8String, &flagStat));
}

+ (void)performRespring {
    __block int status = 0;
    double delayInSeconds = 1.0f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        pid_t pid = 0;
        const char *binary = add1s_binary();
        const char *args[] = {binary, "/usr/bin/killall", "-9", "SpringBoard", "backboardd", NULL};
        posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)sharedEnvp);
        waitpid(pid, &status, 0);
        dispatch_async(dispatch_get_main_queue(), ^{
            // DO NOTHING
        });
    });
}


@end
