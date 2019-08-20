//
//  XXTExplorerNavigationController.h
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef APPSTORE
#import "XXTENavigationController.h"

@class XXTExplorerViewController;

@interface XXTExplorerNavigationController : XXTENavigationController
@property (nonatomic, strong, readonly) XXTExplorerViewController *topmostExplorerViewController;
@end

#else

#define XXTExplorerNavigationController XXTEMasterViewController
#import "XXTEMasterViewController.h"

#endif
