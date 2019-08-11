//
//  XXTELogCell.m
//  XXTExplorer
//
//  Created by Zheng on 2018/4/14.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTELogCell.h"
#import "XXTEAutoLabel.h"

@interface XXTELogCell ()
@property (weak, nonatomic) IBOutlet XXTEAutoLabel *logLabel;

@end

@implementation XXTELogCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (@available(iOS 13.0, *)) {
        self.logLabel.textColor = [UIColor labelColor];
    } else {
        self.logLabel.textColor = [UIColor blackColor];
    }
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (@available(iOS 8.0, *)) {
        
    } else {
        XXTEAutoLabel *label = self.logLabel;
        CGFloat boundsWidth = CGRectGetWidth(label.bounds);
        if (label.preferredMaxLayoutWidth != boundsWidth) {
            label.preferredMaxLayoutWidth = boundsWidth;
            [label setNeedsUpdateConstraints];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setLogText:(NSString *)logText {
    self.logLabel.text = logText;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
