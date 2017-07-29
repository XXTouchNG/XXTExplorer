//
//  NSBundle+FlushCaches.m
//  XXTExplorer
//
//  Created by Zheng on 30/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "NSBundle+FlushCaches.h"

// First, we declare the function. Making it weak-linked
// ensures the preference pane won't crash if the function
// is removed from in a future version of Mac OS X.
extern void _CFBundleFlushBundleCaches(CFBundleRef bundle)
__attribute__((weak_import));

@implementation NSBundle (FlushCaches)

- (BOOL)flushCaches {
    if (_CFBundleFlushBundleCaches != NULL) {
        CFBundleRef cfBundle =
        CFBundleCreate(nil, (CFURLRef)self.bundleURL);
        _CFBundleFlushBundleCaches(cfBundle);
        CFRelease(cfBundle);
        return YES; // Success
    }
    return NO; // Not available
}

@end
