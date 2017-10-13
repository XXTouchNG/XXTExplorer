//
//  XXTEUIViewController+XXTCheckUpdate.m
//  XXTExplorer
//
//  Created by Zheng Wu on 13/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+XXTCheckUpdate.h"
#import <XUI/XUIButtonCell.h>
#import "XXTEMasterViewController.h"

@implementation XXTEUIViewController (XXTCheckUpdate)

- (NSNumber *)xui_XXTCheckUpdate:(XUIButtonCell *)cell {
    XXTEMasterViewController *tabbarController = (XXTEMasterViewController *) self.tabBarController;
    if (tabbarController) {
        [tabbarController checkUpdate];
        return @(YES);
    } else {
        return @(NO);
    }
}

@end
