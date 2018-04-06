//
//  XXTEMoreValueView.m
//  XXTouchApp
//
//  Created by Zheng on 02/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import "XXTEMoreValueView.h"

@interface XXTEMoreValueView ()
@property (nonatomic, strong) UIButton *upView;
@property (nonatomic, strong) UILabel *upTriView;
@property (nonatomic, strong) UIButton *downView;
@property (nonatomic, strong) UILabel *downTriView;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *ptLabel;
@property (nonatomic, strong) UIColor *separatorColor;

@end

@implementation XXTEMoreValueView

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

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    _separatorColor = [XXTColorDefault() colorWithAlphaComponent:0.1];
    _maxValue = 32.0;
    _minValue = 8.0;
    _stepValue = 1.0;
    _isInteger = YES;
    _unitString = @"pt";
    
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderColor = XXTColorDefault().CGColor;
    self.layer.borderWidth = 1.f;
    self.layer.cornerRadius = 6.f;
    
    [self addSubview:self.sizeLabel];
    [self addSubview:self.ptLabel];
    
    UIButton *upView = [[UIButton alloc] init];
    upView.showsTouchWhenHighlighted = YES;
    [upView addTarget:self action:@selector(increaseValue:) forControlEvents:UIControlEventTouchUpInside];
    upView.backgroundColor = [UIColor clearColor];
    UILabel *upTriView = [[UILabel alloc] initWithFrame:CGRectZero];
    upTriView.font = [UIFont systemFontOfSize:14.f];
    upTriView.textColor = XXTColorDefault();
    upTriView.text = @"▲";
    [upTriView sizeToFit];
    self.upTriView = upTriView;
    [upView addSubview:upTriView];
    [self addSubview:upView];
    self.upView = upView;
    
    UIButton *downView = [[UIButton alloc] init];
    downView.showsTouchWhenHighlighted = YES;
    [downView addTarget:self action:@selector(decreaseValue:) forControlEvents:UIControlEventTouchUpInside];
    downView.backgroundColor = [UIColor clearColor];
    UILabel *downTriView = [[UILabel alloc] initWithFrame:CGRectZero];
    downTriView.font = [UIFont systemFontOfSize:14.f];
    downTriView.textColor = XXTColorDefault();
    downTriView.text = @"▼";
    [downTriView sizeToFit];
    [downView addSubview:downTriView];
    self.downTriView = downTriView;
    [self addSubview:downView];
    self.downView = downView;
    
    [self setValue:self.value];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.upView.frame =
    CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height / 2);
    self.downView.frame =
    CGRectMake(0, self.bounds.size.height / 2, self.bounds.size.width, self.bounds.size.height / 2);
    
    self.upTriView.center =
    CGPointMake(self.upView.bounds.size.width / 6 * 5, self.upView.bounds.size.height / 2);
    self.downTriView.center =
    CGPointMake(self.downView.bounds.size.width / 6 * 5, self.downView.bounds.size.height / 2);
    
    self.sizeLabel.center =
    CGPointMake(self.bounds.size.width / 2 - self.sizeLabel.bounds.size.width / 3, self.bounds.size.height / 2);
    self.ptLabel.frame =
    CGRectMake(CGRectGetMaxX(self.sizeLabel.frame) + 4.0, self.sizeLabel.frame.origin.y + self.sizeLabel.bounds.size.height - self.ptLabel.bounds.size.height, self.ptLabel.bounds.size.width, self.ptLabel.bounds.size.height);
}

- (void)increaseValue:(UIButton *)btn {
    if (self.maxValue - self.value > 0.01) {
        self.value = self.value + self.stepValue;
        [self notifyChanged];
    }
}

- (void)decreaseValue:(UIButton *)btn {
    if (self.value - self.minValue > 0.01) {
        self.value = self.value - self.stepValue;
        [self notifyChanged];
    }
}

- (void)notifyChanged {
    if (_delegate && [_delegate respondsToSelector:@selector(valueViewValueDidChanged:)])
    {
        [_delegate valueViewValueDidChanged:self];
    }
}

- (void)setUnitString:(NSString *)unitString {
    _unitString = unitString;
    self.ptLabel.text = unitString;
    [self.ptLabel sizeToFit];
}

- (void)setIsInteger:(BOOL)isInteger {
    _isInteger = isInteger;
    [self setValue:self.value];
}

- (UILabel *)ptLabel {
    if (!_ptLabel) {
        UILabel *ptLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        ptLabel.textAlignment = NSTextAlignmentCenter;
        ptLabel.font = [UIFont boldSystemFontOfSize:14.f];
        ptLabel.textColor = XXTColorDefault();
        ptLabel.text = self.unitString;
        [ptLabel sizeToFit];
        _ptLabel = ptLabel;
    }
    return _ptLabel;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        if (@available(iOS 9.0, *)) {
            sizeLabel.font = [UIFont monospacedDigitSystemFontOfSize:36.f weight:UIFontWeightMedium];
        } else {
            sizeLabel.font = [UIFont boldSystemFontOfSize:36.f];
        }
        sizeLabel.textColor = XXTColorDefault();
        _sizeLabel = sizeLabel;
    }
    return _sizeLabel;
}

- (void)setValue:(CGFloat)fontSize {
    _value = fontSize;
    if (self.isInteger) {
        self.sizeLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.value];
    } else {
        self.sizeLabel.text = [NSString stringWithFormat:@"%.1f", self.value];
    }
    [self.sizeLabel sizeToFit];
    [self setNeedsLayout];
}

- (void)drawRect:(CGRect)rect {
    if (_separatorColor) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSetStrokeColorWithColor(ctx, _separatorColor.CGColor);
        CGContextMoveToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect) / 2.0);
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect) / 2.0);
        CGContextStrokePath(ctx);
    }
}

@end
