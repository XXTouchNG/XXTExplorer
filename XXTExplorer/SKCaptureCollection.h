//
//  SKCaptureCollection.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKCapture;

@interface SKCaptureCollection : NSObject

@property (nonatomic, strong, readonly) NSArray <NSNumber *> *captureIndexes;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (SKCapture *)subscriptWithIndex:(NSNumber *)index;

@end
