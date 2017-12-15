//
//  XXTEEditorSearchBar.m
//  XXTExplorer
//
//  Created by Zheng Wu on 14/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchBar.h"

@interface XXTEEditorSearchBar ()

@property (nonatomic, strong) UIImageView *magnifierIcon;

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
    [self addSubview:self.searchField];
    [self addSubview:self.magnifierIcon];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _searchField.frame = CGRectMake(16.0 + 16.0 + 8.0, 0.0, CGRectGetWidth(self.bounds) - 16.0 - 16.0 - 16.0 - 8.0, CGRectGetHeight(self.bounds));
    _magnifierIcon.frame = CGRectMake(16.0, (CGRectGetHeight(self.bounds) - 16.0) / 2.0, 16.0, 16.0);
    _searchAccessoryView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.bounds), 40.f);
}

#pragma mark - UIView Getters

- (XXTEEditorSearchField *)searchField {
    if (!_searchField) {
        XXTEEditorSearchField *searchField = [[XXTEEditorSearchField alloc] init];
        searchField.placeholder = NSLocalizedString(@"Search...", nil);
        searchField.inputAccessoryView = self.searchAccessoryView;
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

- (XXTEEditorSearchAccessoryView *)searchAccessoryView {
    if (!_searchAccessoryView) {
        _searchAccessoryView = [[XXTEEditorSearchAccessoryView alloc] initWithFrame:self.bounds];
    }
    return _searchAccessoryView;
}

#pragma mark - Setters

- (void)setSeparatorColor:(UIColor *)separatorColor {
    _separatorColor = separatorColor;
    [self setNeedsDisplay];
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    self.magnifierIcon.tintColor = tintColor;
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

@end
