//
//  XXTENavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTENavigationController.h"

@interface XXTENavigationController ()

@end

@implementation XXTENavigationController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.topViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.topViewController.prefersStatusBarHidden;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearanceWhenContainedIn:[self class], nil];
    [navigationBarAppearance setTranslucent:NO];
    [navigationBarAppearance setTintColor:[UIColor whiteColor]];
    [navigationBarAppearance setBarTintColor:XXTE_COLOR];
    [navigationBarAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    
    UIBarButtonItem *barButtonItemAppearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
    [barButtonItemAppearance setTintColor:[UIColor whiteColor]];
    
}

@end
