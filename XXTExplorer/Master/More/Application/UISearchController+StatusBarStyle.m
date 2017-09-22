//
//  UISearchController+StatusBarStyle.m
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UISearchController+StatusBarStyle.h"

@implementation UISearchController (StatusBarStyle)

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.active) {
        return UIStatusBarStyleDefault;
    }
    return [super preferredStatusBarStyle];
}

@end
