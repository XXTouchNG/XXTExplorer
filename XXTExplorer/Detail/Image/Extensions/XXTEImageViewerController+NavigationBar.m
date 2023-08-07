//
//  XXTEImageViewerController+NavigationBar.m
//  XXTExplorer
//
//  Created by Darwin on 8/20/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEImageViewerController+NavigationBar.h"

@implementation XXTEImageViewerController (NavigationBar)

#pragma mark - Navigation Bar Color

- (void)renderNavigationBarTheme:(BOOL)restore {
    UIColor *barTintColor = XXTColorBarTint();
    UIColor *barTitleColor = XXTColorBarText();
    UIColor *tintColor = XXTColorTint();
    UINavigationController *navigation = self.navigationController;
    if (!restore) {
        barTintColor = [UIColor colorWithRed:0x1D/255.0 green:0x1F/255.0 blue:0x21/255.0 alpha:1.0];
        barTitleColor = [UIColor whiteColor];
        tintColor = [UIColor whiteColor];
    }
    UINavigationBarAppearance *navigationBarAppearance = [[UINavigationBarAppearance alloc] init];
    [navigationBarAppearance configureWithOpaqueBackground];
    [navigationBarAppearance setBackgroundColor:barTintColor];
    [navigationBarAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName: barTitleColor, NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    [navigation.navigationBar setStandardAppearance:navigationBarAppearance];
    [navigation.navigationBar setScrollEdgeAppearance:navigationBarAppearance];
    [navigation.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: barTitleColor, NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    navigation.navigationBar.tintColor = tintColor;
    navigation.navigationItem.leftBarButtonItem.tintColor = tintColor;
    navigation.navigationItem.rightBarButtonItem.tintColor = tintColor;
    navigation.navigationItem.titleView.tintColor = barTitleColor;
    for (UIBarButtonItem *item in navigation.navigationItem.leftBarButtonItems) {
        item.tintColor = tintColor;
    }
    for (UIBarButtonItem *item in navigation.navigationItem.rightBarButtonItems) {
        item.tintColor = tintColor;
    }
    self.navigationItem.leftBarButtonItem.tintColor = tintColor;
    self.navigationItem.rightBarButtonItem.tintColor = tintColor;
    self.navigationItem.titleView.tintColor = barTitleColor;
    for (UIBarButtonItem *item in self.navigationItem.leftBarButtonItems) {
        item.tintColor = tintColor;
    }
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
        item.tintColor = tintColor;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
