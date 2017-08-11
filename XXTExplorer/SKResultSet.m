//
//  SKResultSet.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "SKResultSet.h"
#import "SKResult.h"

@implementation SKResultSet {
    NSMutableArray <SKResult *> *_results;
    BOOL hasSetRange;
}

- (instancetype)init {
    if (self = [super init]) {
        _results = [@[] mutableCopy];
        hasSetRange = NO;
    }
    return self;
}

- (NSArray <SKResult *> *)results {
    return _results;
}

- (BOOL)isEmpty {
    return _results.count == 0;
}

- (void)addResult:(SKResult *)result {
    [_results addObject:result];
    if (hasSetRange) {
        
    } else {
        hasSetRange = YES;
        self.range = result.range;
        return;
    }
    self.range = NSUnionRange(self.range, result.range);
}

- (void)addResults:(SKResultSet *)resultSet {
    for (SKResult *result in resultSet.results) {
        [self addResult:result];
    }
}

@end
