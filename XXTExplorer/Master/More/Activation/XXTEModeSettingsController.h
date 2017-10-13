//
// Created by Zheng Wu on 09/10/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libactivator.h"

#if !(TARGET_OS_SIMULATOR)
@interface XXTEModeSettingsController : LAModeSettingsController
#else
@interface XXTEModeSettingsController : UIViewController
#endif

@end
