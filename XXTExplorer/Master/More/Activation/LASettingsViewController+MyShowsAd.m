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
- (BOOL)myShowsAd {
    return NO;
}
@end

@interface ActivatorAdView : UIView
@end
@implementation ActivatorAdView
- (CGFloat)alpha {
    return 0.f;
}
- (BOOL)isHidden {
    return YES;
}
@end
#endif
