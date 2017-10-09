//
//  XXTEMasterViewController+Notifications.h
//  XXTExplorer
//
//  Created by Zheng on 06/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMasterViewController.h"
#import "XXTEScanViewController.h"

@interface XXTEMasterViewController (Notifications) <XXTEScanViewControllerDelegate>

- (void)registerNotifications;
- (void)removeNotifications;

@end
