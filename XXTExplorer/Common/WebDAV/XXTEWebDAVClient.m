//
//  XXTEWebDAVClient.m
//  XXTouch
//
//  Created by Zheng Wu on 2018/2/12.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import "XXTEWebDAVClient.h"

#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebDAVServer.h>

NSString * const XXTEWebDAVNotificationServerDidStart = @"XXTEWebDAVNotificationServerDidStart";
NSString * const XXTEWebDAVNotificationServerDidStop = @"XXTEWebDAVNotificationServerDidStop";
NSString * const XXTEWebDAVNotificationServerDidCompleteBonjourRegistration = @"XXTEWebDAVNotificationServerDidCompleteBonjourRegistration";
NSString * const XXTEWebDAVNotificationServerDidUpdateNATPortMapping = @"XXTEWebDAVNotificationServerDidUpdateNATPortMapping";

@interface XXTEWebDAVClient () <GCDWebDAVServerDelegate>
@property (nonatomic, strong) GCDWebDAVServer *davServer;

@end

@implementation XXTEWebDAVClient

+ (instancetype)sharedInstance {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _homePath = NSHomeDirectory();
    }
    return self;
}

- (void)startWithPort:(NSUInteger)port error:(NSError **)error {
    if (NO == self.davServer.isRunning) {
        NSMutableDictionary* options = [NSMutableDictionary dictionary];
        [options setObject:[NSNumber numberWithInteger:port] forKey:GCDWebServerOption_Port];
        [options setValue:NSStringFromClass([self class]) forKey:GCDWebServerOption_BonjourName];
        [self.davServer startWithOptions:options error:error];
    }
}

- (void)stop {
    if (self.davServer.isRunning) {
        [self.davServer stop];
    }
}

- (BOOL)isRunning {
    return [self.davServer isRunning];
}

- (NSURL *)serverURL {
    return [self.davServer serverURL];
}

- (NSURL *)publicServerURL {
    return [self.davServer publicServerURL];
}

- (NSURL *)bonjourServerURL {
    return [self.davServer bonjourServerURL];
}

- (GCDWebDAVServer *)davServer {
    if (!_davServer) {
        _davServer  = [[GCDWebDAVServer alloc] initWithUploadDirectory:self.homePath];
        _davServer.delegate = self;
    }
    return _davServer;
}

#pragma mark - GCDWebDAVServerDelegate

- (void)webServerDidStart:(GCDWebServer *)server {
    [[NSNotificationCenter defaultCenter] postNotificationName:XXTEWebDAVNotificationServerDidStart object:self];
}

- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer *)server {
    [[NSNotificationCenter defaultCenter] postNotificationName:XXTEWebDAVNotificationServerDidCompleteBonjourRegistration object:self];
}

- (void)webServerDidUpdateNATPortMapping:(GCDWebServer *)server {
    [[NSNotificationCenter defaultCenter] postNotificationName:XXTEWebDAVNotificationServerDidUpdateNATPortMapping object:self];
}

- (void)webServerDidStop:(GCDWebServer *)server {
    [[NSNotificationCenter defaultCenter] postNotificationName:XXTEWebDAVNotificationServerDidStop object:self];
}

@end
