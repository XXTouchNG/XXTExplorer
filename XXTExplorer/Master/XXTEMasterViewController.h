//
//  XXTEMasterViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTExplorerViewController, XXTEUpdateHelper, XXTEUpdateAgent;

typedef enum : NSUInteger {
    kMasterViewControllerIndexExplorer = 0,
#ifdef RMCLOUD_ENABLED
    kMasterViewControllerIndexCloud,
#endif
    kMasterViewControllerIndexMore,
    kMasterViewControllerIndexMax,
} kMasterViewControllerIndex;

@interface XXTEMasterViewController : UITabBarController

#ifndef APPSTORE
- (void)checkUpdate;
#endif

#pragma mark - Convenience Getters

@property (nonatomic, strong, readonly) XXTExplorerViewController *topmostExplorerViewController;

@end
