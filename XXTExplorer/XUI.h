//
//  XUI.h
//  XXTExplorer
//
//  Created by Zheng on 2017/7/21.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#ifndef XUI_h
#define XUI_h

#import <Foundation/Foundation.h>

#define XUI_START_IGNORE_PARTIAL _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wpartial-availability\"")
#define XUI_END_IGNORE_PARTIAL _Pragma("clang diagnostic pop")

#define XUI_SYSTEM_9 (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_0)
#define XUI_SYSTEM_8 (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_0)
#define XUI_PAD ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone)

static NSString * const XUINotificationEventValueChanged = @"XUINotificationEventValueChanged";

#endif /* XUI_h */
