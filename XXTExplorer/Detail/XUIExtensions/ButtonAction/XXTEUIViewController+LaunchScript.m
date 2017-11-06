//
//  XXTEUIViewController+LaunchScript.m
//  XXTExplorer
//
//  Created by Zheng on 02/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+LaunchScript.h"
#import "XUIButtonCell.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENetworkDefines.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import <XUI/XUILogger.h>

@implementation XXTEUIViewController (LaunchScript)

- (NSNumber *)xui_LaunchScript:(XUIButtonCell *)cell {
    NSDictionary *args = cell.xui_args;
    if (![args[@"path"] isKindOfClass:[NSString class]]) {
        [self.logger logMessage:XUIParserErrorInvalidType(@"@selector(LaunchScript:) -> path", @"NSString")];
        return @(NO);
    }
    NSString *scriptName = args[@"path"];
    NSString *scriptPath = [self.bundle pathForResource:scriptName ofType:nil];
    if (!scriptPath) {
        return @(NO);
    }
    blockInteractions(self, YES);
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
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockInteractions(self, NO);
    });
    return @(scriptPath != nil);
}

@end
