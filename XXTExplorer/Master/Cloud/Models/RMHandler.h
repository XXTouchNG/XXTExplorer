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
#import "XXTEAppDefines.h"

static NSString * const RMApiBaseUrlKey = @"RMCLOUD_API";
static NSString * const RMApiBaseDebugUrlKey = @"RMCLOUD_DEBUG_API";
static NSString * const RMApiBaseTokenKey = @"RMCLOUD_TOKEN";
static NSString * const RMApiBasePlatformIDKey = @"RMCLOUD_PLATFORM";

typedef NSString * RMApiAction;
typedef NSDictionary * RMArguments;

static inline NSString *RMApiUrl(RMApiAction action, RMArguments args) {
    if (action.length == 0) return nil;
    NSString *argString = [args stringFromQueryComponents];
#ifdef DEBUG
    return [NSString stringWithFormat:@"%@/%@/?authtoken=%@&pid=%@&%@", uAppDefine(RMApiBaseDebugUrlKey), action, uAppDefine(RMApiBaseTokenKey), uAppDefine(RMApiBasePlatformIDKey), argString];
#else
    return [NSString stringWithFormat:@"%@/%@/?authtoken=%@&pid=%@&%@", uAppDefine(RMApiBaseUrlKey), action, uAppDefine(RMApiBaseTokenKey), uAppDefine(RMApiBasePlatformIDKey), argString];
#endif
}

#endif /* RMHandler_h */
