//
//  XXTPixelFlagView.h
//  XXTouchApp
//
//  Created by Zheng on 20/10/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTPositionColorModel.h"

@interface XXTPixelFlagView : UIView
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, strong) XXTPositionColorModel *dataModel;

@end
