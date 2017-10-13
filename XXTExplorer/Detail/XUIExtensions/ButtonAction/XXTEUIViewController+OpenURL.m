//
//  XXTEUIViewController+OpenURL.m
//  XXTExplorer
//
//  Created by Zheng on 10/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+OpenURL.h"
#import "XUIButtonCell.h"

@implementation XXTEUIViewController (OpenURL)

- (NSNumber *)xui_OpenURL:(XUIButtonCell *)cell {
    NSDictionary *args = cell.xui_args;
    if (![args[@"url"] isKindOfClass:[NSString class]]) {
        return @(NO);
    }
    NSURL *url = [NSURL URLWithString:args[@"url"]];
    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:url];
    if (canOpenURL) {
        [[UIApplication sharedApplication] openURL:url];
    }
    return @(canOpenURL);
}

@end
