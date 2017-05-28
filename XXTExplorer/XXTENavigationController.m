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

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UINavigationBar appearanceWhenContainedIn:[self class], nil] setTranslucent:NO];
    [[UINavigationBar appearanceWhenContainedIn:[self class], nil] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedIn:[self class], nil] setBarTintColor:XXTE_COLOR];
    [[UINavigationBar appearanceWhenContainedIn:[self class], nil] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    [[UIBarButtonItem appearanceWhenContainedIn:[self class], nil] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
}

@end
