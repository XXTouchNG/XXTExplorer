//
// Created by Zheng on 18/08/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKHelperConfig : NSObject

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSString *themeIdentifier;
@property (nonatomic, strong) NSString *languageIdentifier;

@end