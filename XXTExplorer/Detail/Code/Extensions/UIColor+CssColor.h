//
//  UIColor+CssColor.h
//  XXTExplorer
//
//  Created by Darwin on 8/1/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (CssColor)
+ (UIColor *)colorWithCssName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
