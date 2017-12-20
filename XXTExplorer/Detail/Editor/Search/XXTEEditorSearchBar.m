//
//  XXTEEditorSearchBar.m
//  XXTExplorer
//
//  Created by Zheng Wu on 14/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchBar.h"

@interface XXTEEditorSearchBar () <UITextFieldDelegate>

@property (nonatomic, strong) UIImageView *magnifierIcon;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) XXTEEditorSearchField *searchField;

@end

@implementation XXTEEditorSearchBar

- (instancetype)init {
    if (self = [super init]) {
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

- (void)setup {
    _separatorColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    
    self.tintColor = [UIColor blackColor];
    
    [self addSubview:self.searchField];
    [self addSubview:self.magnifierIcon];
    [self addSubview:self.cancelButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _searchField.frame =
    CGRectMake(16.0 + 16.0 + 8.0,
               0.0,
               CGRectGetWidth(self.bounds) - 16.0 - 16.0 - 16.0 - 8.0 - CGRectGetWidth(_cancelButton.bounds) - 16.0,
               CGRectGetHeight(self.bounds));
    _magnifierIcon.frame =
    CGRectMake(16.0,
               (CGRectGetHeight(self.bounds) - 16.0) / 2.0,
               16.0,
               16.0);
    _cancelButton.frame =
    CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(_cancelButton.bounds) - 16.0,
               0.0,
               CGRectGetWidth(_cancelButton.bounds),
               44.f);
}

#pragma mark - UIView Getters

- (XXTEEditorSearchField *)searchField {
    if (!_searchField) {
        XXTEEditorSearchField *searchField = [[XXTEEditorSearchField alloc] init];
        searchField.placeholder = NSLocalizedString(@"Search...", nil);
        searchField.delegate = self;
        [searchField addTarget:self
                        action:@selector(textFieldDidChange:)
              forControlEvents:UIControlEventEditingChanged];
        _searchField = searchField;
    }
    return _searchField;
}

- (UIImageView *)magnifierIcon {
    if (!_magnifierIcon) {
        UIImageView *magnifierIcon = [[UIImageView alloc] init];
        magnifierIcon.contentMode = UIViewContentModeScaleAspectFit;
        magnifierIcon.backgroundColor = [UIColor clearColor];
        magnifierIcon.image = [[UIImage imageNamed:@"XXTEEditorSearchBarIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _magnifierIcon = magnifierIcon;
    }
    return _magnifierIcon;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        UIButton *cancelButton = [[UIButton alloc] init];
        UIFont *font = nil;
        if (@available(iOS 8.2, *)) {
            font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightLight];
        } else {
            font = [UIFont systemFontOfSize:14.0];
        }
        cancelButton.titleLabel.font = font;
        [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton sizeToFit];
        _cancelButton = cancelButton;
    }
    return _cancelButton;
}

#pragma mark - Setters

- (void)setSeparatorColor:(UIColor *)separatorColor {
    _separatorColor = separatorColor;
    [self setNeedsDisplay];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.magnifierIcon.tintColor = tintColor;
    self.searchField.tintColor = tintColor;
    [self.cancelButton setTitleColor:tintColor forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    [self.cancelButton setTitleColor:[tintColor colorWithAlphaComponent:0.3] forState:UIControlStateDisabled];
}

#pragma mark - Draw

- (void)drawRect:(CGRect)rect {
    if (_separatorColor) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetStrokeColorWithColor(ctx, _separatorColor.CGColor);
        CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
        CGContextStrokePath(ctx);
    }
}

#pragma mark - Getters

- (NSString *)text {
    return self.searchField.text;
}

- (void)setText:(NSString *)text {
    [self.searchField setText:text];
}

- (UIColor *)textColor {
    return self.searchField.textColor;
}

- (void)setTextColor:(UIColor *)textColor {
    [self.searchField setTextColor:textColor];
}

- (UIView *)inputAccessoryView {
    return self.searchField.inputAccessoryView;
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView {
    [self.searchField setInputAccessoryView:inputAccessoryView];
}

- (UIKeyboardAppearance)keyboardAppearance {
    return self.searchField.keyboardAppearance;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    [self.searchField setKeyboardAppearance:keyboardAppearance];
}

- (BOOL)isFirstResponder {
    return self.searchField.isFirstResponder;
}

- (BOOL)becomeFirstResponder {
    return [self.searchField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.searchField resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

#pragma mark - Actions

- (void)cancelButtonTapped:(UIButton *)sender {
    [self.searchField resignFirstResponder];
    [self updateCancelButton];
}

- (void)updateCancelButton {
    self.cancelButton.enabled = (self.searchField.isFirstResponder);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([_delegate respondsToSelector:@selector(searchBar:textFieldShouldReturn:)]) {
        return [_delegate searchBar:self textFieldShouldReturn:textField];
    }
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
    if ([_delegate respondsToSelector:@selector(searchBar:textFieldDidChange:)]) {
        [_delegate searchBar:self textFieldDidChange:textField];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self updateCancelButton];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateCancelButton];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if ([_delegate respondsToSelector:@selector(searchBar:textFieldShouldClear:)]) {
        return [_delegate searchBar:self textFieldShouldClear:textField];
    }
    return YES;
}

@end
