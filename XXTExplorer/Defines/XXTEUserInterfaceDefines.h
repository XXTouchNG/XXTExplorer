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
    
#ifdef __cplusplus
}
#endif

#endif /* XXTEUserInterfaceDefines_h */
