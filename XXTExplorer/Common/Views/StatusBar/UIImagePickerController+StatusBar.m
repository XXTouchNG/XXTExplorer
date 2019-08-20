//
//  UIImagePickerController+StatusBar.m
//  XXTExplorer
//
//  Created by Zheng on 18/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "UIImagePickerController+StatusBar.h"

@implementation UIImagePickerController (StatusBar)

- (UIStatusBarStyle)preferredStatusBarStyle {
#ifndef APPSTORE
    return UIStatusBarStyleLightContent;
#else
    return UIStatusBarStyleDefault;
#endif
}

@end
