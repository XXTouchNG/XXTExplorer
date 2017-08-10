//
//  SKCapture.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "SKCapture.h"

@implementation SKCapture

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        NSString *name = dictionary[@"name"];
        if (![name isKindOfClass:[NSString class]]) {
            return nil;
        }
        _name = name;
    }
    return self;
}

@end
