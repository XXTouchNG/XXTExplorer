//
//  XXTESplitViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEDetailViewController.h"

@class XXTEMasterViewController, XXTExplorerViewController;

@interface XXTESplitViewController : UISplitViewController

- (void)restoreWorkspaceViewControllerFromViewController:(UIViewController *)sender;
@property (nonatomic, strong) UIBarButtonItem *detailCloseItem;

#pragma mark - Convinence Getters

@property (nonatomic, strong, readonly) XXTEMasterViewController *xxteMasterViewController;
@property (nonatomic, strong, readonly) UIViewController <XXTEDetailViewController> *xxteDetailViewController;
@property (nonatomic, strong, readonly) XXTExplorerViewController *masterExplorerViewController;

@property (nonatomic, strong, readonly) NSString *masterExplorerEntryPath;
@property (nonatomic, strong, readonly) NSString *detailEntryPath;

@end
