//
//  XUIListViewController+OpenURL.m
//  XXTExplorer
//
//  Created by Zheng on 10/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIListViewController+OpenURL.h"
#import "XUIButtonCell.h"

@implementation XUIListViewController (OpenURL)

- (void)OpenURL:(XUIButtonCell *)cell {
    NSArray *kwargs = cell.xui_kwargs;
    if (!kwargs || kwargs.count != 1 || ![kwargs[0] isKindOfClass:[NSString class]]) {
        return;
    }
    NSURL *url = [NSURL URLWithString:kwargs[0]];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
