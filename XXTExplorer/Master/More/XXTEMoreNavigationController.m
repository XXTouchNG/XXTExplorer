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
        NSAssert(NO, @"XXTEMoreNavigationController must be initialized with a rootViewController.");
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        static BOOL alreadyInitialized = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSAssert(NO == alreadyInitialized, @"XXTEMoreNavigationController is a singleton.");
            alreadyInitialized = YES;
            [self setup];
        });
    }
    return self;
}

- (void)setup {
    
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"More", nil) image:[UIImage imageNamed:@"XXTEMoreTabbarIcon"] tag:1];
}

- (void)dealloc {
    
}

@end
