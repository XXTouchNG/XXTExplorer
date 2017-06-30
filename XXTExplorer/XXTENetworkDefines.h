//
//  XXTENetworkDefines.h
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTENetworkDefines_h
#define XXTENetworkDefines_h

#import "XXTEAppDelegate.h"
#import "UIView+XXTEToast.h"

static id (^convertJsonString)(id obj) =
^id (id obj) {
    if ([obj isKindOfClass:[NSString class]]) {
        NSString *jsonString = obj;
        NSError *serverError = nil;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&serverError];
        if (serverError) {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot connect to daemon: %@.", nil), [serverError localizedDescription]];
        }
        return jsonDictionary;
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDictionary = obj;
        return jsonDictionary;
    }
    return @{};
};

static inline NSString *uAppDaemonCommandUrl(NSString *command) {
    return ([((XXTEAppDelegate *)[[UIApplication sharedApplication] delegate]).appDefines[@"LOCAL_API"] stringByAppendingString:command]);
}

static inline void blockUserInteractions(UIView *viewToBlock, BOOL shouldBlock) {
    if (shouldBlock) {
        viewToBlock.userInteractionEnabled = NO;
        [viewToBlock makeToastActivity:XXTEToastPositionCenter];
    } else {
        [viewToBlock hideToastActivity];
        viewToBlock.userInteractionEnabled = YES;
    }
}

static inline void showUserMessage(UIView *viewToShow, NSString *message) {
    [viewToShow makeToast:message];
}

#endif /* XXTENetworkDefines_h */
