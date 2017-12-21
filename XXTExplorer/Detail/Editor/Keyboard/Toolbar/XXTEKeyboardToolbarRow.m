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
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat barWidth = MIN(screenSize.width, screenSize.height);
    CGFloat barHeight = 44.f;
    
    self.frame = CGRectMake(0, 0, barWidth, barHeight);
    self.backgroundColor = [UIColor clearColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self configureSubviews];
}

- (void)configureSubviews {
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 16.0;
    [self.toolbar setItems:@[self.undoItem, fixedItem, self.redoItem, flexibleItem, self.snippetItem, fixedItem, self.dismissItem]];
    [self addSubview:self.toolbar];
}

#pragma mark - UIView Getters

- (UIToolbar *)toolbar {
    if (!_toolbar) {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [toolbar setBackgroundImage:[UIImage new]
                 forToolbarPosition:UIToolbarPositionAny
                         barMetrics:UIBarMetricsDefault];
        [toolbar setBackgroundColor:[UIColor clearColor]];
        [toolbar setTranslucent:YES];
        _toolbar = toolbar;
    }
    return _toolbar;
}

- (UIBarButtonItem *)dismissItem {
    if (!_dismissItem) {
        UIBarButtonItem *dismissItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEKeyboardDismiss"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissItemTapped:)];
        _dismissItem = dismissItem;
    }
    return _dismissItem;
}

- (UIBarButtonItem *)undoItem {
    if (!_undoItem) {
        UIBarButtonItem *undoItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEKeyboardUndo"] style:UIBarButtonItemStylePlain target:self action:@selector(undoItemTapped:)];
        undoItem.enabled = NO;
        _undoItem = undoItem;
    }
    return _undoItem;
}

- (UIBarButtonItem *)redoItem {
    if (!_redoItem) {
        UIBarButtonItem *redoItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEKeyboardRedo"] style:UIBarButtonItemStylePlain target:self action:@selector(redoItemTapped:)];
        redoItem.enabled = NO;
        _redoItem = redoItem;
    }
    return _redoItem;
}

- (UIBarButtonItem *)snippetItem {
    if (!_snippetItem) {
        UIBarButtonItem *snippetItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEKeyboardSnippet"] style:UIBarButtonItemStylePlain target:self action:@selector(snippetItemTapped:)];
        snippetItem.enabled = NO;
        _snippetItem = snippetItem;
    }
    return _snippetItem;
}

#pragma mark - Setters

- (void)setStyle:(XXTEKeyboardToolbarRowStyle)style {
    _style = style;
    UIToolbar *toolbar = self.toolbar;
    if (style == XXTEKeyboardToolbarRowStyleLight) {
        toolbar.barStyle = UIBarStyleDefault;
    } else {
        toolbar.barStyle = UIBarStyleBlack;
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    UIToolbar *toolbar = self.toolbar;
    toolbar.tintColor = tintColor;
    for (UIBarButtonItem *item in toolbar.items) {
        item.tintColor = tintColor;
    }
}

#pragma mark - Actions

- (void)dismissItemTapped:(UIBarButtonItem *)sender {
    if ([_delegate respondsToSelector:@selector(keyboardToolbarRow:didTapDismiss:)]) {
        [_delegate keyboardToolbarRow:self didTapDismiss:sender];
    }
}

- (void)undoItemTapped:(UIBarButtonItem *)sender {
    if ([_delegate respondsToSelector:@selector(keyboardToolbarRow:didTapUndo:)]) {
        [_delegate keyboardToolbarRow:self didTapUndo:sender];
    }
}

- (void)redoItemTapped:(UIBarButtonItem *)sender {
    if ([_delegate respondsToSelector:@selector(keyboardToolbarRow:didTapRedo:)]) {
        [_delegate keyboardToolbarRow:self didTapRedo:sender];
    }
}

- (void)snippetItemTapped:(UIBarButtonItem *)sender {
    if ([_delegate respondsToSelector:@selector(keyboardToolbarRow:didTapSnippet:)]) {
        [_delegate keyboardToolbarRow:self didTapSnippet:sender];
    }
}

@end
