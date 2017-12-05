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
    if ([self isDarkMode]) {
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
    return [self prefersNavigationBarHidden];
}

- (BOOL)prefersNavigationBarHidden {
    if (XXTE_PAD || NO == XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO))
    {
        return NO;
    }
    return [self isEditing];
}

#pragma mark - Navigation Bar Color

- (void)renderNavigationBarTheme:(BOOL)restore {
//    if (XXTE_PAD) return;
    UIColor *backgroundColor = XXTE_COLOR;
    UIColor *foregroundColor = [UIColor whiteColor];
    XXTEEditorTheme *theme = self.theme;
    UINavigationController *navigation = self.navigationController;
    if (restore == NO && theme) {
        if (theme.foregroundColor)
            foregroundColor = theme.foregroundColor;
        if (theme.backgroundColor)
            backgroundColor = theme.backgroundColor;
    }
    [navigation.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : foregroundColor}];
    navigation.navigationBar.tintColor = foregroundColor;
    navigation.navigationBar.barTintColor = backgroundColor;
    navigation.navigationItem.leftBarButtonItem.tintColor = foregroundColor;
    navigation.navigationItem.rightBarButtonItem.tintColor = foregroundColor;
    self.navigationItem.leftBarButtonItem.tintColor = foregroundColor;
    self.navigationItem.rightBarButtonItem.tintColor = foregroundColor;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
