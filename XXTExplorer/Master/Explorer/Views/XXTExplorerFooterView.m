//
//  XXTExplorerFooterView.m
//  XXTExplorer
//
//  Created by Zheng on 28/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerFooterView.h"
#import "XXTEInsetsLabel.h"

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
    CGRect newFrame = self.frame;
    newFrame.size.height = 92.f;
    self.frame = newFrame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.footerLabel setFrame:self.contentView.bounds];
}

- (UILabel *)footerLabel {
    if (!_footerLabel) {
        XXTEInsetsLabel *textLabel = [[XXTEInsetsLabel alloc] initWithFrame:self.contentView.bounds];
        textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textLabel.textColor = XXTE_COLOR;
        textLabel.backgroundColor = [UIColor whiteColor];
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 8.2, *)) {
            textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightLight];
        } else {
            textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.f];
        }
        XXTE_END_IGNORE_PARTIAL
        textLabel.edgeInsets = UIEdgeInsetsMake(0.0, 12.f, 24.0, 12.f);
        textLabel.numberOfLines = 1;
        textLabel.lineBreakMode = NSLineBreakByClipping;
        textLabel.textAlignment = NSTextAlignmentCenter;
        _footerLabel = textLabel;
    }
    return _footerLabel;
}

@end
