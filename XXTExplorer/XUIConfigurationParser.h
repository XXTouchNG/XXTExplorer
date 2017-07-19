//
//  XUIConfigurationParser.h
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XUIConfigurationParser : NSObject

+ (NSArray <NSDictionary *> *)entriesFromRootEntry:(NSDictionary *)rootEntry;

@end
