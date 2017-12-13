//
// Created by Zheng Wu on 09/10/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LASettingsViewController.h"

#if !(TARGET_OS_SIMULATOR)
@interface LASettingsViewController (MyShowsAd)
- (BOOL)showsAd;
- (BOOL)myShowsAd;
@end
#endif
