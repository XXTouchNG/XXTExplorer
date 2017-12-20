//
//  XXTEEditorSearchAccessoryView.m
//  XXTExplorer
//
//  Created by Zheng Wu on 14/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchAccessoryView.h"

@interface XXTEEditorSearchAccessoryView ()
@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation XXTEEditorSearchAccessoryView

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero inputViewStyle:UIInputViewStyleKeyboard]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame inputViewStyle:UIInputViewStyleKeyboard]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UILabel *countLabel = [[UILabel alloc] init];
    countLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:16.0];
    countLabel.textAlignment = NSTextAlignmentRight;
    countLabel.textColor = self.tintColor; // *
    countLabel.text = NSLocalizedString(@"0/0", nil);
    [countLabel sizeToFit];
    _countLabel = countLabel;
    
    UIBarButtonItem *counter = [[UIBarButtonItem alloc] initWithCustomView:countLabel];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 16.0;
    [self.toolbar setItems:@[self.prevItem, fixedSpace, self.nextItem, flexibleSpace, counter]];
    
    [self addSubview:self.toolbar];
}

- (void)searchPreviousMatch {
    if ([_accessoryDelegate respondsToSelector:@selector(searchAccessoryViewShouldMatchPrev:)]) {
        [_accessoryDelegate searchAccessoryViewShouldMatchPrev:self];
    }
}

- (void)searchNextMatch {
    if ([_accessoryDelegate respondsToSelector:@selector(searchAccessoryViewShouldMatchNext:)]) {
        [_accessoryDelegate searchAccessoryViewShouldMatchNext:self];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    UIToolbar *toolbar = self.toolbar;
    toolbar.tintColor = tintColor;
    for (UIBarButtonItem *item in toolbar.items) {
        item.tintColor = tintColor;
    }
    self.countLabel.textColor = tintColor;
}

#pragma mark - UIView Getters

- (UIToolbar *)toolbar {
    if (!_toolbar) {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [toolbar setBackgroundColor:[UIColor clearColor]];
        [toolbar setTranslucent:YES];
        _toolbar = toolbar;
    }
    return _toolbar;
}

- (void)setBarStyle:(UIBarStyle)barStyle {
    _barStyle = barStyle;
    UIToolbar *toolbar = self.toolbar;
    toolbar.barStyle = barStyle;
    if (barStyle == UIBarStyleDefault) {
        [toolbar setBackgroundImage:nil
                 forToolbarPosition:UIToolbarPositionAny
                         barMetrics:UIBarMetricsDefault];
    } else {
        [toolbar setBackgroundImage:[UIImage new]
                 forToolbarPosition:UIToolbarPositionAny
                         barMetrics:UIBarMetricsDefault];
    }
}

- (UIBarButtonItem *)prevItem {
    if (!_prevItem) {
        UIBarButtonItem *prevButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEEditorSearchBarPrevIcon"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(searchPreviousMatch)];
        prevButtonItem.tintColor = self.tintColor; // *
        prevButtonItem.enabled = NO;
        _prevItem = prevButtonItem;
    }
    return _prevItem;
}

- (UIBarButtonItem *)nextItem {
    if (!_nextItem) {
        UIBarButtonItem *nextButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEEditorSearchBarNextIcon"]
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(searchNextMatch)];
        nextButtonItem.tintColor = self.tintColor; // *
        nextButtonItem.enabled = NO;
        _nextItem = nextButtonItem;
    }
    return _nextItem;
}

@end
