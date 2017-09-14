//
//  UIViewController+StatusBar.m
//  XXTExplorer
//
//  Created by Zheng on 01/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UIViewController+StatusBar.h"
#import "UIColor+DarkColor.h"

@implementation UIViewController (StatusBar)

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.navigationController) {
        if ([self.navigationController.navigationBar.tintColor isDarkColor]) {
            return UIStatusBarStyleDefault;
        } else {
            return UIStatusBarStyleLightContent;
        }
    }
    return UIStatusBarStyleLightContent;
}

@end
