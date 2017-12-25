//
//  XXTPositionColorModel.m
//  XXTouchApp
//
//  Created by Zheng on 20/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTPositionColorModel.h"

@implementation XXTPositionColorModel

+ (instancetype)modelWithPosition:(CGPoint)p andColor:(UIColor *)c {
    XXTPositionColorModel *newModel = [XXTPositionColorModel new];
    newModel.position = p;
    newModel.color = c;
    return newModel;
}

@end
