//
//  XXTEAppDefines.h
//  XXTExplorer
//
//  Created by Zheng on 05/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEAppDefines_h
#define XXTEAppDefines_h

#import "XXTEAppDelegate.h"

static const char * sharedEnvp[] = { "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", "HOME=/var/mobile", "USER=mobile", "LOGNAME=mobile", NULL };

static inline id uAppDefine(NSString *key) {
    return XXTEAppDelegate.appDefines[key];
}

static inline id XXTEDefaultsObject(NSString *key, id defaultValue) {
    id value = [XXTEAppDelegate.userDefaults objectForKey:key];
    if (!value && defaultValue) {
        [XXTEAppDelegate.userDefaults setObject:defaultValue forKey:key];
        value = defaultValue;
    }
    return (value);
}

static inline BOOL XXTEDefaultsBool(NSString *key, BOOL defaultValue) {
    id storedValue = XXTEDefaultsObject(key, @(defaultValue));
    if (![storedValue isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return ([storedValue boolValue]);
}

static inline NSUInteger XXTEDefaultsEnum(NSString *key, NSUInteger defaultValue) {
    id storedValue = XXTEDefaultsObject(key, @(defaultValue));
    if (![storedValue isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return ([storedValue unsignedIntegerValue]);
}

static inline double XXTEDefaultsDouble(NSString *key, double defaultValue) {
    id storedValue = XXTEDefaultsObject(key, @(defaultValue));
    if (![storedValue isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return ([storedValue doubleValue]);
}

static inline double XXTEDefaultsInt(NSString *key, int defaultValue) {
    id storedValue = XXTEDefaultsObject(key, @(defaultValue));
    if (![storedValue isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return ([storedValue intValue]);
}

static inline id XXTEBuiltInDefaultsObject(NSString *key) {
    return (XXTEAppDelegate.builtInDefaults[key]);
}

static inline BOOL XXTEBuiltInDefaultsObjectBool(NSString *key) {
    return ([XXTEBuiltInDefaultsObject(key) boolValue]);
}

static inline NSUInteger XXTEBuiltInDefaultsObjectEnum(NSString *key) {
    return ([XXTEBuiltInDefaultsObject(key) unsignedIntegerValue]);
}

#define XXTEDefaultsSetBasic(key, value) ([XXTEAppDelegate.userDefaults setObject:@(value) forKey:(key)])
#define XXTEDefaultsSetObject(key, obj) ([XXTEAppDelegate.userDefaults setObject:(obj) forKey:(key)])

static NSString * const kXXTErrorDomain = @"com.darwindev.XXTExplorer.error";

#endif /* XXTEAppDefines_h */
