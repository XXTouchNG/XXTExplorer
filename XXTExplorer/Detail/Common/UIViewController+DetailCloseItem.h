//
//  UIViewController+DetailCloseItem.h
//  XXTExplorer
//
//  Created by Zheng on 10/02/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (DetailCloseItem)

- (NSArray <UIBarButtonItem *> *)splitButtonItems;
- (UIBarButtonItem *)splitDetailCloseItem;

@end
