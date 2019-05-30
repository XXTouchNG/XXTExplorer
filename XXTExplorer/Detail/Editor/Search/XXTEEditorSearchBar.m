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
@property (nonatomic, strong) UIImageView *replaceIcon;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) XXTEEditorSearchField *searchField;
@property (nonatomic, strong) XXTEEditorSearchField *replaceField;

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
    _regexMode = NO;
    _separatorColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    
    self.tintColor = [UIColor blackColor];
    
    [self addSubview:self.searchField];
    [self addSubview:self.replaceField];
    [self addSubview:self.magnifierIcon];
    [self addSubview:self.replaceIcon];
    [self addSubview:self.cancelButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat cancelWidth = CGRectGetWidth(_cancelButton.bounds);
    CGFloat fieldWidth = width - cancelWidth - 72.0;
    CGFloat fieldHeight = XXTEEditorSearchBarHeight / 2.0;
    _searchField.frame =
    CGRectMake(40.0,
               0.0,
               fieldWidth,
               fieldHeight);
    _replaceField.frame =
    CGRectMake(40.0,
               fieldHeight * 1,
               fieldWidth,
               fieldHeight);
    _magnifierIcon.frame =
    CGRectMake(16.0,
               fieldHeight / 2.0 - 8.0,
               16.0,
               16.0);
    _replaceIcon.frame =
    CGRectMake(16.0,
               fieldHeight * 1 + fieldHeight / 2.0 - 8.0,
               16.0,
               16.0);
    _cancelButton.frame =
    CGRectMake(width - cancelWidth - 16.0,
               0.0,
               cancelWidth,
               CGRectGetHeight(self.bounds));
    
    [self setNeedsDisplay];
}

#pragma mark - UIView Getters

- (XXTEEditorSearchField *)searchField {
    if (!_searchField) {
        XXTEEditorSearchField *searchField = [[XXTEEditorSearchField alloc] init];
        searchField.delegate = self;
        searchField.returnKeyType = UIReturnKeyNext;
        searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [searchField addTarget:self
                        action:@selector(textFieldDidChange:)
              forControlEvents:UIControlEventEditingChanged];
        _searchField = searchField;
    }
    return _searchField;
}

- (XXTEEditorSearchField *)replaceField {
    if (!_replaceField) {
        XXTEEditorSearchField *replaceField = [[XXTEEditorSearchField alloc] init];
        replaceField.delegate = self;
        replaceField.returnKeyType = UIReturnKeyNext;
        replaceField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [replaceField addTarget:self
                        action:@selector(textFieldDidChange:)
              forControlEvents:UIControlEventEditingChanged];
        _replaceField = replaceField;
    }
    return _replaceField;
}

- (UIImageView *)magnifierIcon {
    if (!_magnifierIcon) {
        UIImageView *magnifierIcon = [[UIImageView alloc] init];
        magnifierIcon.contentMode = UIViewContentModeScaleAspectFit;
        magnifierIcon.backgroundColor = [UIColor clearColor];
        magnifierIcon.image = [[UIImage imageNamed:@"XXTEEditorSearchBarIconSearch"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _magnifierIcon = magnifierIcon;
    }
    return _magnifierIcon;
}

- (UIImageView *)replaceIcon {
    if (!_replaceIcon) {
        UIImageView *replaceIcon = [[UIImageView alloc] init];
        replaceIcon.contentMode = UIViewContentModeScaleAspectFit;
        replaceIcon.backgroundColor = [UIColor clearColor];
        replaceIcon.image = [[UIImage imageNamed:@"XXTEEditorSearchBarIconReplace"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _replaceIcon = replaceIcon;
    }
    return _replaceIcon;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        UIButton *cancelButton = [[UIButton alloc] init];
        UIFont *font = [UIFont systemFontOfSize:14.0];
        cancelButton.titleLabel.font = font;
        [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [cancelButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter]; // fixed
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
    self.replaceIcon.tintColor = tintColor;
    self.searchField.tintColor = tintColor;
    self.replaceField.tintColor = tintColor;
    [self.cancelButton setTitleColor:tintColor forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    [self.cancelButton setTitleColor:[tintColor colorWithAlphaComponent:0.3] forState:UIControlStateDisabled];
}

#pragma mark - Draw

- (void)drawRect:(CGRect)rect {
    if (_separatorColor) {
        CGFloat lineOffset = CGRectGetMaxX(_searchField.frame);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(ctx, 0.5);
        CGContextSetStrokeColorWithColor(ctx, _separatorColor.CGColor);
        CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect) - 0.5);
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect) - 0.5);
        CGContextStrokePath(ctx);
        CGContextMoveToPoint(ctx, lineOffset, CGRectGetMinY(rect));
        CGContextAddLineToPoint(ctx, lineOffset, CGRectGetMaxY(rect) - 0.5);
        CGContextStrokePath(ctx);
        CGContextMoveToPoint(ctx, 0.0, CGRectGetMaxY(rect) / 2.0);
        CGContextAddLineToPoint(ctx, lineOffset, CGRectGetMaxY(rect) / 2.0);
        CGContextStrokePath(ctx);
    }
}

#pragma mark - Getters

- (NSString *)searchText {
    return self.searchField.text;
}

- (void)setSearchText:(NSString *)text {
    [self.searchField setText:text];
}

- (NSString *)replaceText {
    return self.replaceField.text;
}

- (void)setReplaceText:(NSString *)replaceText {
    [self.replaceField setText:replaceText];
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    [self.searchField setTextColor:textColor];
    [self.replaceField setTextColor:textColor];
}

- (UIView *)searchInputAccessoryView {
    return self.searchField.inputAccessoryView;
}

- (void)setSearchInputAccessoryView:(UIView *)inputAccessoryView {
    [self.searchField setInputAccessoryView:inputAccessoryView];
}

- (UIView *)replaceInputAccessoryView {
    return self.replaceInputAccessoryView.inputAccessoryView;
}

- (void)setReplaceInputAccessoryView:(UIView *)replaceInputAccessoryView {
    [self.replaceField setInputAccessoryView:replaceInputAccessoryView];
}

- (UIKeyboardAppearance)searchKeyboardAppearance {
    return self.searchField.keyboardAppearance;
}

- (void)setSearchKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    [self.searchField setKeyboardAppearance:keyboardAppearance];
}

- (UIKeyboardAppearance)replaceKeyboardAppearance {
    return self.replaceField.keyboardAppearance;
}

- (void)setReplaceKeyboardAppearance:(UIKeyboardAppearance)replaceKeyboardAppearance {
    [self.replaceField setKeyboardAppearance:replaceKeyboardAppearance];
}

- (BOOL)isFirstResponder {
    return (self.searchField.isFirstResponder || self.replaceField.isFirstResponder);
}

- (BOOL)becomeFirstResponder {
    return [self.searchField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    BOOL a = [self.searchField resignFirstResponder];
    BOOL b = [self.replaceField resignFirstResponder];
    return (a && b);
}

- (BOOL)canBecomeFirstResponder {
    return NO;
}

#pragma mark - Actions

- (void)cancelButtonTapped:(UIButton *)sender {
    [self.searchField resignFirstResponder];
    [self.replaceField resignFirstResponder];
    if ([_delegate respondsToSelector:@selector(searchBarDidCancel:)]) {
        [_delegate searchBarDidCancel:self];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.searchField) {
        if ([_delegate respondsToSelector:@selector(searchBar:searchFieldShouldReturn:)]) {
            return [_delegate searchBar:self searchFieldShouldReturn:textField];
        }
    } else if (textField == self.replaceField) {
        if ([_delegate respondsToSelector:@selector(searchBar:replaceFieldShouldReturn:)]) {
            return [_delegate searchBar:self replaceFieldShouldReturn:textField];
        }
    }
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
    if (textField == self.searchField) {
        if ([_delegate respondsToSelector:@selector(searchBar:searchFieldDidChange:)]) {
            [_delegate searchBar:self searchFieldDidChange:textField];
        }
    } else if (textField == self.replaceField) {
        if ([_delegate respondsToSelector:@selector(searchBar:replaceFieldDidChange:)]) {
            [_delegate searchBar:self replaceFieldDidChange:textField];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.searchField) {
        if ([_delegate respondsToSelector:@selector(searchBar:searchFieldDidBeginEditing:)]) {
            return [_delegate searchBar:self searchFieldDidBeginEditing:textField];
        }
    } else if (textField == self.replaceField) {
        if ([_delegate respondsToSelector:@selector(searchBar:replaceFieldDidBeginEditing::)]) {
            return [_delegate searchBar:self replaceFieldDidBeginEditing:textField];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.searchField) {
        if ([_delegate respondsToSelector:@selector(searchBar:searchFieldDidEndEditing:)]) {
            return [_delegate searchBar:self searchFieldDidEndEditing:textField];
        }
    } else if (textField == self.replaceField) {
        if ([_delegate respondsToSelector:@selector(searchBar:replaceFieldDidEndEditing:)]) {
            return [_delegate searchBar:self replaceFieldDidEndEditing:textField];
        }
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.searchField) {
        if ([_delegate respondsToSelector:@selector(searchBar:searchFieldShouldBeginEditing:)]) {
            return [_delegate searchBar:self searchFieldShouldBeginEditing:textField];
        }
    } else if (textField == self.replaceField) {
        if ([_delegate respondsToSelector:@selector(searchBar:replaceFieldShouldBeginEditing:)]) {
            return [_delegate searchBar:self replaceFieldShouldBeginEditing:textField];
        }
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (textField == self.searchField) {
        if ([_delegate respondsToSelector:@selector(searchBar:searchFieldShouldEndEditing:)]) {
            return [_delegate searchBar:self searchFieldShouldEndEditing:textField];
        }
    } else if (textField == self.replaceField) {
        if ([_delegate respondsToSelector:@selector(searchBar:replaceFieldShouldEndEditing:)]) {
            return [_delegate searchBar:self replaceFieldShouldEndEditing:textField];
        }
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (textField == self.searchField) {
        if ([_delegate respondsToSelector:@selector(searchBar:searchFieldShouldClear:)]) {
            return [_delegate searchBar:self searchFieldShouldClear:textField];
        }
    } else if (textField == self.replaceField) {
        if ([_delegate respondsToSelector:@selector(searchBar:replaceFieldShouldClear:)]) {
            return [_delegate searchBar:self replaceFieldShouldClear:textField];
        }
    }
    return YES;
}

#pragma mark - Setters

- (void)setRegexMode:(BOOL)regexMode {
    _regexMode = regexMode;
}

#pragma mark - Update

- (void)updateView {
    if (_regexMode == YES) {
        self.searchField.placeholder = NSLocalizedString(@"Search Regex...", nil);
        self.replaceField.placeholder = NSLocalizedString(@"Replace Regex...", nil);
    } else {
        self.searchField.placeholder = NSLocalizedString(@"Search Text...", nil);
        self.replaceField.placeholder = NSLocalizedString(@"Replace Text...", nil);
    }
}

@end
