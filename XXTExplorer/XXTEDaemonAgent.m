//
//  XXTEDaemonAgent.m
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEDaemonAgent.h"

#import <PromiseKit/Promise.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import "XXTEAppDefines.h"
#import "XXTENetworkDefines.h"

@implementation XXTEDaemonAgent

- (void)sync {
    [NSURLConnection POST:uAppDaemonCommandUrl(@"is_running") JSON:@{}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if (jsonDirectory[@"code"]) {
            if (_delegate && [_delegate respondsToSelector:@selector(daemonAgentDidSyncReady:)]) {
                [_delegate daemonAgentDidSyncReady:self];
            }
        }
    })
    .catch(^(NSError *error) {
        if (error) {
            if (_delegate && [_delegate respondsToSelector:@selector(daemonAgent:didFailWithError:)]) {
                [_delegate daemonAgent:self didFailWithError:error];
            }
        }
    });
}

@end
