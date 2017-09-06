//
//  XXTEKeyboardRow.m
//  XXTouchApp
//
//  Created by Zheng on 9/19/16.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTEKeyboardRow.h"

@interface XXTEKeyboardRow ()

@end

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
    XXTEKeyboardButtonStyle style = XXTEKeyboardButtonStylePhone;
    switch ([UIDevice currentDevice].userInterfaceIdiom) {
        case UIUserInterfaceIdiomPhone:
            style = XXTEKeyboardButtonStylePhone;
            break;
        case UIUserInterfaceIdiomPad:
            style = XXTEKeyboardButtonStyleTablet;
            break;
        default:
            break;
    }
    _style = style;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat barWidth = MIN(screenSize.width, screenSize.height);
    CGFloat barHeight = 44.f;
    if (style == XXTEKeyboardButtonStyleTablet) {
        barHeight = 72.f;
    }

    self.frame = CGRectMake(0, 0, barWidth, barHeight);
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

@end
