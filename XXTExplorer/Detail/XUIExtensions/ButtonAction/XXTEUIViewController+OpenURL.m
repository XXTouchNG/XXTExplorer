//
//  XXTEUIViewController+OpenURL.m
//  XXTExplorer
//
//  Created by Zheng on 10/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+OpenURL.h"
#import <XUI/XUIButtonCell.h>
#import <XUI/XUILogger.h>

@implementation XXTEUIViewController (OpenURL)

- (NSNumber *)xui_OpenURL:(XUIButtonCell *)cell {
    NSDictionary *args = cell.xui_args;
    if (![args[@"url"] isKindOfClass:[NSString class]]) {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(OpenURL:) -> url", @"NSString")];
        return @(NO);
    }
    NSURL *url = [NSURL URLWithString:args[@"url"]];
    BOOL canOpenURL = uOpenURL(url);
    if (!canOpenURL)
    {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot open url \"%@\".", nil), url]);
    }
    return @(canOpenURL);
}

@end
