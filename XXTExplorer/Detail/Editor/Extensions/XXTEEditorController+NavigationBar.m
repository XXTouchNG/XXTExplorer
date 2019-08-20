//
//  XXTEEditorController+NavigationBar.m
//  XXTExplorer
//
//  Created by Zheng on 02/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+NavigationBar.h"

#import "XXTEEditorDefaults.h"

#import "XXTEEditorTheme.h"
#import "UIColor+XUIDarkColor.h"

#import "XXTEEditorToolbar.h"

@implementation XXTEEditorController (NavigationBar)

- (UIStatusBarStyle)preferredStatusBarStyle {
    BOOL prefersLightStatusBar = YES;
    if ([self shouldNavigationBarHidden]) {
        prefersLightStatusBar = [self isDarkMode];
    } else {
        UIColor *newColor = self.theme.barTintColor;
        if (!newColor) newColor = XXTColorBarTint();
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
    UIColor *newColor = self.theme.backgroundColor;
    if (!newColor) newColor = XXTColorBarTint();
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
    if (XXTE_IS_IPAD ||
        NO == XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO))
    {
        return NO;
    }
    return [self isEditing];
}

#pragma mark - Navigation Bar Color

- (void)renderNavigationBarTheme:(BOOL)restore {
    UIColor *barTintColor = XXTColorBarTint();
    UIColor *barTitleColor = XXTColorBarText();
    UIColor *tintColor = XXTColorTint();
    XXTEEditorTheme *theme = self.theme;
    UINavigationController *navigation = self.navigationController;
    if (restore == NO && theme) {
        if (theme.barTextColor) {
            barTitleColor = theme.barTextColor;
            tintColor = theme.barTextColor;
        }
        if (theme.barTintColor)
            barTintColor = theme.barTintColor;
    }
    [navigation.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : barTitleColor}];
    navigation.navigationBar.tintColor = tintColor;
    navigation.navigationBar.barTintColor = barTintColor;
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
