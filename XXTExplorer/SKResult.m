//
//  SKResult.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "SKResult.h"

@implementation SKResult

- (instancetype)initWithScope:(NSString *)scope range:(NSRange)range {
    if (self = [super init]) {
        _scope = scope;
        _range = range;
    }
    return self;
}

@end
