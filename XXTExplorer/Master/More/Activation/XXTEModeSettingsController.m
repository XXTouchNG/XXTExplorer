//
// Created by Zheng Wu on 09/10/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XXTEModeSettingsController.h"


@implementation XXTEModeSettingsController {}

- (BOOL)showsAd {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
#if (TARGET_OS_SIMULATOR)
    self.view.backgroundColor = [UIColor whiteColor];
#endif
}

@end
