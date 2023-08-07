//
//  UIViewController+TopMostViewController.h
//  XXTExplorer
//
//  Created by Zheng on 06/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (TopMostViewController)

- (UIViewController *)topMostViewController;
- (void)dismissModalStackAnimated:(BOOL)animated;

@end
