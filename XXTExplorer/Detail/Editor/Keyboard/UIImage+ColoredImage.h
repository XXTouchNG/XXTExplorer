//
//  UIImage+ColoredImage.h
//  XXTExplorer
//
//  Created by Zheng on 12/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ColoredImage)

+ (UIImage *)imageWithUIColor:(UIColor *)color;
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 130000
- (UIImage *)imageWithTintColor:(UIColor *)tintColor;
#endif

@end
