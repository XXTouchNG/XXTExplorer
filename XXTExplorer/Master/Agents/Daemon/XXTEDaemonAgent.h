//
//  XXTEDaemonAgent.h
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XXTEDaemonAgent;

@protocol XXTEDaemonAgentDelegate <NSObject>

- (void)daemonAgentDidSyncReady:(XXTEDaemonAgent *)agent;
- (void)daemonAgent:(XXTEDaemonAgent *)agent didFailWithError:(NSError *)error;

@end

@interface XXTEDaemonAgent : NSObject

@property (nonatomic, weak) id <XXTEDaemonAgentDelegate> delegate;
- (void)sync;

@end
