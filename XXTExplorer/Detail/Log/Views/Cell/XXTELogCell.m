//
//  XXTELogCell.m
//  XXTExplorer
//
//  Created by Zheng on 2018/4/14.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTELogCell.h"

@interface XXTELogCell ()
@property (weak, nonatomic) IBOutlet UILabel *logLabel;
@end

@implementation XXTELogCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.logLabel.textColor = XXTColorPlainTitleText();
    self.tintColor = XXTColorForeground();
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
}

- (void)setLogText:(NSString *)logText {
    _logText = logText;
    self.logLabel.text = logText;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setAttributedLogText:(NSAttributedString *)logText {
    _logText = [logText string];
    self.logLabel.attributedText = logText;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
