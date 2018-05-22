//
//  XXTEUIViewController+LaunchScript.m
//  XXTExplorer
//
//  Created by Zheng on 02/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+LaunchScript.h"
#import <XUI/XUIButtonCell.h>
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
    NSString *bundlePath = [self.bundle bundlePath];
    if (!bundlePath) {
        return @(NO);
    }
    NSMutableDictionary <NSString *, NSString *> *launchArgs = [[NSMutableDictionary alloc] initWithDictionary:uAppConstEnvp()];
    for (NSString *argKey in args)
    {
        if ([args[argKey] isKindOfClass:[NSString class]])
        {
            launchArgs[argKey] = args[argKey];
        }
    }
    launchArgs[@"XUI_PATH"] = scriptPath;
    launchArgs[@"XUI_BUNDLE_PATH"] = bundlePath;
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"launch_script_file") JSON:@{ @"filename": scriptPath, @"envp": [launchArgs copy] }]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
            
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
        }
        return [PMKPromise promiseWithValue:@{}];
    })
    .catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
    });
    return @(scriptPath != nil);
}

@end
