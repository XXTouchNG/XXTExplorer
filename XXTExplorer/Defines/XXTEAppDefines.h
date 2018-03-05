//
//  XXTEAppDefines.h
//  XXTExplorer
//
//  Created by Zheng on 05/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEAppDefines_h
#define XXTEAppDefines_h

#ifdef __OBJC__
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    const char **XXTESharedEnvp(void);
    
    id uAppDefine(NSString *key);
    
    id XXTEDefaultsObject(NSString *key, id defaultValue);
    BOOL XXTEDefaultsBool(NSString *key, BOOL defaultValue);
    NSUInteger XXTEDefaultsEnum(NSString *key, NSUInteger defaultValue);
    double XXTEDefaultsDouble(NSString *key, double defaultValue);
    NSInteger XXTEDefaultsInt(NSString *key, int defaultValue);
    
    id XXTEBuiltInDefaultsObject(NSString *key);
    BOOL XXTEBuiltInDefaultsObjectBool(NSString *key);
    NSUInteger XXTEBuiltInDefaultsObjectEnum(NSString *key);
    
    void XXTEDefaultsSetObject(NSString *key, id obj);
    
    NSString *XXTERootPath(void);
    
#ifdef __cplusplus
}
#endif

#define XXTEDefaultsSetBasic(key, value) (XXTEDefaultsSetObject(key, @(value)))

static NSString * const kXXTErrorDomain = @"com.darwindev.XXTExplorer.error";
static NSString * const kXXTDaemonVersionKey = @"DAEMON_VERSION";
static NSString * const kXXTELaunchedTimes = @"XXTELaunchedTimes";

#endif /* __OBJC__ */

#endif /* XXTEAppDefines_h */
