//
//  UIViewController+DetailCloseItem.m
//  XXTExplorer
//
//  Created by Zheng on 10/02/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "UIViewController+DetailCloseItem.h"
#import "XXTESplitViewController.h"

@implementation UIViewController (DetailCloseItem)

- (NSArray <UIBarButtonItem *> *)splitButtonItems {
    if (@available(iOS 8_0, *)) {
        return @[self.splitViewController.displayModeButtonItem, self.splitDetailCloseItem];
    } else {
        // Fallback on earlier versions
        return @[];
    }
}

- (UIBarButtonItem *)splitDetailCloseItem {
    if ([self.splitViewController isKindOfClass:[XXTESplitViewController class]])
    {
        XXTESplitViewController *splitController = (XXTESplitViewController *)self.splitViewController;
        return splitController.detailCloseItem;
    }
    return nil;
}

@end
