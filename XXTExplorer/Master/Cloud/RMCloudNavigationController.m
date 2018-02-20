//
//  RMCloudNavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudNavigationController.h"

@interface RMCloudNavigationController ()

@end

@implementation RMCloudNavigationController

- (instancetype)init {
    if (self = [super init]) {
        NSAssert(NO, @"RMCloudNavigationController must be initialized with a rootViewController.");
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        static BOOL alreadyInitialized = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSAssert(NO == alreadyInitialized, @"RMCloudNavigationController is a singleton.");
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
    
    if (@available(iOS 11.0, *)) {
        self.navigationBar.translucent = YES;
    } else {
        self.navigationBar.translucent = NO;
    }
    
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"RuanMao Cloud", nil) image:[UIImage imageNamed:@"RMCloudTabbarIcon"] tag:1];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [RMCloudNavigationController dealloc]");
#endif
}

@end
