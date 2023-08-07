//
//  UIColor+SystemColors.m
//  XXTExplorer
//
//  Created by Darwin on 8/12/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "UIColor+SystemColors.h"
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 130000
@implementation UIColor (SystemColors)

+ (UIColor *)systemBackgroundColor {
    return [UIColor whiteColor];
}

+ (UIColor *)labelColor {
    return [UIColor blackColor];
}

+ (UIColor *)secondarySystemBackgroundColor {
    return [UIColor colorWithWhite:0.950 alpha:0.750];
}

+ (UIColor *)secondaryLabelColor {
    return [UIColor darkGrayColor];
}

+ (UIColor *)tertiaryLabelColor {
    return [UIColor grayColor];
}

+ (UIColor *)separatorColor {
    return [UIColor colorWithWhite:0.850 alpha:1.0];
}

+ (UIColor *)systemGroupedBackgroundColor {
    return [UIColor groupTableViewBackgroundColor];
}

@end
#endif
