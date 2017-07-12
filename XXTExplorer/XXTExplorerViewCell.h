//
//  XXTExplorerViewCell.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTESwipeTableCell.h"

typedef enum : NSUInteger {
    XXTExplorerViewCellFlagTypeNone = 0,
    XXTExplorerViewCellFlagTypeSelected,
    XXTExplorerViewCellFlagTypeSelectedInside,
    XXTExplorerViewCellFlagTypeForbidden,
    XXTExplorerViewCellFlagTypeBroken,
    XXTExplorerViewCellFlagTypeSelectedBootScript,
} XXTExplorerViewCellFlagType;

static NSString * const XXTExplorerViewCellReuseIdentifier = @"XXTExplorerViewCellReuseIdentifier";
static CGFloat XXTExplorerViewCellHeight = 66.f;

@interface XXTExplorerViewCell : XXTESwipeTableCell
@property (weak, nonatomic) IBOutlet UIImageView *entryIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *entryTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *entrySubtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *flagIconImageView;

@property (nonatomic, assign) XXTExplorerViewCellFlagType flagType;

@end
