//
//  UIControl+BlockTarget.m
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UIControl+BlockTarget.h"
#import <objc/runtime.h>

static void *UIControlEventsHandlerKey = @"UIControlEventsHandlerKey";

@implementation UIControl (BlockTarget)

- (void)addActionforControlEvents:(UIControlEvents)controlEvents respond:(UIControlCompletionHandler)completion {
    [self addTarget:self action:@selector(controlElementTriggered:) forControlEvents:controlEvents];
    
    void (^block)(void) = ^{
        completion(self);
    };
    objc_setAssociatedObject(self, UIControlEventsHandlerKey, block, OBJC_ASSOCIATION_COPY);
}

-(void)controlElementTriggered:(id)sender {
    void (^block)(void) = objc_getAssociatedObject(self, UIControlEventsHandlerKey);
    block();
}

@end
