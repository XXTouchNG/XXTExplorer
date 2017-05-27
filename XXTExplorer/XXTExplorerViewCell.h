//
//  XXTExplorerViewCell.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *XXTExplorerViewCellReuseIdentifier = @"XXTExplorerViewCellReuseIdentifier";
static CGFloat XXTExplorerViewCellHeight = 66.f;

@interface XXTExplorerViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *entryIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *entryTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *entrySubtitleLabel;

@end
