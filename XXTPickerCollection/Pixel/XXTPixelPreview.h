//
//  XXTPixelPreview.h
//  XXTouchApp
//
//  Created by Zheng on 13/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTPixelPreview : UIWindow
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, strong) UIImage *imageToMagnify;
@property (nonatomic, assign) CGPoint pointToMagnify;
@property (nonatomic, strong, readonly) UIColor *colorOfLastPoint;

- (UIColor *)getColorOfPoint:(CGPoint)p;

@end
