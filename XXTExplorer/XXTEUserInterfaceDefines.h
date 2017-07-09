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

#endif /* XXTEUserInterfaceDefines_h */
