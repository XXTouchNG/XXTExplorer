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

static inline XXTEAppDelegate *sharedDelegate() {
    return ((XXTEAppDelegate *)[[UIApplication sharedApplication] delegate]);
}

static inline id uAppDefine(NSString *key) {
    return sharedDelegate().appDefines[key];
}

static inline id XXTEDefaultsObject(NSString *key, id defaultValue) {
    id value = [sharedDelegate().userDefaults objectForKey:key];
    if (!value && defaultValue) {
        [sharedDelegate().userDefaults setObject:defaultValue forKey:key];
        value = defaultValue;
    }
    return (value);
}

static inline BOOL XXTEDefaultsBool(NSString *key, BOOL defaultValue) {
    return ([XXTEDefaultsObject(key, @(defaultValue)) boolValue]);
}

static inline NSUInteger XXTEDefaultsEnum(NSString *key, NSUInteger defaultValue) {
    return ([XXTEDefaultsObject(key, @(defaultValue)) unsignedIntegerValue]);
}

static inline double XXTEDefaultsDouble(NSString *key, double defaultValue) {
    return ([XXTEDefaultsObject(key, @(defaultValue)) doubleValue]);
}

static inline id XXTEBuiltInDefaultsObject(NSString *key) {
    return (sharedDelegate().builtInDefaults[key]);
}

static inline BOOL XXTEBuiltInDefaultsObjectBool(NSString *key) {
    return ([XXTEBuiltInDefaultsObject(key) boolValue]);
}

static inline NSUInteger XXTEBuiltInDefaultsObjectEnum(NSString *key) {
    return ([XXTEBuiltInDefaultsObject(key) unsignedIntegerValue]);
}

#define XXTEDefaultsSetBasic(key, value) ([sharedDelegate().userDefaults setObject:@(value) forKey:(key)])
#define XXTEDefaultsSetObject(key, obj) ([sharedDelegate().userDefaults setObject:(obj) forKey:(key)])

static NSString * const kXXTErrorDomain = @"com.darwindev.XXTExplorer.error";

#endif /* XXTEAppDefines_h */
