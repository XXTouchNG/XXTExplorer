//
// Created by Zheng on 27/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEMailComposeViewController.h"
#import "UIColor+XUIDarkColor.h"

@implementation XXTEMailComposeViewController {

}

- (UIStatusBarStyle)preferredStatusBarStyle {
#ifndef APPSTORE
    return UIStatusBarStyleLightContent;
#else
    return UIStatusBarStyleDefault;
#endif
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

@end
