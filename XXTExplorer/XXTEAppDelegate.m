//
//  XXTEAppDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <unistd.h>
#import <sys/stat.h>

#import "XXTEAppDelegate.h"
#import "XXTESplitViewController.h"
#import "XXTENavigationController.h"
#import "XXTExplorerNavigationController.h"
#import "XXTEMoreNavigationController.h"
#import "XXTEMasterViewController.h"
#import "XXTExplorerViewController.h"
#import "XXTEMoreViewController.h"
#import "XXTEWorkspaceViewController.h"
#import "XXTENotificationCenterDefines.h"
#import "XXTECommonNavigationController.h"

#import "XXTEAppDefines.h"

#import "zip.h"
#import <Bugly/Bugly.h>
#import "XXTECloudApiSdk.h"
#import "XXTENetworkDefines.h"

static NSString * const XXTEShortcutAction = @"XXTEShortcutAction";
static NSString * const XXTELaunchedVersion = @"XXTELaunchedVersion-%@";

@interface XXTEAppDelegate ()

@end

@implementation XXTEAppDelegate {
    
}

#pragma mark - Application

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Create required subdirectories
    {
        NSString *sharedRootPath = [XXTEAppDelegate sharedRootPath];
        NSArray <NSString *> *requiredSubdirectories = uAppDefine(@"REQUIRED_SUBDIRECTORIES");
        for (NSString *requiredSubdirectory in requiredSubdirectories) {
            NSString *directoryPath = [sharedRootPath stringByAppendingPathComponent:requiredSubdirectory];
            const char *directoryPathCStr = [directoryPath UTF8String];
            struct stat subdirectoryStat;
            if (0 != lstat(directoryPathCStr, &subdirectoryStat))
                if (0 != mkdir(directoryPathCStr, 0755))
                    continue;
        }
    }
    
    // Master - Explorer Controller
    XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] init];
    XXTExplorerNavigationController *masterNavigationControllerLeft = [[XXTExplorerNavigationController alloc] initWithRootViewController:explorerViewController];
    
    // Master - More Controller
    XXTEMoreViewController *moreViewController = [[XXTEMoreViewController alloc] initWithStyle:UITableViewStyleGrouped];
    XXTEMoreNavigationController *masterNavigationControllerRight = [[XXTEMoreNavigationController alloc] initWithRootViewController:moreViewController];
    
    // Master Controller
    XXTEMasterViewController *masterViewController = [[XXTEMasterViewController alloc] init];
    masterViewController.viewControllers = @[masterNavigationControllerLeft, masterNavigationControllerRight];
    
    {
        if (@available(iOS 8.0, *)) {
            // Detail Controller
            XXTEWorkspaceViewController *detailViewController = [[XXTEWorkspaceViewController alloc] init];
            XXTECommonNavigationController *detailNavigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:detailViewController];
            
            // Split Controller
            XXTESplitViewController *splitViewController = [[XXTESplitViewController alloc] init];
            splitViewController.viewControllers = @[masterViewController, detailNavigationController];
            
            UIWindow *mainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            mainWindow.tintColor = XXTE_COLOR;
            mainWindow.backgroundColor = [UIColor whiteColor];
            mainWindow.rootViewController = splitViewController;
            [mainWindow makeKeyAndVisible];
            
            self.window = mainWindow;
        } else {
            UIWindow *mainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            mainWindow.tintColor = XXTE_COLOR;
            mainWindow.backgroundColor = [UIColor whiteColor];
            mainWindow.rootViewController = masterViewController;
            [mainWindow makeKeyAndVisible];
            
            self.window = mainWindow;
        }
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Setup Bugly
    {
        [Bugly startWithAppId:nil];
    }
    
    // Setup Envp
    {
        NSDictionary *envp = uAppConstEnvp();
        for (NSString *envpKey in envp) {
            NSString *envpVal = envp[envpKey];
            setenv(envpKey.UTF8String, envpVal.UTF8String, true);
        }
    }
    
    // Copy Initial Resources
    {
        BOOL shouldCopyResources = NO;
        NSString *currentVersion = uAppDefine(@"DAEMON_VERSION");
        NSString *versionFlag = [NSString stringWithFormat:XXTELaunchedVersion, currentVersion];
        if (XXTEDefaultsObject(versionFlag, nil) == nil) {
            shouldCopyResources = YES;
            XXTEDefaultsSetObject(versionFlag, @(YES));
        }
        if (shouldCopyResources)
        {
            // Extract in Background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSString *rootPath = [[self class] sharedRootPath];
                NSArray <NSDictionary *> *copyResources = uAppDefine(@"INITIAL_RESOURCES");
                for (NSDictionary *copyResource in copyResources) {
                    NSString *from = copyResource[@"from"];
                    NSString *fromPath = [[NSBundle mainBundle] pathForResource:from ofType:@"zip"];
                    NSString *to = copyResource[@"to"];
                    NSString *toPath = [rootPath stringByAppendingPathComponent:to];
                    int (^extract_callback)(const char *, void *) = ^int(const char *filename, void *arg) {
                        NSLog(@"Extract \"%@\"...", [[NSString alloc] initWithUTF8String:filename]);
                        return 0;
                    };
                    int arg = 2;
                    int status = zip_extract(fromPath.UTF8String, toPath.UTF8String, extract_callback, &arg);
                    BOOL result = (status == 0);
                    if (result) {
                        
                    }
                }
            });
        }
    }
    
    // Setup Shortcut Actions
    {
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            UIApplicationShortcutIcon *stopIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"XXTEShortcut-Stop"];
            UIApplicationShortcutItem *stopItem = [[UIApplicationShortcutItem alloc] initWithType:@"Stop" localizedTitle:NSLocalizedString(@"Stop", nil) localizedSubtitle:nil icon:stopIcon userInfo:@{ XXTEShortcutAction: @"stop" }];
            UIApplicationShortcutIcon *launchIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"XXTEShortcut-Launch"];
            UIApplicationShortcutItem *launchItem = [[UIApplicationShortcutItem alloc] initWithType:@"Launch" localizedTitle:NSLocalizedString(@"Launch", nil) localizedSubtitle:nil icon:launchIcon userInfo:@{ XXTEShortcutAction: @"launch" }];
            UIApplicationShortcutIcon *scanIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"XXTEShortcut-Scan"];
            UIApplicationShortcutItem *scanItem = [[UIApplicationShortcutItem alloc] initWithType:@"Scan" localizedTitle:NSLocalizedString(@"QR Scan", nil) localizedSubtitle:nil icon:scanIcon userInfo:@{ XXTEShortcutAction : @"scan" }];
            [UIApplication sharedApplication].shortcutItems = @[stopItem, launchItem, scanItem];
        }
        XXTE_END_IGNORE_PARTIAL
    }
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:application userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeApplicationDidEnterBackground}]];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:application userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeApplicationDidBecomeActive}]];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Restoration

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(nonnull NSCoder *)coder {
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return YES;
}

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    return nil;
}

#pragma mark - Open URL

/*
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if (@available(iOS 9.0, *)) {
        return NO;
    }
    return [self application:application openURL:url];
}
*/

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(id)annotation
{
    XXTE_START_IGNORE_PARTIAL
    BOOL inApp = [sourceApplication isEqualToString:[[NSBundle mainBundle] bundleIdentifier]];
    return [self application:application openURL:url withDelay:!inApp];
    XXTE_END_IGNORE_PARTIAL
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(nonnull NSDictionary<NSString *,id> *)options
{
    XXTE_START_IGNORE_PARTIAL
    BOOL inApp = [options[UIApplicationOpenURLOptionsSourceApplicationKey] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]];
    return [self application:application openURL:url withDelay:!inApp];
    XXTE_END_IGNORE_PARTIAL
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url withDelay:(BOOL)delay {
    if ([[url scheme] isEqualToString:@"xxt"]) {
        NSURL *xxtCommandURL = url;
        NSString *xxtCommandInterface = [xxtCommandURL host];
        NSArray <NSString *> *xxtComponents = [xxtCommandURL pathComponents];
        NSString *xxtUserData = [xxtCommandURL query];
        if (!xxtUserData) xxtUserData = @"";
        if (xxtCommandInterface.length <= 0 ||
            xxtComponents.count != 1 ||
            ![xxtComponents[0] isEqualToString:@"/"]) {
            return NO;
        }
        NSDictionary *userInfo =
        @{XXTENotificationShortcutInterface: xxtCommandInterface,
          XXTENotificationShortcutUserData: xxtUserData};
        if (delay) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationShortcut object:application userInfo:userInfo]];
            });
        } else {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationShortcut object:application userInfo:userInfo]];
        }
    } else if ([[url scheme] isEqualToString:@"file"]) {
        if (delay) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:url userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeInbox}]];
            });
        } else {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:url userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeInbox}]];
        }
    }
    return NO;
}

XXTE_START_IGNORE_PARTIAL
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    if (shortcutItem.userInfo[XXTEShortcutAction]) {
        NSString *shortcutAction = (NSString *)shortcutItem.userInfo[XXTEShortcutAction];
        NSDictionary *userInfo =
        @{XXTENotificationShortcutInterface: shortcutAction,
          XXTENotificationShortcutUserData: @""};
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationShortcut object:application userInfo:userInfo]];
        });
    }
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - App Defines

+ (NSDictionary *)appDefines {
    static NSDictionary *localAppDefines = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!localAppDefines) {
            localAppDefines = ({
                NSDictionary *appDefines = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"XXTEAppDefines" ofType:@"plist"]];
                [[XXTECloudAppConfiguration instance] setAPP_KEY:appDefines[@"ALIYUN_APPKEY"]];
                [[XXTECloudAppConfiguration instance] setAPP_SECRET:appDefines[@"ALIYUN_APPSECRERT"]];
                [[XXTECloudAppConfiguration instance] setAPP_CONNECTION_TIMEOUT:[appDefines[@"APP_CONNECTION_TIMEOUT"] intValue]];
                appDefines;
            });
        }
    });
    return localAppDefines;
}

+ (NSUserDefaults *)userDefaults {
    static NSUserDefaults *userDefaults = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!userDefaults) {
            userDefaults = ({
                [NSUserDefaults standardUserDefaults];
            });
        }
    });
    return userDefaults;
}

+ (NSDictionary *)builtInDefaults {
    static NSDictionary *builtInDefaults = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!builtInDefaults) {
            builtInDefaults = ({
                NSString *builtInDefaultsPath = [[NSBundle mainBundle] pathForResource:@"XXTEBuiltInDefaults" ofType:@"plist"];
                [[NSDictionary alloc] initWithContentsOfFile:builtInDefaultsPath];
            });
        }
    });
    return builtInDefaults;
}

+ (NSString *)sharedRootPath {
    static NSString *rootPath = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!rootPath) {
            rootPath = ({
#ifndef DEBUG
                NSString *mainPath = uAppDefine(@"MAIN_PATH");
#else
                NSString *mainPath = nil;
#endif
                const char *mainPathCStr = [mainPath UTF8String];
                if (!mainPath) {
                    mainPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                } else if (0 != access(mainPathCStr, F_OK)) {
                    mkdir(mainPathCStr, 0755);
                }
                mainPath;
            });
        }
    });
    return rootPath;
}

@end
