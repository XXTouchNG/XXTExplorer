//
//  SKCapture.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKCapture : NSObject

@property (nonatomic, strong, readonly) NSString *name;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
