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


#import "zip.h"

#import "UIViewController+TopMostViewController.h"

static NSString * const kXXTEShortcutAction = @"XXTEShortcutAction";
static NSString * const kXXTELaunchedVersion = @"XXTELaunchedVersion-%@";
static NSString * const kXXTEExtractedResourceName = @"XXTEExtractedResourceName-%@";

@interface XXTEAppDelegate ()


@end

@implementation XXTEAppDelegate {
    
}

#pragma mark - Application

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // restore defaults
    [[self class] appDefines];
    NSUserDefaults *userDefaults = [[self class] userDefaults];
    NSDictionary *builtInDefaults = [[self class] builtInDefaults];
    NSArray <NSDictionary *> *sectionMetas = builtInDefaults[@"SECTION_META"];
    for (NSDictionary *sectionMeta in sectionMetas) {
        NSString *metaKey = sectionMeta[@"key"];
        NSArray <NSDictionary *> *explorerUserDefaults = builtInDefaults[metaKey];
        for (NSDictionary *explorerUserDefault in explorerUserDefaults) {
            NSString *defaultKey = explorerUserDefault[@"key"];
            if (![userDefaults objectForKey:defaultKey]) {
                id defaultValue = explorerUserDefault[@"default"];
                if (defaultValue) {
                    [userDefaults setObject:defaultValue forKey:defaultKey];
                }
            }
        }
    }
    
    // create required subdirectories
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
        [self rootDirectoryForCloud:^(NSURL *url) {
            NSLog(@"%@", url);
        }];
    }
    
    UIWindow *mainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [mainWindow makeKeyAndVisible];
    self.window = mainWindow;
    
    [self reloadWorkspace];
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
#ifdef DEBUG
    NSLog(@"!!! LOG %@", [NSLocale currentLocale].localeIdentifier);
    NSLog(@"!!! LOG %@", [NSLocale systemLocale].localeIdentifier);
    NSLog(@"!!! LOG %@", [NSLocale preferredLanguages]);
    NSLog(@"!!! LOG %@", [NSTimeZone localTimeZone]);
    NSLog(@"!!! LOG %@", [NSTimeZone systemTimeZone]);
#endif
    
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
        // Extract in Background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *rootPath = [[self class] sharedRootPath];
            NSArray <NSDictionary *> *copyResources = uAppDefine(@"INITIAL_RESOURCES");
            for (NSDictionary *copyResource in copyResources) {
                NSString *from = copyResource[@"from"];
                if (![from isKindOfClass:[NSString class]]) {
                    continue;
                }
                NSString *fromPath = [[NSBundle mainBundle] pathForResource:from ofType:@"zip"];
                NSString *to = copyResource[@"to"];
                if (![to isKindOfClass:[NSString class]]) {
                    continue;
                }
                BOOL shouldCopyResources = NO;
                NSString *resourceFlag = [NSString stringWithFormat:kXXTEExtractedResourceName, from];
                if (XXTEDefaultsObject(resourceFlag, nil) == nil) {
                    shouldCopyResources = YES;
                    XXTEDefaultsSetBasic(resourceFlag, YES);
                }
                if (!shouldCopyResources) {
                    continue;
                }
                NSString *toPath = [rootPath stringByAppendingPathComponent:to];
                int (^will_extract)(const char *, void *) = ^int(const char *filename, void *arg) {
                    return zip_extract_override;
                };
                int (^extract_callback)(const char *, void *) = ^int(const char *filename, void *arg) {
                    NSLog(@"Extract \"%s\"...", filename);
                    return 0;
                };
                int arg = 2;
                int status = zip_extract(fromPath.UTF8String, toPath.UTF8String, will_extract, extract_callback, &arg);
                BOOL result = (status == 0);
                if (result) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:application userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeApplicationDidExtractResource}]];
                    });
                }
            }
        });
    }
    
    // Setup Shortcut Actions
    {
        XXTE_START_IGNORE_PARTIAL
        UIApplicationShortcutIcon *stopIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"XXTEShortcut-Stop"];
        UIApplicationShortcutItem *stopItem = [[UIApplicationShortcutItem alloc] initWithType:@"Stop" localizedTitle:NSLocalizedString(@"Stop", nil) localizedSubtitle:NSLocalizedString(@"Stop Current Script", nil) icon:stopIcon userInfo:@{ kXXTEShortcutAction: @"stop" }];
        UIApplicationShortcutIcon *launchIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"XXTEShortcut-Launch"];
        UIApplicationShortcutItem *launchItem = [[UIApplicationShortcutItem alloc] initWithType:@"Launch" localizedTitle:NSLocalizedString(@"Launch", nil) localizedSubtitle:NSLocalizedString(@"Launch Selected Script", nil) icon:launchIcon userInfo:@{ kXXTEShortcutAction: @"launch" }];
        UIApplicationShortcutIcon *scanIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"XXTEShortcut-Scan"];
        UIApplicationShortcutItem *scanItem = [[UIApplicationShortcutItem alloc] initWithType:@"Scan" localizedTitle:NSLocalizedString(@"QR Scan", nil) localizedSubtitle:NSLocalizedString(@"QRCode Scan", nil) icon:scanIcon userInfo:@{ kXXTEShortcutAction : @"scan" }];
        [UIApplication sharedApplication].shortcutItems = @[stopItem, launchItem, scanItem];
        XXTE_END_IGNORE_PARTIAL
    }
    
    // Launched Version
    {
        NSString *currentVersion = uAppDefine(kXXTDaemonVersionKey);
        NSString *versionFlag = [NSString stringWithFormat:kXXTELaunchedVersion, currentVersion];
        if (XXTEDefaultsObject(versionFlag, nil) == nil) {
            XXTEDefaultsSetBasic(versionFlag, YES);
        }
    }
    
    // Launched Times
    {
        NSInteger launchedTimes = XXTEDefaultsInt(kXXTELaunchedTimes, 0);
        launchedTimes++;
#ifdef DEBUG
        NSLog(@"Launched %ld times.", (long)launchedTimes);
#endif
        XXTEDefaultsSetBasic(kXXTELaunchedTimes, launchedTimes);
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


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    static BOOL isBootstrap = YES;
    if (!isBootstrap) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:application userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeApplicationDidBecomeActive}]];
    } else {
        isBootstrap = NO;
    }
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

#pragma mark - UIApplicationDelegate

XXTE_START_IGNORE_PARTIAL
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(id)annotation
{
    BOOL inApp = [sourceApplication isEqualToString:[[NSBundle mainBundle] bundleIdentifier]];
    return [self application:application openURL:url withDelay:!inApp];
}
XXTE_END_IGNORE_PARTIAL

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
        BOOL handleNativeOnly = [self application:application handleNativeEvents:userInfo];
        if (handleNativeOnly) {
            return YES;
        }
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
    if (shortcutItem.userInfo[kXXTEShortcutAction]) {
        NSString *shortcutAction = (NSString *)shortcutItem.userInfo[kXXTEShortcutAction];
        NSDictionary *userInfo =
        @{XXTENotificationShortcutInterface: shortcutAction,
          XXTENotificationShortcutUserData: [NSNull null]};
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.6f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationShortcut object:application userInfo:userInfo]];
        });
    }
}
XXTE_END_IGNORE_PARTIAL

- (BOOL)application:(UIApplication *)application handleNativeEvents:(NSDictionary *)userInfo {
    NSString *shortcutInterface = userInfo[XXTENotificationShortcutInterface];
    if ([shortcutInterface isEqualToString:@"workspace"]) {
        UIViewController *rootController = self.window.rootViewController;
        UIViewController *controller = rootController.topMostViewController;
        [controller dismissModalStackAnimated:YES];
        return NO;
    }
    return NO;
}

#pragma mark - Reload

- (void)dismissTopMostViewController {
    // no implementation
}

- (void)reloadWorkspace {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        UIWindow *mainWindow = self.window;
        
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
            // Detail Controller
            XXTEWorkspaceViewController *detailViewController = [[XXTEWorkspaceViewController alloc] init];
            XXTENavigationController *detailNavigationController = [[XXTENavigationController alloc] initWithRootViewController:detailViewController];
            
            // Split Controller
            XXTESplitViewController *splitViewController = [[XXTESplitViewController alloc] init];
            splitViewController.viewControllers = @[masterViewController, detailNavigationController];
            mainWindow.rootViewController = splitViewController;
        }
        
    });
    
}

#pragma mark - App Defines

+ (NSDictionary *)appDefines {
    static NSDictionary *localAppDefines = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!localAppDefines) {
            localAppDefines = ({
                NSDictionary *appDefines = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"XXTEAppDefines" ofType:@"plist"]];
                appDefines;
            });
#ifdef DEBUG
            NSLog(@"App Defines: %@", localAppDefines);
#endif
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
#ifdef DEBUG
            NSLog(@"User Defaults: %@", [userDefaults dictionaryRepresentation]);
#endif
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
#ifdef ARCHIVE
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

- (void)rootDirectoryForCloud:(void (^)(NSURL *))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *rootDirectory = [[manager URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
        if (rootDirectory) {
            if (![manager fileExistsAtPath:rootDirectory.path isDirectory:nil]) {
                [manager createDirectoryAtURL:rootDirectory withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(rootDirectory);
        });
    });
}

@end
