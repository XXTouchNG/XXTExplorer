//
//  XXTEUtils.mm
//  XXTExplorer
//
//  Created by Zheng on 30/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "XXTExplorerDefaults.h"

#import "UIView+XXTEToast.h"
#import "NSString+XQueryComponents.h"
#import "NSString+SHA1.h"
#import "XXTECloudApiSdk.h"

#import <pwd.h>
#import <spawn.h>
#import <sys/stat.h>
#import <time.h>

#import "XXTEAppDelegate.h"

#pragma mark - Defaults

const char **XXTESharedEnvp() {
    static const char *sharedEnvp[] = { "PATH=/bootstrap/usr/local/bin:/bootstrap/usr/sbin:/bootstrap/usr/bin:/bootstrap/sbin:/bootstrap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games:/usr/bin/1ferver", "HOME=/var/mobile", "USER=mobile", "LOGNAME=mobile", NULL };
    return sharedEnvp;
}

id uAppDefine(NSString *key) {
    return XXTEAppDelegate.appDefines[key];
}

id XXTEDefaultsObject(NSString *key, id defaultValue) {
    id value = [XXTEAppDelegate.userDefaults objectForKey:key];
    if (!value && defaultValue) {
        [XXTEAppDelegate.userDefaults setObject:defaultValue forKey:key];
        value = defaultValue;
    }
    return (value);
}

BOOL XXTEDefaultsBool(NSString *key, BOOL defaultValue) {
    id storedValue = XXTEDefaultsObject(key, @(defaultValue));
    if (![storedValue isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return ([storedValue boolValue]);
}

NSUInteger XXTEDefaultsEnum(NSString *key, NSUInteger defaultValue) {
    id storedValue = XXTEDefaultsObject(key, @(defaultValue));
    if (![storedValue isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return ([storedValue unsignedIntegerValue]);
}

double XXTEDefaultsDouble(NSString *key, double defaultValue) {
    id storedValue = XXTEDefaultsObject(key, @(defaultValue));
    if (![storedValue isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return ([storedValue doubleValue]);
}

NSInteger XXTEDefaultsInt(NSString *key, int defaultValue) {
    id storedValue = XXTEDefaultsObject(key, @(defaultValue));
    if (![storedValue isKindOfClass:[NSNumber class]]) {
        return defaultValue;
    }
    return ([storedValue integerValue]);
}

id XXTEBuiltInDefaultsObject(NSString *key) {
    return (XXTEAppDelegate.builtInDefaults[key]);
}

BOOL XXTEBuiltInDefaultsObjectBool(NSString *key) {
    return ([XXTEBuiltInDefaultsObject(key) boolValue]);
}

NSUInteger XXTEBuiltInDefaultsObjectEnum(NSString *key) {
    return ([XXTEBuiltInDefaultsObject(key) unsignedIntegerValue]);
}

void XXTEDefaultsSetObject(NSString *key, id obj) {
    [XXTEAppDelegate.userDefaults setObject:obj forKey:key];
}

NSString *XXTERootPath() {
    return [XXTEAppDelegate sharedRootPath];
}

#pragma mark - Permissions

const char *add1s_binary() {
    static NSString *add1s_binary = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        add1s_binary = uAppDefine(@"ADD1S_PATH");
    });
    return [add1s_binary fileSystemRepresentation];
}

const char *installer_binary() {
    static NSString *installer_binary = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        installer_binary = uAppDefine(@"INSTALLER_PATH");
    });
    return [installer_binary fileSystemRepresentation];
}

int promiseFixPermission(NSString *path, BOOL resursive) {
#ifdef APPSTORE
    return 0; // app store version, skipped
#else
    static NSString *realRootPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char *root_path = [[XXTEAppDelegate sharedRootPath] fileSystemRepresentation];
        char *resolved_root_path = realpath(root_path, NULL);
        if (resolved_root_path) {
            realRootPath = [[NSString alloc] initWithUTF8String:resolved_root_path];
            free(resolved_root_path);
        }
    });
    const char *original_path = [path fileSystemRepresentation];
    char *resolved_path = realpath(original_path, NULL);
    if (resolved_path)
    {
        NSString *resolvedPath = [[NSString alloc] initWithUTF8String:resolved_path];
        free(resolved_path);
        if (NO == [resolvedPath hasPrefix:realRootPath])
        {
            return -1; // not in root path, skipped
        }
    }
    struct stat entryStat;
    if (lstat(original_path, &entryStat) != 0) return -2;
    struct passwd pwent;
    struct passwd *pwentp;
    char buf[BUFSIZ];
    getpwuid_r(entryStat.st_uid, &pwent, buf, sizeof buf, &pwentp);
    if (pwentp != NULL) {
        if (pwent.pw_name) {
            NSString *pwName = [[NSString alloc] initWithUTF8String:pwent.pw_name];
            if ([pwName isEqualToString:@"mobile"]) {
                return 0; // already mobile owner, skipped
            }
        }
    }
    const char *binary = add1s_binary();
    BOOL fixEnabled = XXTEDefaultsBool(XXTExplorerFixFileOwnerAutomaticallyKey, YES);
    if (fixEnabled) {
        int status = 0;
        if (resursive)
        {
            pid_t pid = 0;
            const char* args[] = {binary, "chown", "-R", "mobile:mobile", original_path, NULL};
            posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)XXTESharedEnvp());
            waitpid(pid, &status, 0);
        }
        else
        {
            pid_t pid = 0;
            const char* args[] = {binary, "chown", "mobile:mobile", original_path, NULL};
            posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)XXTESharedEnvp());
            waitpid(pid, &status, 0);
        }
        if (WIFEXITED(status)) {
            status = WEXITSTATUS(status);
        }
        return status;
    }
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

NSDateFormatter *RFC822DateFormatter() {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:XXTE_STANDARD_LOCALE];
    });
    return formatter;
}

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
    {
        NSString *dateString = returningHeadersDict[@"Date"];
        NSDate *newDate = [RFC822DateFormatter() dateFromString:dateString];
        NSTimeInterval interval1 = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval interval2 = [newDate timeIntervalSince1970];
        NSTimeInterval interval = interval1 - interval2;
        if (interval < 0) interval = 0.0 - interval;
        if (interval > 300) {
            @throw NSLocalizedString(@"Local time is not accurate.", nil);
        }
    }
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

UIViewController *blockInteractionsWithToast(UIViewController *viewController, BOOL shouldBlock, BOOL shouldToast) {
    if (!viewController) return nil;
    NSMutableArray <UIViewController *> *viewControllerToBlock = [NSMutableArray array];
    NSMutableArray <UIView *> *viewToBlock = [NSMutableArray array];
    if (viewController.tabBarController.view) {
        [viewControllerToBlock addObject:viewController.tabBarController];
        [viewToBlock addObject:viewController.tabBarController.view];
    }
    if (viewController.navigationController.view) {
        [viewControllerToBlock addObject:viewController.navigationController];
        [viewToBlock addObject:viewController.navigationController.view];
    }
    if (viewController.view) {
        [viewControllerToBlock addObject:viewController];
        [viewToBlock addObject:viewController.view];
    }
    if (shouldBlock) {
        UIView *view = viewToBlock[0];
        view.userInteractionEnabled = NO;
        if (shouldToast)
        {
            [view makeToastActivity:XXTEToastPositionCenter];
        }
    } else {
        for (UIView *view in viewToBlock) {
            [view hideToastActivity];
            view.userInteractionEnabled = YES;
        }
    }
    return [viewControllerToBlock firstObject];
}

UIViewController *blockInteractions(UIViewController *viewController, BOOL shouldBlock) {
    return blockInteractionsWithToast(viewController, shouldBlock, YES);
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

void toastError(UIViewController *viewController, NSError *error) {
    toastMessageWithDelay(viewController, [error localizedDescription], 2.0);
}

NSString *XXTSchemeCloudProjectID(NSUInteger projectID) {
    return [NSString stringWithFormat:@"xxt://cloud/?project=%lu", (unsigned long)projectID];
}

UIColor *XXTColorDefault() { // rgb(52, 152, 219), #3498DB
    static UIColor *xxtColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xxtColor = [UIColor colorWithRed:52.f/255.f green:152.f/255.f blue:219.f/255.f alpha:1.f];
    });
    return xxtColor;
}

UIColor *XXTColorCellSelected() { // rgba(52, 152, 219, 0.1)
    static UIColor *xxtColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xxtColor = [UIColor colorWithRed:52.f/255.f green:152.f/255.f blue:219.f/255.f alpha:0.1];
    });
    return xxtColor;
}

UIColor *XXTColorDanger() { // rgb(231, 76, 60)
    static UIColor *xxtDangerColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xxtDangerColor = [UIColor colorWithRed:231.f/255.f green:76.f/255.f blue:60.f/255.f alpha:1.f];
    });
    return xxtDangerColor;
}

UIColor *XXTColorSuccess() { // rgb(26, 188, 134)
    static UIColor *xxtSuccessColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        xxtSuccessColor = [UIColor colorWithRed:26.f/255.f green:188.f/255.f blue:134.f/255.f alpha:1.f];
    });
    return xxtSuccessColor;
}

BOOL isOS11Above() {
    if (@available(iOS 11.0, *)) {
        return YES;
    }
    return NO;
}

BOOL isOS10Above() {
    if (@available(iOS 10.0, *)) {
        return YES;
    }
    return NO;
}

BOOL isOS9Above() {
    if (@available(iOS 9.0, *)) {
        return YES;
    }
    return NO;
}

BOOL isOS8Above() {
    if (@available(iOS 8.0, *)) {
        return YES;
    }
    return NO;
}

BOOL isAppStore() {
#ifdef APPSTORE
    return YES;
#else
    return NO;
#endif
}

NSString *uAppUserAgent() {
    return [NSString stringWithFormat:@"XXTExplorer/%@", [uAppDefine(kXXTDaemonVersionKey) stringByReplacingOccurrencesOfString:@"-" withString:@"."]];
}
