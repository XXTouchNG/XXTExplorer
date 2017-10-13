//
// Created by Zheng Wu on 09/10/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "LASettingsViewController+MyShowsAd.h"

#if !(TARGET_OS_SIMULATOR)
@implementation LASettingsViewController (MyShowsAd)

- (BOOL)showsAd
{
    return NO;
}

- (BOOL)myShowsAd
{
    return NO;
}

@end
#endif
