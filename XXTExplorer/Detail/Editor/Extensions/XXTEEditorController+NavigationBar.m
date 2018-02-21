//
//  XXTEEditorController+NavigationBar.m
//  XXTExplorer
//
//  Created by Zheng on 02/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+NavigationBar.h"

#import "XXTEAppDefines.h"
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
        if (!newColor) newColor = XXTE_COLOR;
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
    if (!newColor) newColor = XXTE_COLOR;
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
    if (XXTE_PAD ||
        NO == XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO))
    {
        return NO;
    }
    return [self isEditing];
}

#pragma mark - Navigation Bar Color

- (void)renderNavigationBarTheme:(BOOL)restore {
    UIColor *barTintColor = XXTE_COLOR;
    UIColor *barTitleColor = [UIColor whiteColor];
    XXTEEditorTheme *theme = self.theme;
    UINavigationController *navigation = self.navigationController;
    if (restore == NO && theme) {
        if (theme.barTextColor)
            barTitleColor = theme.barTextColor;
        if (theme.barTintColor)
            barTintColor = theme.barTintColor;
    }
    [navigation.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : barTitleColor}];
    navigation.navigationBar.tintColor = barTitleColor;
    navigation.navigationBar.barTintColor = barTintColor;
    navigation.navigationItem.leftBarButtonItem.tintColor = barTitleColor;
    navigation.navigationItem.rightBarButtonItem.tintColor = barTitleColor;
    for (UIBarButtonItem *item in navigation.navigationItem.leftBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    for (UIBarButtonItem *item in navigation.navigationItem.rightBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    self.navigationItem.leftBarButtonItem.tintColor = barTitleColor;
    self.navigationItem.rightBarButtonItem.tintColor = barTitleColor;
    for (UIBarButtonItem *item in self.navigationItem.leftBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
        item.tintColor = barTitleColor;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
