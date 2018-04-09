//
//  XXTESymbolCell.m
//  XXTExplorer
//
//  Created by Zheng on 06/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESymbolCell.h"

NSString * const XXTESymbolCellReuseIdentifier = @"XXTESymbolCellReuseIdentifier";

@interface XXTESymbolCell ()

@end

@implementation XXTESymbolCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.typeBackgroundView.layer.backgroundColor =
    [UIColor colorWithRed:155.0 / 255.0 green:89.0 / 255.0 blue:182.0 / 255.0 alpha:1.0].CGColor;
    self.typeBackgroundView.layer.cornerRadius = 4.f;
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
}

@end
