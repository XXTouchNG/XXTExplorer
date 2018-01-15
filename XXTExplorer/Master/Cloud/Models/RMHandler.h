//
//  RMHandler.h
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#ifndef RMHandler_h
#define RMHandler_h

#import <Foundation/Foundation.h>
#import "NSString+XQueryComponents.h"

static NSString * const RMApiBaseUrl = @"http://auth.mall-software.net/api/OpenAPI";
static NSString * const RMApiBaseToken = @"3487C956F68D360C";
static NSString * const RMApiBasePlatformID = @"2";

typedef NSString * RMApiAction;
typedef NSDictionary * RMArguments;

static inline NSString *RMApiUrl(RMApiAction action, RMArguments args) {
    if (action.length == 0) return nil;
    NSString *argString = [args stringFromQueryComponents];
    return [NSString stringWithFormat:@"%@/%@/?authtoken=%@&pid=%@&%@", RMApiBaseUrl, action, RMApiBaseToken, RMApiBasePlatformID, argString];
}

#endif /* RMHandler_h */
