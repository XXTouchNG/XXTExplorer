//
//  XXTExplorerNavigationController.h
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTENavigationController.h"

@class XXTExplorerViewController;

@interface XXTExplorerNavigationController : XXTENavigationController

#pragma mark - Convenience Getters

@property (nonatomic, strong, readonly) XXTExplorerViewController *topmostExplorerViewController;

@end
