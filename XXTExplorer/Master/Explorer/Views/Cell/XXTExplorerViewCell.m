//
//  XXTExplorerViewCell.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewCell.h"

@interface XXTExplorerViewCell ()

@end

@implementation XXTExplorerViewCell

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self setup];
}

- (void)setup {
    self.flagIconImageView.layer.shadowOffset = CGSizeMake(0, 0);
    self.flagIconImageView.layer.shadowColor = [UIColor colorWithWhite:0.f alpha:1.f].CGColor;
    self.flagIconImageView.layer.shadowOpacity = .3f;
    self.flagIconImageView.layer.shadowRadius = 1.f;
    self.flagIconImageView.layer.masksToBounds = NO;
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = [XXTE_COLOR colorWithAlphaComponent:0.1f];
    self.selectedBackgroundView = selectionBackground;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFlagType:(XXTExplorerViewCellFlagType)flagType {
    _flagType = flagType;
    if (flagType == XXTExplorerViewCellFlagTypeSelected) {
        self.flagIconImageView.image = [UIImage imageNamed:@"XXTExplorerSelectedScriptFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedInside) {
        self.flagIconImageView.image = [UIImage imageNamed:@"XXTExplorerSelectedScriptInsideFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeForbidden) {
        self.flagIconImageView.image = [UIImage imageNamed:@"XXTExplorerForbiddenFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeBroken) {
        self.flagIconImageView.image = [UIImage imageNamed:@"XXTExplorerBrokenFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedBootScript) {
        self.flagIconImageView.image = [UIImage imageNamed:@"XXTExplorerSelectedBootScriptFlag"];
    }
    if (flagType == XXTExplorerViewCellFlagTypeNone) {
        self.flagIconImageView.hidden = YES;
    } else {
        self.flagIconImageView.hidden = NO;
    }
}

@end
