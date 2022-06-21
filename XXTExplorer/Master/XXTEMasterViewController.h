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
    kMasterViewControllerIndexMore,
    kMasterViewControllerIndexMax,
} kMasterViewControllerIndex;

@interface XXTEMasterViewController : UITabBarController
- (void)checkUpdate;

#pragma mark - Convenience Getters
@property (nonatomic, strong, readonly) XXTExplorerViewController *topmostExplorerViewController;

#pragma mark - Pre-Defined Appearances
+ (void)setupAlertDefaultAppearance:(LGAlertView *)alertAppearance;
+ (void)setupAlertDarkAppearance:(LGAlertView *)alertAppearance;

@end
