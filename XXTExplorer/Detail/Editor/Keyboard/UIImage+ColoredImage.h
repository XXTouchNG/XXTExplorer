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
- (UIImage *)imageWithTintColor:(UIColor *)tintColor;

@end
