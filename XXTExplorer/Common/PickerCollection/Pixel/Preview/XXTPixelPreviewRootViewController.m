//
//  XXTPixelPreviewRootViewController.m
//  XXTouchApp
//
//  Created by Zheng on 14/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTPixelPreviewRootViewController.h"
#import "XXTPickerDefine.h"

@implementation XXTPixelPreviewRootViewController

- (BOOL)prefersStatusBarHidden {
    return self.statusBarHidden;
}

#pragma mark - View Style

- (BOOL)shouldAutorotate {
    return XXTP_SYSTEM_9;
}

@end
