//
//  XXTEUserInterfaceDefines.h
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEUserInterfaceDefines_h
#define XXTEUserInterfaceDefines_h

#ifdef __OBJC__
#import <UIKit/UIKit.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    UIViewController *blockInteractionsWithToast(UIViewController *viewController, BOOL shouldBlock, BOOL shouldToast);
    UIViewController *blockInteractions(UIViewController *viewController, BOOL shouldBlock);
    BOOL isiPhoneX(void);
    BOOL isOS11Above(void);
    BOOL isOS10Above(void);
    BOOL isOS9Above(void);
    BOOL isOS8Above(void);
    BOOL isAppStore(void);
    
    void toastMessageWithDelay(UIViewController *viewController, NSString *message, NSTimeInterval duration);
    void toastMessage(UIViewController *viewController, NSString *message);
    void toastError(UIViewController *viewController, NSError *error);
    
    UIColor *XXTColorDefault(void);
    UIColor *XXTColorDanger(void);
    UIColor *XXTColorSuccess(void);
    UIColor *XXTColorCellSelected(void);
    
#ifdef __cplusplus
}
#endif

#define toastDaemonError(v, e) \
    if (e.code == -1004) toastMessage(v, NSLocalizedString(@"Could not connect to the daemon.", nil)); \
    else toastError(v, e);

#define XXTE_COLLAPSED \
XXTE_START_IGNORE_PARTIAL \
(XXTE_SYSTEM_8 && self.splitViewController && self.splitViewController.collapsed != YES) \
XXTE_END_IGNORE_PARTIAL

#define XXTE_IS_FULLSCREEN(c) ((c.navigationController && c.navigationController.modalPresentationStyle == UIModalPresentationFullScreen) || (c.modalPresentationStyle == UIModalPresentationFullScreen))
#define XXTE_IS_IPAD (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone)
#define XXTE_IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#define XXTE_SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define XXTE_SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define XXTE_SCREEN_MAX_LENGTH (MAX(XXTE_SCREEN_WIDTH, XXTE_SCREEN_HEIGHT))
#define XXTE_SCREEN_MIN_LENGTH (MIN(XXTE_SCREEN_WIDTH, XXTE_SCREEN_HEIGHT))

#define XXTE_IS_IPHONE_6_BELOW (XXTE_IS_IPHONE && XXTE_SCREEN_MAX_LENGTH < 667.0)
#define XXTE_IS_IPHONE_6P_ABOVE (XXTE_IS_IPHONE && XXTE_SCREEN_MAX_LENGTH >= 736.0)

#endif /* __OBJC__ */

#endif /* XXTEUserInterfaceDefines_h */
