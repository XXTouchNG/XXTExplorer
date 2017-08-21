//
//  XXTEUserInterfaceDefines.h
//  XXTExplorer
//
//  Created by Zheng on 09/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XXTEUserInterfaceDefines_h
#define XXTEUserInterfaceDefines_h

#import "UIView+XXTEToast.h"

static inline void blockUserInteractions(UIViewController *viewController, BOOL shouldBlock, NSTimeInterval delay) {
    UIViewController *parentController = viewController.tabBarController;
    if (!parentController) {
        parentController = viewController.navigationController;
    }
    if (!parentController) {
        parentController = viewController;
    }
    UIView *viewToBlock = parentController.view;
    if (delay > 0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:viewToBlock selector:@selector(makeToastActivity:) object:XXTEToastPositionCenter];
    }
    if (shouldBlock) {
        viewToBlock.userInteractionEnabled = NO;
        if (delay > 0) {
            [viewToBlock performSelector:@selector(makeToastActivity:) withObject:XXTEToastPositionCenter afterDelay:.2f];
        } else {
            [viewToBlock makeToastActivity:XXTEToastPositionCenter];
        }
    } else {
        [viewToBlock hideToastActivity];
        viewToBlock.userInteractionEnabled = YES;
    }
}

static inline void showUserMessage(UIViewController *viewController, NSString *message) {
    [viewController.navigationController.view makeToast:message];
}

#endif /* XXTEUserInterfaceDefines_h */
