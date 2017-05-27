//
//  AppDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "AppDelegate.h"
#import "XXTESplitViewController.h"
#import "XXTENavigationController.h"
#import "XXTExplorerNavigationController.h"
#import "XXTEMoreNavigationController.h"
#import "XXTEMasterViewController.h"
#import "XXTExplorerViewController.h"
#import "XXTEMoreViewController.h"
#import "XXTEWorkspaceViewController.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Master - Explorer Controller
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:documentPath];
    XXTExplorerNavigationController *masterNavigationControllerLeft = [[XXTExplorerNavigationController alloc] initWithRootViewController:explorerViewController];
    
    // Master - More Controller
    XXTEMoreViewController *moreViewController = [[XXTEMoreViewController alloc] initWithStyle:UITableViewStyleGrouped];
    XXTEMoreNavigationController *masterNavigationControllerRight = [[XXTEMoreNavigationController alloc] initWithRootViewController:moreViewController];
    
    // Master Controller
    XXTEMasterViewController *masterViewController = [[XXTEMasterViewController alloc] init];
    masterViewController.viewControllers = @[masterNavigationControllerLeft, masterNavigationControllerRight];
    
    // Detail Controller
    XXTEWorkspaceViewController *detailViewController = [[XXTEWorkspaceViewController alloc] init];
    XXTENavigationController *detailNavigationController = [[XXTENavigationController alloc] initWithRootViewController:detailViewController];
    
    // Split Controller
    XXTESplitViewController *splitViewController = [[XXTESplitViewController alloc] init];
    splitViewController.delegate = self;
    splitViewController.viewControllers = @[masterViewController, detailNavigationController];
    
    // Add Split Button
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    
    UIWindow *mainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    mainWindow.backgroundColor = [UIColor whiteColor];
    mainWindow.rootViewController = splitViewController;
    [mainWindow makeKeyAndVisible];
    
    self.window = mainWindow;
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return YES;
}

@end
