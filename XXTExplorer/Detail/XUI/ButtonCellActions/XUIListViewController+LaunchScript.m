//
//  XUIListViewController+LaunchScript.m
//  XXTExplorer
//
//  Created by Zheng on 02/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIListViewController+LaunchScript.h"
#import "XUIButtonCell.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENetworkDefines.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

@implementation XUIListViewController (LaunchScript)

- (NSNumber *)xui_LaunchScript:(XUIButtonCell *)cell {
    NSArray *kwargs = cell.xui_kwargs;
    if (!kwargs || kwargs.count != 1 || ![kwargs[0] isKindOfClass:[NSString class]]) {
        return @(NO);
    }
    NSString *scriptName = kwargs[0];
    NSString *scriptPath = [self.bundle pathForResource:scriptName ofType:nil];
    blockUserInteractions(self, YES, 0);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"launch_script_file") JSON:@{@"filename": scriptPath, @"envp": uAppConstEnvp()}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
        }
        return [PMKPromise promiseWithValue:@{}];
    })
    .catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            showUserMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockUserInteractions(self, NO, 0);
    });
    return @(scriptPath != nil);
}

@end
