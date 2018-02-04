 //
//  XXTEMasterViewController+Guide.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/4.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "XXTEMasterViewController+Guide.h"
#import "XXTEMasterViewController.h"
#import <EAFeatureGuideView/UIView+EAFeatureGuideView.h>

#import "XXTEAppDefines.h"

static NSString * const kXXTEGuideMasterCloudKey = @"kXXTEGuideMasterCloudKey";

@implementation XXTEMasterViewController (Guide)

- (void)showGuide {
#ifndef APPSTORE
    if (!XXTE_PAD) {
        UIFont *introduceFont = [UIFont systemFontOfSize:14.0];
        CGRect itemRect = CGRectNull;
        NSMutableArray <EAFeatureItem *> *featureItems = [[NSMutableArray alloc] init];
        
#ifdef RMCLOUD_ENABLED
        itemRect = [self rectOfTabBarItemAtIndex:kMasterViewControllerIndexCloud];
        if (!CGRectIsNull(itemRect)) {
            CGFloat minWidth = MIN(CGRectGetWidth(itemRect), CGRectGetHeight(itemRect));
            CGRect highlightRect = CGRectMake(CGRectGetMinX(itemRect) + (CGRectGetWidth(itemRect) - minWidth) / 2.0, CGRectGetMinY(itemRect) + (CGRectGetHeight(itemRect) - minWidth) / 2.0, minWidth, minWidth);
            EAFeatureItem *item = [[EAFeatureItem alloc] initWithFocusRect:highlightRect focusCornerRadius:minWidth focusInsets:UIEdgeInsetsZero];
            item.introduce = NSLocalizedString(@"Here is our new script market.", nil);
            item.introduceFont = introduceFont;
            item.actionTitle = NSLocalizedString(@"Try it!", nil);
            @weakify(self);
            item.action = ^(id sender) {
                @strongify(self);
                [self setSelectedIndex:kMasterViewControllerIndexCloud];
            };
            [featureItems addObject:item];
        }
#endif
        
        [self.view showWithFeatureItems:[featureItems copy] saveKeyName:kXXTEGuideMasterCloudKey];
    }
#endif
}

@end
