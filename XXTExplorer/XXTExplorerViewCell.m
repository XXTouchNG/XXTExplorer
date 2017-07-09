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

- (void)setup {
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFlagType:(XXTExplorerViewCellFlagType)flagType {
    _flagType = flagType;
    if (flagType == XXTExplorerViewCellFlagTypeSelected) {
        self.flagIconImageView.image = [UIImage imageNamed:@"XXTExplorerSelectedScriptFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeForbidden) {
        self.flagIconImageView.image = [UIImage imageNamed:@"XXTExplorerForbiddenFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeBroken) {
        self.flagIconImageView.image = [UIImage imageNamed:@"XXTExplorerBrokenFlag"];
    }
    if (flagType == XXTExplorerViewCellFlagTypeNone) {
        self.flagIconImageView.hidden = YES;
    } else {
        self.flagIconImageView.hidden = NO;
    }
}

@end
