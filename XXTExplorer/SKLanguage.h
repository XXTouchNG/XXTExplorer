//
//  SKLanguage.h
//  XXTExplorer
//
//  Created by Zheng on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKPattern;

@interface SKLanguage : NSObject

@property (nonatomic, strong, readonly) NSString *UUID;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *scopeName;
@property (nonatomic, strong, readonly) NSArray <SKPattern *> *patterns;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
