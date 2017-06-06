//
//  XXTESplitViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESplitViewController.h"
#import <LGAlertView/LGAlertView.h>

@interface XXTESplitViewController ()

@end

@implementation XXTESplitViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.viewControllers[0].preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.viewControllers[0].prefersStatusBarHidden;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.viewControllers[0];
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.viewControllers[0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    LGAlertView *alertAppearance = [LGAlertView appearanceWhenContainedIn:[self class], nil];
    alertAppearance.coverColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    alertAppearance.coverBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    alertAppearance.coverAlpha = 0.75;
    alertAppearance.layerShadowColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    alertAppearance.layerShadowRadius = 4.0;
    alertAppearance.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    alertAppearance.buttonsHeight = 44.0;
    alertAppearance.titleFont = [UIFont boldSystemFontOfSize:18.0];
    alertAppearance.titleTextColor = [UIColor blackColor];
    alertAppearance.messageTextColor = [UIColor blackColor];
    alertAppearance.activityIndicatorViewColor = XXTE_COLOR;
    alertAppearance.buttonsTitleColor = XXTE_COLOR;
    alertAppearance.buttonsBackgroundColorHighlighted = XXTE_COLOR;
    alertAppearance.cancelButtonTitleColor = XXTE_COLOR;
    alertAppearance.cancelButtonBackgroundColorHighlighted = XXTE_COLOR;
    alertAppearance.destructiveButtonTitleColor = XXTE_DANGER_COLOR;
    alertAppearance.destructiveButtonBackgroundColorHighlighted = XXTE_DANGER_COLOR;
    alertAppearance.progressLabelFont = [UIFont italicSystemFontOfSize:14.f];
    alertAppearance.progressLabelLineBreakMode = NSLineBreakByTruncatingHead;
    alertAppearance.dismissOnAction = NO;
    alertAppearance.buttonsIconPosition = LGAlertViewButtonIconPositionLeft;
    alertAppearance.buttonsTextAlignment = NSTextAlignmentLeft;
}

@end
