//
//  RMHotWord.h
//  XXTExplorer
//
//  Created by Zheng on 20/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMModel.h"
#import "RMHandler.h"

static RMApiAction const RMApiActionHotTrends = @"HotTrends";

@interface RMHotWord : RMModel
@property (nonatomic, copy) NSString *word;

+ (PMKPromise *)hotTrendsWithAmount:(NSUInteger)amount;

@end
