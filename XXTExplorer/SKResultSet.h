//
//  SKResultSet.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKResult;

@interface SKResultSet : NSObject

@property (nonatomic, strong, readonly) NSArray <SKResult *> *results;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, assign, getter=isEmpty) BOOL empty;

- (void)addResult:(SKResult *)result;
- (void)addResults:(SKResultSet *)resultSet;

@end
