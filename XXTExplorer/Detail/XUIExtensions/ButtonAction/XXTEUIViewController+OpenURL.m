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

#ifndef APPSTORE
BOOL SBSOpenSensitiveURLAndUnlock(NSURL *url, BOOL flags);
#endif

#if (TARGET_OS_SIMULATOR)
BOOL SBSOpenSensitiveURLAndUnlock(NSURL *url, BOOL flags) {
    return YES;
}
#endif

@implementation XXTEUIViewController (OpenURL)

- (NSNumber *)xui_OpenURL:(XUIButtonCell *)cell {
    NSDictionary *args = cell.xui_args;
    if (![args[@"url"] isKindOfClass:[NSString class]]) {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(OpenURL:) -> url", @"NSString")];
        return @(NO);
    }
    NSURL *url = [NSURL URLWithString:args[@"url"]];
#ifndef APPSTORE
    BOOL canOpenURL = SBSOpenSensitiveURLAndUnlock(url, YES);
#else
    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:url];
    if (canOpenURL) {
        [[UIApplication sharedApplication] openURL:url];
    }
#endif
    if (!canOpenURL)
    {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot open url \"%@\".", nil), url]);
    }
    return @(canOpenURL);
}

@end
