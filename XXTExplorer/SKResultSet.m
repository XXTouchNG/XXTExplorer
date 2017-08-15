//
//  SKResultSet.m
//  XXTExplorer
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKResultSet.h"
#import "SKResult.h"

@implementation SKResultSet {
    NSMutableArray <SKResult *> *_results;
    NSRange _range;
}

- (NSArray <SKResult *> *)getResults {
    return _results;
}

- (NSRange)getRange {
    return _range;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _results = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)initWithStartingRange:(NSRange)range {
    self = [super init];
    if (self) {
        _results = [[NSMutableArray alloc] init];
        _range = range;
    }
    return self;
}

- (void)extendWithRange:(NSRange)range {
    _range = NSUnionRange(self.range, range);
}

- (void)addResult:(SKResult *)result {
    [self extendWithRange:result.range];
    [_results addObject:result];
}

- (void)addResultSet:(SKResultSet *)resultSet {
    [self extendWithRange:resultSet.range];
    for (SKResult *result in resultSet.results) {
        [_results addObject:result];
    }
}

@end
