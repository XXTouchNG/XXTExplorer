//
//  XXTExplorerFooterView.m
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerFooterView.h"
#import "XXTEInsetsLabel.h"

@interface XXTExplorerFooterView ()
@property (nonatomic, strong) UIButton *boxEmptyButton;

@end

@implementation XXTExplorerFooterView

@synthesize footerLabel = _footerLabel;

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

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self addSubview:self.footerLabel];
    [self addSubview:self.boxEmptyButton];
    CGRect newFrame = self.frame;
    newFrame.size.height = 92.f;
    self.frame = newFrame;
    self.footerLabel.hidden = YES;
    self.boxEmptyButton.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.footerLabel setFrame:self.contentView.bounds];
    [self.boxEmptyButton setFrame:self.contentView.bounds];
}

- (UILabel *)footerLabel {
    if (!_footerLabel) {
        XXTEInsetsLabel *textLabel = [[XXTEInsetsLabel alloc] initWithFrame:self.contentView.bounds];
        textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textLabel.textColor = XXTColorForeground();
        if (@available(iOS 13.0, *)) {
            textLabel.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            textLabel.backgroundColor = [UIColor whiteColor];
        }
        UIFont *font = [UIFont systemFontOfSize:14.0];
        textLabel.font = font;
        textLabel.edgeInsets = UIEdgeInsetsMake(0.0, 12.f, 24.0, 12.f);
        textLabel.numberOfLines = 1;
        textLabel.lineBreakMode = NSLineBreakByClipping;
        textLabel.textAlignment = NSTextAlignmentCenter;
        _footerLabel = textLabel;
    }
    return _footerLabel;
}

- (UIButton *)boxEmptyButton {
    if (!_boxEmptyButton) {
        UIFont *font = [UIFont systemFontOfSize:14.0];
        UIButton *boxButton = [[UIButton alloc] initWithFrame:self.contentView.bounds];
        boxButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        boxButton.titleLabel.textAlignment = NSTextAlignmentLeft;
        [boxButton setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 32.0)];
        [boxButton setImage:[[UIImage imageNamed:@"XXTEBoxEmpty"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
#ifndef APPSTORE
        NSString *boxString = NSLocalizedString(@"No script can be found.\nTap here to find more scripts.", nil);
#else
        NSString *boxString = NSLocalizedString(@"No file can be found.\nImport file via File Sharing or iTunes.", nil);
#endif
        if (@available(iOS 13.0, *)) {
            [boxButton setAttributedTitle:[[NSAttributedString alloc] initWithString:boxString attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor tertiaryLabelColor]}] forState:UIControlStateNormal];
            [boxButton setAttributedTitle:[[NSAttributedString alloc] initWithString:boxString attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor secondaryLabelColor]}] forState:UIControlStateHighlighted];
            [boxButton setTintColor:[UIColor tertiaryLabelColor]];
        } else {
            [boxButton setAttributedTitle:[[NSAttributedString alloc] initWithString:boxString attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor lightGrayColor]}] forState:UIControlStateNormal];
            [boxButton setAttributedTitle:[[NSAttributedString alloc] initWithString:boxString attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor darkGrayColor]}] forState:UIControlStateHighlighted];
            [boxButton setTintColor:[UIColor lightGrayColor]];
        }
        [boxButton addTarget:self action:@selector(emptyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        _boxEmptyButton = boxButton;
    }
    return _boxEmptyButton;
}

#pragma mark - Empty Mode

- (void)setEmptyMode:(BOOL)emptyMode {
    _emptyMode = emptyMode;
    if (emptyMode) {
        self.footerLabel.hidden = YES;
        self.boxEmptyButton.hidden = NO;
    } else {
        self.footerLabel.hidden = NO;
        self.boxEmptyButton.hidden = YES;
    }
}

- (void)emptyButtonTapped:(UIButton *)sender {
    if ([_delegate respondsToSelector:@selector(footerView:emptyButtonTapped:)]) {
        [_delegate footerView:self emptyButtonTapped:sender];
    }
}

@end
