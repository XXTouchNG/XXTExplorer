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

- (NSNumber *)OpenURL:(XUIButtonCell *)cell {
    NSArray *kwargs = cell.xui_kwargs;
    if (!kwargs || kwargs.count != 1 || ![kwargs[0] isKindOfClass:[NSString class]]) {
        return @(NO);
    }
    NSURL *url = [NSURL URLWithString:kwargs[0]];
    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:url];
    if (canOpenURL) {
        [[UIApplication sharedApplication] openURL:url];
    }
    return @(canOpenURL);
}

@end
