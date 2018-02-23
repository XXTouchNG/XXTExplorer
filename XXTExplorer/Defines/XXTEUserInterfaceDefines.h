//
//  XXTEUserInterfaceDefines.h
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEUserInterfaceDefines_h
#define XXTEUserInterfaceDefines_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    UIViewController *blockInteractionsWithDelay(UIViewController *viewController, BOOL shouldBlock, NSTimeInterval delay);
    UIViewController *blockInteractions(UIViewController *viewController, BOOL shouldBlock);
    BOOL isiPhoneX(void);
    void toastMessageWithDelay(UIViewController *viewController, NSString *message, NSTimeInterval duration);
    void toastMessage(UIViewController *viewController, NSString *message);
    void toastError(UIViewController *viewController, NSError *error);
    
#ifdef __cplusplus
}
#endif

#define toastDaemonError(v, e) \
    if (e.code == -1004) toastMessage(v, NSLocalizedString(@"Could not connect to the daemon.", nil)); \
    else toastError(v, e);

#endif /* XXTEUserInterfaceDefines_h */
