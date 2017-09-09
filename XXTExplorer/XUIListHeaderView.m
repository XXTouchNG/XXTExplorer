//
//  XUIListHeaderView.m
//  XXTExplorer
//
//  Created by Zheng on 2017/7/21.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XUIListHeaderView.h"

@interface XUIListHeaderView ()

@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *subheaderLabel;

@property (nonatomic, strong) NSDictionary *headerAttributes;
@property (nonatomic, strong) NSDictionary *subheaderAttributes;

@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat subheaderHeight;

@end

@implementation XUIListHeaderView

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
    _headerAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:45.f],
                           NSForegroundColorAttributeName: [UIColor colorWithWhite:0.f alpha:.85f] };
    _subheaderAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:18.f],
                              NSForegroundColorAttributeName: [UIColor colorWithWhite:0.f alpha:.85f] };
    
    [self addSubview:self.headerLabel];
    [self addSubview:self.subheaderLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.headerLabel.frame = CGRectMake(20.f, 40.f, self.bounds.size.width - 40.f, self.headerHeight);
    self.subheaderLabel.frame = CGRectMake(20.f, 40.f + self.headerHeight + 12.f, self.bounds.size.width - 40.f, self.subheaderHeight);
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.bounds.size.width, 40.f + CGRectGetHeight(self.headerLabel.bounds) + 12.f + CGRectGetHeight(self.subheaderLabel.bounds) + 20.f);
}

#pragma mark - UIView Getters

- (UILabel *)headerLabel {
    if (!_headerLabel) {
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        headerLabel.backgroundColor = UIColor.clearColor;
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.numberOfLines = 1;
        headerLabel.lineBreakMode = NSLineBreakByClipping;
        _headerLabel = headerLabel;
    }
    return _headerLabel;
}

- (UILabel *)subheaderLabel {
    if (!_subheaderLabel) {
        UILabel *subheaderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subheaderLabel.backgroundColor = UIColor.clearColor;
        subheaderLabel.textAlignment = NSTextAlignmentCenter;
        subheaderLabel.numberOfLines = 0;
        subheaderLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _subheaderLabel = subheaderLabel;
    }
    return _subheaderLabel;
}

- (void)setHeaderText:(NSString *)headerText {
    _headerText = headerText;
    
    NSAttributedString *attributedHeaderText = [[NSAttributedString alloc] initWithString:headerText attributes:self.headerAttributes];
    [self.headerLabel setAttributedText:attributedHeaderText];
    
    self.headerHeight = [attributedHeaderText boundingRectWithSize:CGSizeMake(self.bounds.size.width - 40.f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
}

- (void)setSubheaderText:(NSString *)subheaderText {
    _subheaderText = subheaderText;
    
    NSAttributedString *attributedSubheaderText = [[NSAttributedString alloc] initWithString:subheaderText attributes:self.subheaderAttributes];
    [self.subheaderLabel setAttributedText:attributedSubheaderText];
    
    self.subheaderHeight = [attributedSubheaderText boundingRectWithSize:CGSizeMake(self.bounds.size.width - 40.f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.height;
}

@end
