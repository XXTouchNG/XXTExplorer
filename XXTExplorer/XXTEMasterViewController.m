//
//  XXTEMasterViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMasterViewController.h"

@interface XXTEMasterViewController ()

@end

@implementation XXTEMasterViewController

//#pragma mark - Restore State
//
//- (NSString *)restorationIdentifier {
//    return [NSString stringWithFormat:@"com.xxtouch.restoration.%@", NSStringFromClass(self.class)];
//}

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
//        [self setRestorationIdentifier:self.restorationIdentifier];
        [self setupAppearance];
    }
    return self;
}

- (void)setupAppearance {
    [[UITabBar appearanceWhenContainedIn:[self class], nil] setTintColor:XXTE_COLOR];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.selectedViewController.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.selectedViewController.prefersStatusBarHidden;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.selectedViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.selectedViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
