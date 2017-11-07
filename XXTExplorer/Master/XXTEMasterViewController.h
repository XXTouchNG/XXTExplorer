//
//  XXTEMasterViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEAPTHelper, XXTEUpdateAgent;

@interface XXTEMasterViewController : UITabBarController

#ifndef APPSTORE
- (void)checkUpdate;
#endif

@end
