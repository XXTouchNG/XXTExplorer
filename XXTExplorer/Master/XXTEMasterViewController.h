//
//  XXTEMasterViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTENavigationController.h"

@class XXTExplorerViewController, XXTEUpdateHelper, XXTEUpdateAgent;
@class LGAlertView;

typedef enum : NSUInteger {
    kMasterViewControllerIndexExplorer = 0,
#ifndef APPSTORE
#ifdef RMCLOUD_ENABLED
    kMasterViewControllerIndexCloud,
#endif
    kMasterViewControllerIndexMore,
#endif
    kMasterViewControllerIndexMax,
} kMasterViewControllerIndex;

#ifndef APPSTORE
@interface XXTEMasterViewController : UITabBarController
#else
@interface XXTEMasterViewController : XXTENavigationController
#endif

#ifndef APPSTORE
- (void)checkUpdate;
#endif

#pragma mark - Convenience Getters
@property (nonatomic, strong, readonly) XXTExplorerViewController *topmostExplorerViewController;

#pragma mark - Pre-Defined Appearances
+ (void)setupAlertDefaultAppearance:(LGAlertView *)alertAppearance;
+ (void)setupAlertDarkAppearance:(LGAlertView *)alertAppearance;

@end
