//
//  XXTEKeyboardToolbarRow.m
//  XXTExplorer
//
//  Created by Zheng on 06/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEKeyboardToolbarRow.h"

@interface XXTEKeyboardToolbarRow ()

@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation XXTEKeyboardToolbarRow

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
    XXTEKeyboardToolbarRowDevice device = XXTEKeyboardToolbarRowDevicePhone;
    switch ([UIDevice currentDevice].userInterfaceIdiom) {
        case UIUserInterfaceIdiomPhone:
            device = XXTEKeyboardToolbarRowDevicePhone;
            break;
        case UIUserInterfaceIdiomPad:
            device = XXTEKeyboardToolbarRowDeviceTablet;
            break;
        default:
            break;
    }
    _device = device;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat barWidth = MIN(screenSize.width, screenSize.height);
    CGFloat barHeight = 44.f;
    if (device == XXTEKeyboardToolbarRowDeviceTablet)
    {
        barHeight = 72.f;
    }
    
    self.frame = CGRectMake(0, 0, barWidth, barHeight);
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self configureSubviews];
}

- (void)configureSubviews {
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.toolbar setItems:@[flexibleItem]];
    [self addSubview:self.toolbar];
}

#pragma mark - UIView Getters

- (UIToolbar *)toolbar {
    if (!_toolbar) {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        [toolbar setBackgroundImage:[UIImage new]
                 forToolbarPosition:UIToolbarPositionAny
                         barMetrics:UIBarMetricsDefault];
        [toolbar setBackgroundColor:[UIColor clearColor]];
        _toolbar = toolbar;
    }
    return _toolbar;
}

#pragma mark - Actions

- (void)dismissItemTapped:(UIBarButtonItem *)sender {
    
}

@end
