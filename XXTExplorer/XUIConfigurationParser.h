//
//  XUIConfigurationParser.h
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kXUIConfigurationParserErrorDomain;

@interface XUIConfigurationParser : NSObject

@property (nonatomic, strong, readonly) NSDictionary <NSString *, id> *rootEntry;
@property (nonatomic, strong, readonly) NSError *error;
- (instancetype)initWithRootEntry:(NSDictionary <NSString *, id> *)rootEntry;

@end
