//
//  XXTEWebDAVClient.h
//  XXTouch
//
//  Created by Zheng Wu on 2018/2/12.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>

extern NSString * const XXTEWebDAVNotificationServerDidStart;
extern NSString * const XXTEWebDAVNotificationServerDidStop;
extern NSString * const XXTEWebDAVNotificationServerDidCompleteBonjourRegistration;
extern NSString * const XXTEWebDAVNotificationServerDidUpdateNATPortMapping;

@interface XXTEWebDAVClient : NSObject
@property (nonatomic, copy) NSString *homePath;

+ (instancetype)sharedInstance;

- (BOOL)isRunning;
- (void)startWithPort:(NSUInteger)port error:(NSError **)error;
- (void)stop;

- (NSURL *)serverURL;
- (NSURL *)publicServerURL;
- (NSURL *)bonjourServerURL;

@end
