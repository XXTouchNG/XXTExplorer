//
//  XXTEUIViewController+OpenURLInCydia.m
//  XXTExplorer
//
//  Created by Zheng on 2018/5/12.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEUIViewController+OpenURLInCydia.h"
#import <XUI/XUIButtonCell.h>
#import <XUI/XUILogger.h>

@implementation XXTEUIViewController (OpenURLInCydia)

- (NSNumber *)xui_OpenURLInCydia:(XUIButtonCell *)cell {
    NSDictionary *args = cell.xui_args;
    if (![args[@"path"] isKindOfClass:[NSString class]])
    {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(OpenURLInCydia:) -> url", @"NSString")];
        return @(NO);
    }
    NSString *payloadName = args[@"path"];
    NSString *payloadPath = [self.bundle pathForResource:payloadName ofType:nil];
    if (!payloadPath) {
        return @(NO);
    }
    NSString *cydiaURLString = uAppDefine(@"CYDIA_URL");
    if (!cydiaURLString) {
        return @(NO);
    }
    NSString *urlString = [NSString stringWithFormat:cydiaURLString, payloadPath];
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:url];
    if (canOpenURL) {
        [[UIApplication sharedApplication] openURL:url];
    }
    if (!canOpenURL)
    {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot open url \"%@\".", nil), url]);
    }
    return @(canOpenURL);
}

@end
