//
//  SKResult.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKResult : NSObject

@property (nonatomic, strong, readonly) NSString *scope;
@property (nonatomic, assign, readonly) NSRange range;

- (instancetype)initWithScope:(NSString *)scope range:(NSRange)range;

@end
