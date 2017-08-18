//
//  SKResult.m
//  XXTExplorer
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKResult.h"

@implementation SKResult

- (instancetype)initWithIdentifier:(NSString *)identifier range:(NSRange)range attribute:(id)attribute {
    self = [super init];
    if (self)
    {
        _patternIdentifier = identifier;
        _range = range;
        _attribute = attribute;
    }
    return self;
}

- (BOOL)isEqual:(SKResult *)object {
    return [self.patternIdentifier isEqualToString:object.patternIdentifier] && NSEqualRanges(self.range, object.range);
}

@end
