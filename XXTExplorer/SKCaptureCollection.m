//
//  SKCaptureCollection.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "SKCaptureCollection.h"
#import "SKCapture.h"

@interface SKCaptureCollection ()

@property (nonatomic, strong, readonly) NSDictionary <NSNumber *, SKCapture *> *captures;

@end

@implementation SKCaptureCollection

- (NSArray <NSNumber *> *)captureIndexes {
    NSMutableArray <NSNumber *> *keys = [[NSMutableArray alloc] initWithArray:self.captures.allKeys];
    [keys sortUsingComparator:^NSComparisonResult(NSNumber *  _Nonnull obj1, NSNumber *  _Nonnull obj2) {
        return [obj1 compare:obj2]; // ?
    }];
    return [[NSArray alloc] initWithArray:keys];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary1 {
    if (self = [super init]) {
        NSDictionary <NSString *, NSDictionary <NSString *, NSString *> *> *dictionary = dictionary1;
        if (![dictionary isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        NSMutableDictionary <NSNumber *, SKCapture *> *captures = [@[] mutableCopy];
        for (NSString *keyString in dictionary.allKeys) {
            NSDictionary *value = dictionary[keyString];
            if (![value isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            NSNumber *key = [numberFormatter numberFromString:keyString];
            SKCapture *capture = [[SKCapture alloc] initWithDictionary:value];
            if (!key || !capture) {
                continue;
            }
            captures[key] = capture;
        }
        _captures = captures;
    }
    return self;
}

- (SKCapture *)subscriptWithIndex:(NSNumber *)index {
    return self.captures[index];
}

@end
