//
//  XXTENetworkDefines.h
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTENetworkDefines_h
#define XXTENetworkDefines_h

#import "XXTEAppDefines.h"
#import "NSString+XQueryComponents.h"
#import "NSString+SHA1.h"
#import "XXTECloudApiSdk.h"
#import "XXTEUserInterfaceDefines.h"

static id (^convertJsonString)(id) =
^id (id obj) {
    if ([obj isKindOfClass:[NSString class]]) {
        NSString *jsonString = obj;
        NSError *serverError = nil;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&serverError];
        if (serverError) {
            @throw [serverError localizedDescription];
        }
        return jsonDictionary;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDictionary = obj;
        return jsonDictionary;
    }
    return @{};
};

static id (^sendCloudApiRequest)(NSArray *objs) =
^(NSArray *objs) {
    NSString *commandUrl = objs[0];
    NSDictionary *sendDictionary = objs[1];
    NSMutableDictionary *sendMutableDictionary = [[NSMutableDictionary alloc] initWithDictionary:sendDictionary];
    NSString *signatureString = [[sendDictionary stringFromQueryComponents] sha1String];
    sendMutableDictionary[@"sign"] = signatureString;
    NSURL *sendUrl = [NSURL URLWithString:commandUrl];
    NSURLRequest *request = [XXTECloudApiSdk buildRequest:[NSString stringWithFormat:@"%@://", [sendUrl scheme]]
                                                   method:@"POST"
                                                     host:[sendUrl host]
                                                     path:[sendUrl path]
                                               pathParams:nil
                                              queryParams:nil
                                               formParams:[sendMutableDictionary copy]
                                                     body:nil
                                       requestContentType:@"application/x-www-form-urlencoded"
                                        acceptContentType:@"application/json"
                                             headerParams:nil];
    NSHTTPURLResponse *licenseResponse = nil;
    NSError *licenseError = nil;
    NSData *licenseReceived = [NSURLConnection sendSynchronousRequest:request returningResponse:&licenseResponse error:&licenseError];
    if (licenseError) {
        @throw [licenseError localizedDescription];
    }
    NSDictionary *returningHeadersDict = [licenseResponse allHeaderFields];
    if (licenseResponse.statusCode != 200 &&
        returningHeadersDict[@"X-Ca-Error-Message"])
    {
        @throw returningHeadersDict[@"X-Ca-Error-Message"];
    }
    NSDictionary *licenseDictionary = [NSJSONSerialization JSONObjectWithData:licenseReceived options:0 error:&licenseError];
    if (licenseError) {
        @throw [licenseError localizedDescription];
    }
    return licenseDictionary;
};

static inline NSString *uAppDaemonCommandUrl(NSString *command) {
    return ([uAppDefine(@"LOCAL_API") stringByAppendingString:command]);
}

static inline NSString *uAppLicenseServerCommandUrl(NSString *command) {
    return ([uAppDefine(@"AUTH_API") stringByAppendingString:command]);
}

#endif /* XXTENetworkDefines_h */
