//
//  XXTECodeViewerController+NavigationBar.m
//  XXTExplorer
//
//  Created by Darwin on 8/1/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTECodeViewerController+NavigationBar.h"
#import "UIColor+XUIDarkColor.h"

@implementation XXTECodeViewerController (NavigationBar)

- (UIStatusBarStyle)preferredStatusBarStyle {
    BOOL prefersLightStatusBar = YES;
    if ([self shouldNavigationBarHidden]) {
        prefersLightStatusBar = [self isDarkMode];
    } else {
        UIColor *newColor = self.barTintColor;
        if (!newColor) newColor = XXTColorDefault();
        prefersLightStatusBar = [newColor xui_isDarkColor];
    }
    if (prefersLightStatusBar) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (BOOL)isDarkMode
{
    UIColor *newColor = self.backgroundColor;
    if (!newColor) newColor = XXTColorDefault();
    return [newColor xui_isDarkColor];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)xxte_prefersNavigationBarHidden {
    return [self shouldNavigationBarHidden];
}

- (BOOL)prefersNavigationBarHidden
{
    return [self shouldNavigationBarHidden];
}

- (BOOL)shouldNavigationBarHidden {
    return NO;
}

#pragma mark - Navigation Bar Color

- (void)renderNavigationBarTheme:(BOOL)restore {
    UIColor *barTintColor = XXTColorDefault();
    UIColor *barTitleColor = [UIColor whiteColor];
    UINavigationController *navigation = self.navigationController;
    if (restore == NO) {
        if (self.barTextColor)
        barTitleColor = self.barTextColor;
        if (self.barTintColor)
        barTintColor = self.barTintColor;
    }
    [navigation.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : barTitleColor}];
    navigation.navigationBar.tintColor = barTitleColor;
    navigation.navigationBar.barTintColor = barTintColor;
    navigation.navigationItem.leftBarButtonItem.tintColor = barTitleColor;
    navigation.navigationItem.rightBarButtonItem.tintColor = barTitleColor;
    navigation.navigationItem.titleView.tintColor = barTitleColor;
    for (UIBarButtonItem *item in navigation.navigationItem.leftBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    for (UIBarButtonItem *item in navigation.navigationItem.rightBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    self.navigationItem.leftBarButtonItem.tintColor = barTitleColor;
    self.navigationItem.rightBarButtonItem.tintColor = barTitleColor;
    self.navigationItem.titleView.tintColor = barTitleColor;
    for (UIBarButtonItem *item in self.navigationItem.leftBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
