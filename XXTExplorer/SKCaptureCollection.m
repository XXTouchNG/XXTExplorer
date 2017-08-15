//
//  SKCaptureCollection.m
//  XXTExplorer
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "SKCaptureCollection.h"
#import "SKCapture.h"

@interface SKCaptureCollection ()

@property (nonatomic, strong, readonly) NSDictionary <NSNumber *, SKCapture *> *captures;

@end

@implementation SKCaptureCollection

- (NSArray <NSNumber *> *)getCaptureIndexes {
    NSMutableArray <NSNumber *> *keys = [[NSMutableArray alloc] initWithArray:self.captures.allKeys];
    [keys sortUsingComparator:^NSComparisonResult(NSNumber * _Nonnull obj1, NSNumber * _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return keys;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary1 {
    self = [super init];
    if (self)
    {
        NSDictionary <NSString *, NSDictionary <NSString *, NSString *> *> *dictionary = dictionary1;
        if (!dictionary)
            return nil;
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSMutableDictionary <NSNumber *, SKCapture *> *captures = [[NSMutableDictionary alloc] init];
        for (NSString *key in dictionary) {
            NSDictionary <NSString *, NSString *> *value = dictionary[key];
            NSNumber *keyNumber = [formatter numberFromString:key];
            SKCapture *capture = [[SKCapture alloc] initWithDictionary:value];
            if (keyNumber && capture) {
                captures[key] = capture;
            }
        }
        _captures = captures;
    }
    return self;
}

- (SKCapture *)objectForKeyedSubscript:(NSNumber *)index {
    return self.captures[index];
}

@end
