//
//  XXTExplorerViewCell.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewCell.h"

@interface XXTExplorerViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *indicatorView;

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
    [self setup];
}

- (void)setup {
    self.tintColor = XXTColorDefault();
    
    self.flagIconImageView.layer.shadowOffset = CGSizeMake(0, 0);
    self.flagIconImageView.layer.shadowColor = [UIColor colorWithWhite:0.f alpha:1.f].CGColor;
    self.flagIconImageView.layer.shadowOpacity = .3f;
    self.flagIconImageView.layer.shadowRadius = 1.f;
    self.flagIconImageView.layer.masksToBounds = NO;
    
    self.accessoryType = UITableViewCellAccessoryDetailButton;
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = [XXTColorDefault() colorWithAlphaComponent:0.1f];
    self.selectedBackgroundView = selectionBackground;
}

- (void)setFlagType:(XXTExplorerViewCellFlagType)flagType {
    _flagType = flagType;
    
    UIImageView *imageView = self.flagIconImageView;
    UIImageView *indicatorView = self.indicatorView;
    
    if (flagType == XXTExplorerViewCellFlagTypeSelected) {
        imageView.image = [UIImage imageNamed:@"XXTExplorerSelectedScriptFlag"];
        indicatorView.image = [UIImage imageNamed:@"XXTEColoredPixelSuccess"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedInside) {
        imageView.image = [UIImage imageNamed:@"XXTExplorerSelectedScriptInsideFlag"];
        indicatorView.image = [UIImage imageNamed:@"XXTEColoredPixelSuccess"];
    } else if (flagType == XXTExplorerViewCellFlagTypeForbidden) {
        imageView.image = [UIImage imageNamed:@"XXTExplorerForbiddenFlag"];
        indicatorView.image = nil;
    } else if (flagType == XXTExplorerViewCellFlagTypeBroken) {
        imageView.image = [UIImage imageNamed:@"XXTExplorerBrokenFlag"];
        indicatorView.image = nil;
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedBootScript) {
        imageView.image = [UIImage imageNamed:@"XXTExplorerSelectedBootScriptFlag"];
        indicatorView.image = [UIImage imageNamed:@"XXTEColoredPixelNormal"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedBootScriptInside) {
        imageView.image = [UIImage imageNamed:@"XXTExplorerSelectedBootScriptInsideFlag"];
        indicatorView.image = [UIImage imageNamed:@"XXTEColoredPixelNormal"];
    }
    
    if (flagType == XXTExplorerViewCellFlagTypeNone) {
        imageView.hidden = YES;
        indicatorView.hidden = YES;
    } else {
        imageView.hidden = NO;
        indicatorView.hidden = NO;
    }
}

- (UIColor *)flagColor {
    XXTExplorerViewCellFlagType flagType = self.flagType;
    if (flagType == XXTExplorerViewCellFlagTypeSelected
        || flagType == XXTExplorerViewCellFlagTypeSelectedInside) {
        return XXTColorSuccess();
    } else if (flagType == XXTExplorerViewCellFlagTypeForbidden
               || flagType == XXTExplorerViewCellFlagTypeBroken) {
        return XXTColorDanger();
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedBootScript
               || flagType == XXTExplorerViewCellFlagTypeSelectedBootScriptInside) {
        return XXTColorDefault();
    }
    return XXTColorDefault();
}

@end
