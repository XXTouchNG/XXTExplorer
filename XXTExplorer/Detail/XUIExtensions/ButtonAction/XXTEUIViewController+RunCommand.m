//
//  XXTEUIViewController+RunCommand.m
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/4.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "XXTEUIViewController+RunCommand.h"
#import "XUIButtonCell.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import <XUI/XUILogger.h>

#import "XXTLuaNSValue.h"

@implementation XXTEUIViewController (RunCommand)

+ (PMKPromise *)promiseRunCommand:(NSString *)command {
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        int status = xxt_system(command.UTF8String);
        if (WIFEXITED(status)) {
            status = WEXITSTATUS(status);
        }
        resolve(@(status));
    }];
}

- (NSNumber *)xui_RunCommand:(XUIButtonCell *)cell {
    NSDictionary *args = cell.xui_args;
    if ([args[@"command"] isKindOfClass:[NSString class]]) {
        NSString *command = args[@"command"];
        UIViewController *blockVC = blockInteractions(self, YES);
        [[self class] promiseRunCommand:command]
        .then(^(NSNumber *retCode) {
            if ([retCode intValue] == 0) {
                toastMessage(self, NSLocalizedString(@"Operation succeed.", nil));
            } else {
                toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Command exit with code: %@", nil), retCode]);
            }
        })
        .catch(^(NSError *error) {
            toastError(self, error);
        })
        .finally(^() {
            blockInteractions(blockVC, NO);
        });
        return @(YES);
    }
    return @(NO);
}

@end
