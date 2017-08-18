//
// Created by Zheng on 18/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "SKHelperConfig.h"


@implementation SKHelperConfig {

}

- (instancetype)init {
    self = [super init];
    if (self)
    {
        _bundle = [NSBundle mainBundle];
        _font = [UIFont systemFontOfSize:14.f];
        _color = UIColor.blackColor;
        _themeIdentifier = @"";
        _languageIdentifier = @"";
    }
    return self;
}

@end