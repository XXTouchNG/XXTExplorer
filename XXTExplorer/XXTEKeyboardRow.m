//
//  XXTEKeyboardRow.m
//  XXTExplorer
//
//  Created by Zheng on 06/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEKeyboardRow.h"

@implementation XXTEKeyboardRow

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero inputViewStyle:UIInputViewStyleKeyboard]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame inputViewStyle:(UIInputViewStyle)inputViewStyle {
    if (self = [super initWithFrame:frame inputViewStyle:inputViewStyle]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    XXTEKeyboardRowDevice device = XXTEKeyboardRowDevicePhone;
    switch ([UIDevice currentDevice].userInterfaceIdiom) {
        case UIUserInterfaceIdiomPhone:
            device = XXTEKeyboardRowDevicePhone;
            break;
        case UIUserInterfaceIdiomPad:
            device = XXTEKeyboardRowDeviceTablet;
            break;
        default:
            break;
    }
    _device = device;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat barWidth = MIN(screenSize.width, screenSize.height);
    CGFloat barHeight = 44.f;
    if (device == XXTEKeyboardRowDeviceTablet)
    {
        barHeight = 72.f;
    }
    
    self.frame = CGRectMake(0, 0, barWidth, barHeight);
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    
}

@end
