//
//  XXTEPermissionDefines.h
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/1/30.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#ifndef XXTEPermissionDefines_h
#define XXTEPermissionDefines_h

#import <spawn.h>
#import <sys/stat.h>
#import "XXTEAppDefines.h"
#import <PromiseKit/PromiseKit.h>

static inline int promiseFixPermission(NSString *path, BOOL resursive) {
#ifdef APPSTORE
    return 0;
#endif
#ifndef DEBUG
    static const char* binary = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        binary = [uAppDefine(@"ADD1S_PATH") UTF8String];
    });
    int status = 0;
    if (resursive) {
        pid_t pid = 0;
        const char* args[] = {binary, "chown", "-R", "mobile:mobile", [path fileSystemRepresentation], NULL};
        posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)sharedEnvp);
        waitpid(pid, &status, 0);
    } else {
        pid_t pid = 0;
        const char* args[] = {binary, "chown", "mobile:mobile", [path fileSystemRepresentation], NULL};
        posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)sharedEnvp);
        waitpid(pid, &status, 0);
    }
    return status;
#else
    return 0;
#endif
}

#endif /* XXTEPermissionDefines_h */
