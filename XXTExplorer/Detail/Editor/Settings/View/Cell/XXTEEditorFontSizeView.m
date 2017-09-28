//
//  XXTEEditorFontSizeView.m
//  XXTouchApp
//
//  Created by Zheng on 02/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTEEditorFontSizeView.h"

@interface XXTEEditorFontSizeView ()
@property (nonatomic, strong) UIButton *upView;
@property (nonatomic, strong) UIButton *downView;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *ptLabel;
@property (nonatomic, strong) UILabel *upTriView;
@property (nonatomic, strong) UILabel *downTriView;

@end

@implementation XXTEEditorFontSizeView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderColor = XXTE_COLOR.CGColor;
    self.layer.borderWidth = 1.f;
    self.layer.cornerRadius = 6.f;
    
    [self addSubview:self.sizeLabel];
    [self addSubview:self.ptLabel];
    
    UIButton *upView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height / 2)];
    upView.showsTouchWhenHighlighted = YES;
    [upView addTarget:self action:@selector(increaseFontSize:) forControlEvents:UIControlEventTouchUpInside];
    upView.backgroundColor = [UIColor clearColor];
    UILabel *upTriView = [[UILabel alloc] initWithFrame:CGRectZero];
    upTriView.font = [UIFont systemFontOfSize:14.f];
    upTriView.textColor = XXTE_COLOR;
    upTriView.text = @"▲";
    [upTriView sizeToFit];
    upTriView.center = CGPointMake(upView.bounds.size.width / 6 * 5, upView.bounds.size.height / 2);
    [upView addSubview:upTriView];
    [self addSubview:upView];
    self.upView = upView;
    
    UIButton *downView = [[UIButton alloc] initWithFrame:CGRectMake(0, self.bounds.size.height / 2, self.bounds.size.width, self.bounds.size.height / 2)];
    downView.showsTouchWhenHighlighted = YES;
    [downView addTarget:self action:@selector(decreaseFontSize:) forControlEvents:UIControlEventTouchUpInside];
    downView.backgroundColor = [UIColor clearColor];
    UILabel *downTriView = [[UILabel alloc] initWithFrame:CGRectZero];
    downTriView.font = [UIFont systemFontOfSize:14.f];
    downTriView.textColor = XXTE_COLOR;
    downTriView.text = @"▼";
    [downTriView sizeToFit];
    downTriView.center = CGPointMake(downView.bounds.size.width / 6 * 5, downView.bounds.size.height / 2);
    [downView addSubview:downTriView];
    [self addSubview:downView];
    self.downView = downView;
    
    [self setFontSize:self.fontSize];
}

- (void)increaseFontSize:(UIButton *)btn {
    if (self.fontSize < MAX_FONT_SIZE) {
        self.fontSize = self.fontSize + 1;
        [self notifyChanged];
    }
}

- (void)decreaseFontSize:(UIButton *)btn {
    if (self.fontSize > MIN_FONT_SIZE) {
        self.fontSize = self.fontSize - 1;
        [self notifyChanged];
    }
}

- (void)notifyChanged {
    if (_delegate && [_delegate respondsToSelector:@selector(fontViewSizeDidChanged:)])
    {
        [_delegate fontViewSizeDidChanged:self];
    }
}

- (UILabel *)ptLabel {
    if (!_ptLabel) {
        UILabel *ptLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        ptLabel.font = [UIFont boldSystemFontOfSize:14.f];
        ptLabel.textColor = XXTE_COLOR;
        ptLabel.text = NSLocalizedString(@"pt", nil);
        [ptLabel sizeToFit];
        _ptLabel = ptLabel;
    }
    return _ptLabel;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        sizeLabel.font = [UIFont boldSystemFontOfSize:36.f];
        sizeLabel.textColor = XXTE_COLOR;
        _sizeLabel = sizeLabel;
    }
    return _sizeLabel;
}

- (void)setFontSize:(NSUInteger)fontSize {
    _fontSize = fontSize;
    self.sizeLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.fontSize];
    [self.sizeLabel sizeToFit];
    self.sizeLabel.center = CGPointMake(self.bounds.size.width / 2 - self.sizeLabel.bounds.size.width / 2, self.bounds.size.height / 2);
    self.ptLabel.frame = CGRectMake(self.bounds.size.width / 2 + 4, self.sizeLabel.frame.origin.y + self.sizeLabel.bounds.size.height - self.ptLabel.bounds.size.height, self.bounds.size.width, self.bounds.size.height);
}

@end
