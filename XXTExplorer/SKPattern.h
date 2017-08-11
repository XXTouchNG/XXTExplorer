//
//  SKPattern.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/11.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKCaptureCollection;

@interface SKPattern : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *match;
@property (nonatomic, strong, readonly) SKCaptureCollection *captures;
@property (nonatomic, strong, readonly) NSString *patternBegin;
@property (nonatomic, strong, readonly) SKCaptureCollection *beginCaptures;
@property (nonatomic, strong, readonly) NSString *patternEnd;
@property (nonatomic, strong, readonly) SKCaptureCollection *endCaptures;

@property (nonatomic, strong, readonly) SKPattern *superPattern;
@property (nonatomic, strong, readonly) NSArray <SKPattern *> *subPatterns;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                            parent:(SKPattern *)superPattern;

@end
