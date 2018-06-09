//
//  XXTENetworkDefines.h
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTENetworkDefines_h
#define XXTENetworkDefines_h

#ifdef __OBJC__

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#ifndef APPSTORE
    extern id (^convertJsonString)(id);
#endif
    
#ifndef APPSTORE
    extern id (^sendCloudApiRequest)(NSArray *objs);
#endif
    
#ifndef APPSTORE
    NSString *uAppDaemonCommandUrl(NSString *command);
    NSString *uAppWebAccessUrl(NSString *path);
#endif
    
#ifndef APPSTORE
    NSString *uAppLicenseServerCommandUrl(NSString *command);
#endif
    
    NSDictionary *uAppConstEnvp(void);
    NSString *uAppUserAgent(void);
    BOOL uOpenURL(NSURL *url);
    
    NSString *XXTSchemeCloudProjectID(NSUInteger projectID);
    
#ifdef __cplusplus
}
#endif

static NSString * const XXTSchemeLicense = @"xxt://license/?code=%@";
static NSString * const XXTETrustedHostsKey = @"TRUSTED_HOSTS";

#endif /* __OBJC__ */

#endif /* XXTENetworkDefines_h */
