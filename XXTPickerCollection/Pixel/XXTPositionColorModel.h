//
//  XXTPositionColorModel.h
//  XXTouchApp
//
//  Created by Zheng on 20/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTPositionColorModel : NSObject
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGPoint position;

+ (instancetype)modelWithPosition:(CGPoint)p andColor:(UIColor *)c;
@end
