//
//  XXTEUIViewController+OpenURL.m
//  XXTExplorer
//
//  Created by Zheng on 10/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+OpenURL.h"
#import "XUIButtonCell.h"

#import <XUI/XUI.h>
#import <XUI/XUILogger.h>


@implementation XXTEUIViewController (Reload)

- (NSNumber *)xui_Reload:(XUIButtonCell *)cell {
    [[NSNotificationCenter defaultCenter] postNotificationName:XUINotificationEventUIUpdated object:cell userInfo:nil];
    return @(YES);
}

@end
