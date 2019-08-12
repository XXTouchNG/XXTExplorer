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


@implementation XXTEDaemonAgent

- (void)sync {
    [NSURLConnection POST:uAppDaemonCommandUrl(@"is_running") JSON:@{}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if (jsonDirectory[@"code"]) {
            if (self->_delegate && [self->_delegate respondsToSelector:@selector(daemonAgentDidSyncReady:)]) {
                [self->_delegate daemonAgentDidSyncReady:self];
            }
        }
    })
    .catch(^(NSError *error) {
        if (error) {
            if (self->_delegate && [self->_delegate respondsToSelector:@selector(daemonAgent:didFailWithError:)]) {
                [self->_delegate daemonAgent:self didFailWithError:error];
            }
        }
    });
}

@end
