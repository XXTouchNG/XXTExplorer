//
//  XXTExplorerNavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerNavigationController.h"

@interface XXTExplorerNavigationController ()

@end

@implementation XXTExplorerNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"My Scripts", nil) image:[UIImage imageNamed:@"XXTExplorerTabbarIcon"] tag:0];
}

@end
