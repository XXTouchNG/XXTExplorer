//
//  SKCapture.m
//  XXTExplorer
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKCapture.h"

@implementation SKCapture

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self)
    {
        NSString *name = dictionary[@"name"];
        if (![name isKindOfClass:[NSString class]]) {
            return nil;
        }
        _name = name;
    }
    return self;
}

@end
