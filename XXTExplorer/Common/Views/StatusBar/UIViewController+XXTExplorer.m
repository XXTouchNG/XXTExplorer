//
//  UIViewController+XXTExplorer.m
//  XXTExplorer
//
//  Created by Zheng on 01/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UIViewController+XXTExplorer.h"
#import "UIColor+XUIDarkColor.h"

#import "XXTEViewer.h"
#import "XXTEEditor.h"

@implementation UIViewController (XXTExplorer)

- (BOOL)shouldAutorotate {
    BOOL notViewer = [self conformsToProtocol:@protocol(XXTEViewer)] == NO && [self conformsToProtocol:@protocol(XXTEEditor)] == NO;
    return (notViewer);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
