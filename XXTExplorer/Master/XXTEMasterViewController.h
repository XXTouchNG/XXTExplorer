//
//  XXTEMasterViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEUpdateHelper, XXTEUpdateAgent;

typedef enum : NSUInteger {
    kMasterViewControllerIndexExplorer = 0,
#ifdef RMCLOUD_ENABLED
    kMasterViewControllerIndexCloud,
#endif
    kMasterViewControllerIndexMore,
    kMasterViewControllerIndexMax,
} kMasterViewControllerIndex;

@interface XXTEMasterViewController : UITabBarController

- (void)setTabBarVisible:(BOOL)visible animated:(BOOL)animated completion:(void (^)(BOOL))completion;
- (BOOL)tabBarIsVisible;
- (CGRect)rectOfTabBarItemAtIndex:(NSUInteger)idx;

#ifndef APPSTORE
- (void)checkUpdate;
#endif

@end
