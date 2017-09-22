//
//  XUITheme.m
//  XXTExplorer
//
//  Created by Zheng Wu on 14/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUITheme.h"
#import "UIColor+DarkColor.h"
#import "UIColor+SKColor.h"

#define XUI_COLOR ([UIColor colorWithRed:52.f/255.f green:152.f/255.f blue:219.f/255.f alpha:1.f]) // rgb(52, 152, 219)
#define XUI_COLOR_DANGER ([UIColor colorWithRed:231.f/255.f green:76.f/255.f blue:60.f/255.f alpha:1.f]) // rgb(231, 76, 60)
#define XUI_COLOR_SUCCESS ([UIColor colorWithRed:26.f/255.f green:188.f/255.f blue:134.f/255.f alpha:1.f]) // rgb(26, 188, 134)
#define XUI_COLOR_HIGHLIGHTED ([UIColor colorWithRed:0.22 green:0.29 blue:0.36 alpha:1.00])

@implementation XUITheme

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)themeDictionary {
    self = [super init];
    if (self) {
        [self setup];
        
        if (themeDictionary[@"tintColor"])
            _tintColor = [UIColor colorWithHex:themeDictionary[@"tintColor"]];
        if (themeDictionary[@"dangerColor"])
            _dangerColor = [UIColor colorWithHex:themeDictionary[@"dangerColor"]];
        if (themeDictionary[@"successColor"])
            _successColor = [UIColor colorWithHex:themeDictionary[@"successColor"]];
        if (themeDictionary[@"highlightColor"])
            _highlightColor = [UIColor colorWithHex:themeDictionary[@"highlightColor"]];
        if (themeDictionary[@"navigationBarColor"])
            _navigationBarColor = [UIColor colorWithHex:themeDictionary[@"navigationBarColor"]];
        if (themeDictionary[@"navigationTitleColor"])
            _navigationTitleColor = [UIColor colorWithHex:themeDictionary[@"navigationTitleColor"]];
        if (themeDictionary[@"labelColor"])
            _labelColor = [UIColor colorWithHex:themeDictionary[@"labelColor"]];
        if (themeDictionary[@"valueColor"])
            _valueColor = [UIColor colorWithHex:themeDictionary[@"valueColor"]];
    }
    return self;
}

- (void)setup {
    _tintColor = XUI_COLOR_HIGHLIGHTED;
    _dangerColor = XUI_COLOR_DANGER;
    _successColor = XUI_COLOR_SUCCESS;
    _highlightColor = XUI_COLOR_HIGHLIGHTED;
    
    _navigationBarColor = XUI_COLOR_HIGHLIGHTED;
    _navigationTitleColor = [UIColor whiteColor];
    
    _labelColor = [UIColor blackColor];
    _valueColor = [UIColor grayColor];
}

- (BOOL)isDarkMode {
    return [self.navigationBarColor isDarkColor];
}

@end
