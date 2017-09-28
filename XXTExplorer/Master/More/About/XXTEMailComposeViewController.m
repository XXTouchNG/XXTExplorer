//
// Created by Zheng on 27/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEMailComposeViewController.h"
#import "UIColor+DarkColor.h"

@implementation XXTEMailComposeViewController {

}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.navigationBar.tintColor isDarkColor] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

@end
