//
//  XXTEProcessDelegateObject.m
//  XXTExplorer
//
//  Created by Zheng on 2018/4/14.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEProcessDelegateObject.h"

#import <stdio.h>
#import <spawn.h>
#import <sys/wait.h>
#import <fcntl.h>
#import <unistd.h>
#import <strings.h>
#import <errno.h>
#import <stdlib.h>
#import <sys/stat.h>

@implementation XXTEProcessDelegateObject

- (NSArray <NSValue *> *)processOpen:(const char **)arglist pidPointer:(pid_t *)pid_p {
    
    if (!arglist || !pid_p) return (NULL);
    
    pid_t pid = 0;
    
    int pfd1[2];
    FILE *fp1 = NULL;
    
    int pfd2[2];
    FILE *fp2 = NULL;
    
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    
    if (pipe(pfd1) < 0 || pipe(pfd2) < 0)
        return (NULL);
    posix_spawn_file_actions_adddup2(&actions, pfd1[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&actions, pfd1[0]);
    posix_spawn_file_actions_adddup2(&actions, pfd2[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&actions, pfd2[0]);
    
    posix_spawn(&pid, arglist[0], &actions, NULL, (char **)arglist, (char **)XXTESharedEnvp());
    posix_spawn_file_actions_destroy(&actions);
    
    close(pfd1[1]);
    if ( (fp1 = fdopen(pfd1[0], "r")) == NULL)
        return (NULL);
    close(pfd2[1]);
    if ( (fp2 = fdopen(pfd2[0], "r")) == NULL)
        return (NULL);
    
    return @[ [NSValue valueWithPointer:fp1], [NSValue valueWithPointer:fp2] ];
}

- (int)processClose:(NSArray <NSValue *> *)fpArr pidPointer:(pid_t *)pid_p {
    
    if (!fpArr || !pid_p) return (-1);
    
    FILE *fp1 = [fpArr[0] pointerValue];
    FILE *fp2 = [fpArr[1] pointerValue];
    
    int stat;
    
    pid_t pid = *pid_p;
    
    if (fclose(fp1) == EOF)
        return (-1);
    if (fclose(fp2) == EOF)
        return (-1);
    
    while (waitpid(pid, &stat, 0) < 0)
        if (errno != EINTR)
            return (-1); /* error other than EINTR from waitpid() */
    
    if (WIFEXITED(stat)) {
        stat = WEXITSTATUS(stat);
    }
    
    return (stat); /* return child's termination status */
}

@end
