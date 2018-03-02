//
//  RMHotWord.m
//  XXTExplorer
//
//  Created by Zheng on 20/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMHotWord.h"

@implementation RMHotWord

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"word": @"Word",
                                                                  }];
}

+ (PMKPromise *)hotTrendsWithAmount:(NSUInteger)amount {
    NSDictionary *args =
    @{ @"num": [NSString stringWithFormat:@"%lu", (unsigned long)amount],
       };
    return [self promiseGETRequest:RMApiUrl(RMApiActionHotTrends, args)];
}

@end
