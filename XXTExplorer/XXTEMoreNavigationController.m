//
//  XXTEMoreNavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreNavigationController.h"

@interface XXTEMoreNavigationController ()

@end

@implementation XXTEMoreNavigationController

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"More", nil) image:[UIImage imageNamed:@"XXTEMoreTabbarIcon"] tag:1];
}

@end
