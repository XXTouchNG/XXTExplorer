//
//  XXTEUtils.mm
//  XXTExplorer
//
//  Created by Zheng on 30/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEPermissionDefines.h"
#import "XXTEUserInterfaceDefines.h"

#import "UIView+XXTEToast.h"
#import "NSString+XQueryComponents.h"
#import "NSString+SHA1.h"
#import "XXTECloudApiSdk.h"

#import <spawn.h>
#import <sys/stat.h>

#pragma mark - Permissions

const char *add1s_binary() {
    static const char* binary = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        binary = [uAppDefine(@"ADD1S_PATH") UTF8String];
    });
    return binary;
}

int promiseFixPermission(NSString *path, BOOL resursive) {
#ifdef APPSTORE
    return 0;
#endif
#ifndef DEBUG
    const char *binary = add1s_binary();
    BOOL fixEnabled = XXTEDefaultsBool(XXTExplorerFixFileOwnerAutomaticallyKey, YES);
    if (fixEnabled) {
        int status = 0;
        if (resursive) {
            pid_t pid = 0;
            const char* args[] = {binary, "chown", "-R", "mobile:mobile", [path fileSystemRepresentation], NULL};
            posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)sharedEnvp);
            waitpid(pid, &status, 0);
        } else {
            pid_t pid = 0;
            const char* args[] = {binary, "chown", "mobile:mobile", [path fileSystemRepresentation], NULL};
            posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)sharedEnvp);
            waitpid(pid, &status, 0);
        }
        return status;
    }
    return 0;
#else
    return 0;
#endif
}

#pragma mark - Networking

#ifndef APPSTORE
id (^convertJsonString)(id) =
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
#endif

#ifndef APPSTORE
id (^sendCloudApiRequest)(NSArray *objs) =
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
        @throw [NSString stringWithFormat:NSLocalizedString(@"Aliyun gateway error: %@", nil), returningHeadersDict[@"X-Ca-Error-Message"]];
    }
    NSDictionary *licenseDictionary = [NSJSONSerialization JSONObjectWithData:licenseReceived options:0 error:&licenseError];
    if (licenseError) {
        @throw [licenseError localizedDescription];
    }
    return licenseDictionary;
};
#endif

#ifndef APPSTORE
NSString *uAppDaemonCommandUrl(NSString *command) {
    return ([uAppDefine(@"LOCAL_API") stringByAppendingString:command]);
}
#endif

#ifndef APPSTORE
NSString *uAppLicenseServerCommandUrl(NSString *command) {
    return ([uAppDefine(@"AUTH_API") stringByAppendingString:command]);
}
#endif

NSDictionary *uAppConstEnvp(void) {
    NSString *languageCode = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    if (!languageCode) languageCode = @"en";
    NSString *versionString = uAppDefine(kXXTDaemonVersionKey);
    if (!versionString) versionString = @"";
    return @{ @"XXTOUCH_LAUNCH_VIA": @"APPLICATION", @"XXTOUCH_LANGUAGE": languageCode, @"XXTOUCH_VERSION": versionString };
}

#pragma mark - Interface

UIViewController *blockInteractionsWithDelay(UIViewController *viewController, BOOL shouldBlock, NSTimeInterval delay) {
    if (!viewController) return nil;
    UIViewController *parentController = viewController.tabBarController;
    if (!parentController) {
        parentController = viewController.navigationController;
    }
    if (!parentController) {
        parentController = viewController;
    }
    UIView *viewToBlock = parentController.view;
    [NSObject cancelPreviousPerformRequestsWithTarget:viewToBlock selector:@selector(makeToastActivity:) object:XXTEToastPositionCenter];
    [NSObject cancelPreviousPerformRequestsWithTarget:viewToBlock selector:@selector(hideToastActivity) object:XXTEToastPositionCenter];
    if (shouldBlock) {
        viewToBlock.userInteractionEnabled = NO;
        if (delay > 0) {
            [viewToBlock performSelector:@selector(makeToastActivity:) withObject:XXTEToastPositionCenter afterDelay:delay];
        } else {
            [viewToBlock makeToastActivity:XXTEToastPositionCenter];
        }
    } else {
        if (delay > 0) {
            [viewToBlock performSelector:@selector(hideToastActivity) withObject:nil afterDelay:delay];
        } else {
            [viewToBlock hideToastActivity];
        }
        viewToBlock.userInteractionEnabled = YES;
    }
    return parentController;
}

UIViewController *blockInteractions(UIViewController *viewController, BOOL shouldBlock) {
    return blockInteractionsWithDelay(viewController, shouldBlock, 0.0);
}

BOOL isiPhoneX() {
    static BOOL checkiPhoneX = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 8.0, *)) {
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone && UIScreen.mainScreen.nativeBounds.size.height == 2436)  {
                checkiPhoneX = YES;
            }
        } else {
            // Fallback on earlier versions
        }
    });
    return checkiPhoneX;
}

void toastMessageWithDelay(UIViewController *viewController, NSString *message, NSTimeInterval duration) {
    if (viewController.navigationController) {
        [viewController.navigationController.view makeToast:message duration:duration position:XXTEToastPositionCenter];
    } else if (viewController.tabBarController) {
        [viewController.tabBarController.view makeToast:message duration:duration position:XXTEToastPositionCenter];
    } else {
        [viewController.view makeToast:message duration:duration position:XXTEToastPositionCenter];
    }
}

void toastMessage(UIViewController *viewController, NSString *message) {
    toastMessageWithDelay(viewController, message, 2.0);
}

NSString *XXTSchemeCloudProjectID(NSUInteger projectID) {
    return [NSString stringWithFormat:@"xxt://cloud/?project=%lu", (unsigned long)projectID];
}
