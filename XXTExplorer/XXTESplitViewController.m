//
//  XXTESplitViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESplitViewController.h"

@interface XXTESplitViewController ()

@end

@implementation XXTESplitViewController

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.viewControllers[0];
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.viewControllers[0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
