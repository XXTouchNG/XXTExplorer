//
//  UIDocumentPickerViewController+NavigationBar.m
//  XXTExplorer
//
//  Created by Zheng on 07/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UIDocumentPickerViewController+NavigationBar.h"

@implementation UIDocumentPickerViewController (NavigationBar)

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

@end
