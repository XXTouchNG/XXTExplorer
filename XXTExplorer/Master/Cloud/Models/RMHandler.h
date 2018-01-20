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

static NSString * const RMApiBaseScheme = @"RMCLOUD_SCHEME";
static NSString * const RMApiBaseHostKey = @"RMCLOUD_HOST";
static NSString * const RMApiBaseDebugHostKey = @"RMCLOUD_DEBUG_HOST";
static NSString * const RMApiBaseOpenPath = @"RMCLOUD_OPENAPI";
static NSString * const RMApiBaseTokenKey = @"RMCLOUD_TOKEN";
static NSString * const RMApiBasePlatformIDKey = @"RMCLOUD_PLATFORM";

static NSString * const RMApiBuyPath = @"RMCLOUD_API_BUY";

static NSInteger const RMApiErrorCode = 46952;
static NSInteger const RMApiFatalErrorCode = 46953;

typedef NSString * RMApiAction;
typedef NSDictionary * RMArguments;

static inline NSString *RMApiUrl(RMApiAction action, RMArguments args) {
    if (action.length == 0) return nil;
    NSString *argString = [args stringFromQueryComponents];
#ifdef DEBUG
    return [NSString stringWithFormat:@"%@://%@%@/%@/?authtoken=%@&pid=%@&%@", uAppDefine(RMApiBaseScheme), uAppDefine(RMApiBaseDebugHostKey), uAppDefine(RMApiBaseOpenPath), action, uAppDefine(RMApiBaseTokenKey), uAppDefine(RMApiBasePlatformIDKey), argString];
#else
    return [NSString stringWithFormat:@"%@://%@%@/%@/?authtoken=%@&pid=%@&%@", uAppDefine(RMApiBaseScheme), uAppDefine(RMApiBaseHostKey), uAppDefine(RMApiBaseOpenPath), action, uAppDefine(RMApiBaseTokenKey), uAppDefine(RMApiBasePlatformIDKey), argString];
#endif
}

static inline NSString *RMBuyUrl(RMArguments args) {
    NSString *argString = [args stringFromQueryComponents];
#ifdef DEBUG
    return [NSString stringWithFormat:@"%@://%@%@/?authtoken=%@&pid=%@&%@", uAppDefine(RMApiBaseScheme), uAppDefine(RMApiBaseDebugHostKey), uAppDefine(RMApiBuyPath), uAppDefine(RMApiBaseTokenKey), uAppDefine(RMApiBasePlatformIDKey), argString];
#else
    return [NSString stringWithFormat:@"%@://%@%@/?authtoken=%@&pid=%@&%@", uAppDefine(RMApiBaseScheme), uAppDefine(RMApiBaseHostKey), uAppDefine(RMApiBuyPath), uAppDefine(RMApiBaseTokenKey), uAppDefine(RMApiBasePlatformIDKey), argString];
#endif
}

#endif /* RMHandler_h */
