//
//  main.m
//  XXTExplorer
//

#import "XXTEAppDelegate.h"

#ifndef DEBUG
#import <UIKit/UIKit.h>

// For debugger_ptrace. Ref: https://www.theiphonewiki.com/wiki/Bugging_Debuggers
#import <dlfcn.h>
#import <sys/types.h>

// For debugger_sysctl
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>
#include <stdlib.h>

// For ioctl
#include <termios.h>
#include <sys/ioctl.h>

// For task_get_exception_ports
#include <mach/task.h>
#include <mach/mach_init.h>

typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);

#if !defined(PT_DENY_ATTACH)
#define PT_DENY_ATTACH 31
#endif  // !defined(PT_DENY_ATTACH)

/*!
 @brief This is the basic ptrace functionality.
 @link http://www.coredump.gr/articles/ios-anti-debugging-protections-part-1/
 */
void debugger_ptrace()
{
    void* handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
    ptrace_ptr_t ptrace_ptr = dlsym(handle, "ptrace");
    ptrace_ptr(PT_DENY_ATTACH, 0, 0, 0);
    dlclose(handle);
}

/*!
 @brief This function uses sysctl to check for attached debuggers.
 @link https://developer.apple.com/library/mac/qa/qa1361/_index.html
 @link http://www.coredump.gr/articles/ios-anti-debugging-protections-part-2/
 */
static bool debugger_sysctl(void)
// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
{
    int mib[4];
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    if (sysctl(mib, 4, &info, &info_size, NULL, 0) == -1)
    {
        exit(13);
    }
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ((info.kp_proc.p_flag & P_TRACED) != 0);
}

/* Set platform binary flag */
#define FLAG_PLATFORMIZE (1 << 1)

/**
 * function for jailbroken iOS 11 by Electra
 *
 * @license GPL-3.0 (cydia) https://github.com/ElectraJailbreak/cydia/blob/master/COPYING
 * @see https://github.com/coolstar/electra/blob/master/docs/getting-started.md
 * @see https://github.com/ElectraJailbreak/cydia/blob/master/cydo.cpp
 */
void patch_setuidandplatformize()
{
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) return;
    
    // Reset errors
    dlerror();
    
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t setuidptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");
    
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t entitleptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
    
    setuidptr(getpid());
    
    setuid(0);
    
    const char *dlsym_error = dlerror();
    if (dlsym_error) {
        return;
    }
    
    entitleptr(getpid(), FLAG_PLATFORMIZE);
}

#endif

void plugin_i_love_xxtouch() {
    
}

int main(int argc, char * argv[]) {
    
    {
        setuid(0);
        setgid(0);
    }
    
#ifndef DEBUG
    // If enabled the program should exit with code 055 in GDB
    // Program exited with code 055.
    debugger_ptrace();
    
    // If enabled the program should exit with code 0377 in GDB
    // Program exited with code 0377.
    if (debugger_sysctl())
    {
        exit(13);
        return 13;
    }
    
    // Another way of calling ptrace.
    // Ref: https://www.theiphonewiki.com/wiki/Kernel_Syscalls
    syscall(26, 31, 0, 0);
    
    
    // Another way of figuring out if LLDB is attached.
    if (isatty(1)) {
        exit(13);
        return 13;
    }
    
    // Yet another way of figuring out if LLDB is attached.
    if (!ioctl(1, TIOCGWINSZ)) {
        exit(13);
        return 13;
    }
    
    // Everything above relies on libraries. It is easy enough to hook these libraries and return the required
    // result to bypass those checks. So here it is implemented in ARM assembly. Not very fun to bypass these.
#ifdef __arm__
    asm volatile (
                  "mov r0, #31\n"
                  "mov r1, #0\n"
                  "mov r2, #0\n"
                  "mov r12, #26\n"
                  "svc #80\n"
                  );
#endif
#ifdef __arm64__
    asm volatile (
                  "mov x0, #26\n"
                  "mov x1, #31\n"
                  "mov x2, #0\n"
                  "mov x3, #0\n"
                  "mov x16, #0\n"
                  "svc #128\n"
                  );
#endif
    
#endif
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([XXTEAppDelegate class]));
    }
}
