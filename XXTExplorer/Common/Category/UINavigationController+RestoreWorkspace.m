//
//  UINavigationController+RestoreWorkspace.m
//  XXTExplorer
//
//  Created by Zheng on 23/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UINavigationController+RestoreWorkspace.h"
#import "XXTESplitViewController.h"

@implementation UINavigationController (RestoreWorkspace)

- (void)restoreWorkspaceViewController {
    XXTESplitViewController *splitViewController = (XXTESplitViewController *)self.splitViewController;
    if ([splitViewController isKindOfClass:[XXTESplitViewController class]]) {
        [splitViewController restoreWorkspaceViewControllerFromViewController:self];
    }
}

@end
