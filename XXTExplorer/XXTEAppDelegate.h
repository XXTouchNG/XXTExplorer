//
//  XXTEAppDelegate.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEDaemonService.h"

@interface XXTEAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) XXTEDaemonService *daemonService;
@property (strong, nonatomic, readonly) NSDictionary *appDefines;

@end

