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
@property (weak, nonatomic) IBOutlet UIImageView *animationView;

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
    
    self.accessoryType = UITableViewCellAccessoryNone;
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
}

- (UIImage *)indicatorImageForFlagType:(XXTExplorerViewCellFlagType)flagType {
    if (flagType == XXTExplorerViewCellFlagTypeSelected) {
        return [UIImage imageNamed:@"XXTEColoredPixelSuccess"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedInside) {
        return [UIImage imageNamed:@"XXTEColoredPixelSuccess"];
    } else if (flagType == XXTExplorerViewCellFlagTypeForbidden) {
        return nil;
    } else if (flagType == XXTExplorerViewCellFlagTypeBroken) {
        return nil;
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedBootScript) {
        return [UIImage imageNamed:@"XXTEColoredPixelNormal"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedBootScriptInside) {
        return [UIImage imageNamed:@"XXTEColoredPixelNormal"];
    }
    return nil;
}

- (UIImage *)flagImageForFlagType:(XXTExplorerViewCellFlagType)flagType {
    if (flagType == XXTExplorerViewCellFlagTypeSelected) {
        return [UIImage imageNamed:@"XXTExplorerSelectedScriptFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedInside) {
        return [UIImage imageNamed:@"XXTExplorerSelectedScriptInsideFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeForbidden) {
        return [UIImage imageNamed:@"XXTExplorerForbiddenFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeBroken) {
        return [UIImage imageNamed:@"XXTExplorerBrokenFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedBootScript) {
        return [UIImage imageNamed:@"XXTExplorerSelectedBootScriptFlag"];
    } else if (flagType == XXTExplorerViewCellFlagTypeSelectedBootScriptInside) {
        return [UIImage imageNamed:@"XXTExplorerSelectedBootScriptInsideFlag"];
    }
    return nil;
}

- (void)setFlagType:(XXTExplorerViewCellFlagType)flagType {
    _flagType = flagType;
    
    UIImageView *imageView = self.flagIconImageView;
    UIImageView *indicatorView = self.indicatorView;
    
    imageView.image = [self flagImageForFlagType:flagType];
    indicatorView.image = [self indicatorImageForFlagType:flagType];
    
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

//- (void)animateIndicatorForFlagType:(XXTExplorerViewCellFlagType)flagType {
//    UIImage *image = [self indicatorImageForFlagType:flagType];
//    if (image == nil) {
//        return;
//    }
//    UIImageView *animationView = self.animationView;
//    if (!animationView.hidden) {
//        return;
//    }
//    [animationView setImage:image];
//    animationView.transform = CGAffineTransformIdentity;
//    [animationView setHidden:NO];
//    [UIView animateWithDuration:0.27f delay:0.6f options:UIViewAnimationOptionCurveEaseOut animations:^{
//        animationView.transform = CGAffineTransformMakeTranslation(-CGRectGetWidth(animationView.bounds), 0);
//    } completion:^(BOOL finished) {
//        [animationView setHidden:YES];
//        animationView.transform = CGAffineTransformIdentity;
//    }];
//}

@end
