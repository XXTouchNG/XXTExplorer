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


static inline void blockInteractionsWithDelay(UIViewController *viewController, BOOL shouldBlock, NSTimeInterval delay) {
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
}
static inline void blockInteractions(UIViewController *viewController, BOOL shouldBlock) {
    blockInteractionsWithDelay(viewController, shouldBlock, 0.0);
}

static inline void toastMessageWithDelay(UIViewController *viewController, NSString *message, NSTimeInterval duration) {
    if (viewController.navigationController) {
        [viewController.navigationController.view makeToast:message duration:duration position:XXTEToastPositionCenter];
    } else if (viewController.tabBarController) {
        [viewController.tabBarController.view makeToast:message duration:duration position:XXTEToastPositionCenter];
    } else {
        [viewController.view makeToast:message duration:duration position:XXTEToastPositionCenter];
    }
}
static inline void toastMessage(UIViewController *viewController, NSString *message) {
    toastMessageWithDelay(viewController, message, 2.0);
}

#endif /* XXTEUserInterfaceDefines_h */
