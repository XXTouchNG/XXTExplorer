//
//  SKTheme.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NSDictionary * SKAttributes;

@interface SKTheme : NSObject

@property (nonatomic, strong, readonly) NSString *UUID;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSDictionary <NSString *, SKAttributes> *attributes;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
