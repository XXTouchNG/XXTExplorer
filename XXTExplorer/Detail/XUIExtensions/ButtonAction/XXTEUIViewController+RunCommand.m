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
        resolve(@(xxt_system(command.UTF8String)));
    }];
}

- (NSNumber *)xui_RunCommand:(XUIButtonCell *)cell {
    NSDictionary *args = cell.xui_args;
    if ([args[@"command"] isKindOfClass:[NSString class]]) {
        NSString *command = args[@"command"];
        UIViewController *blockVC = blockInteractions(self, YES);
        [[self class] promiseRunCommand:command]
        .then(^(NSNumber *retCode) {
            toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Command exit with code: %@", nil), retCode]);
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
