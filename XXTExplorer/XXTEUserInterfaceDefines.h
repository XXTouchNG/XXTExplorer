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

static inline void blockUserInteractions(UIViewController *viewController, BOOL shouldBlock) {
    UIViewController *parentController = viewController.tabBarController;
    if (!parentController) {
        parentController = viewController.navigationController;
    }
    if (!parentController) {
        parentController = viewController;
    }
    UIView *viewToBlock = parentController.view;
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

#endif /* XXTEUserInterfaceDefines_h */
