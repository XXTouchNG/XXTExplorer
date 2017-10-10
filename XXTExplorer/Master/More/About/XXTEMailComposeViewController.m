//
// Created by Zheng on 27/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEMailComposeViewController.h"
#import "UIColor+XUIDarkColor.h"

@implementation XXTEMailComposeViewController {

}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.navigationBar.tintColor xui_isDarkColor] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

@end
