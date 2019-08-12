//
//  UIColor+systemColors.h
//  XXTExplorer
//
//  Created by Darwin on 8/12/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 130000

@interface UIColor (systemColors)

+ (UIColor *)systemBackgroundColor;
+ (UIColor *)labelColor;
+ (UIColor *)secondarySystemBackgroundColor;
+ (UIColor *)secondaryLabelColor;
+ (UIColor *)tertiaryLabelColor;
+ (UIColor *)separatorColor;
+ (UIColor *)systemGroupedBackgroundColor;

@end

#endif
NS_ASSUME_NONNULL_END
