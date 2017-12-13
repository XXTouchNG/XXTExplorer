//
//  XXTExplorerViewHomeCell.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *XXTExplorerViewHomeCellReuseIdentifier = @"XXTExplorerViewHomeCellReuseIdentifier";
static CGFloat XXTExplorerViewHomeCellHeight = 68.f;

@interface XXTExplorerViewHomeCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *entryIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *entryTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *entrySubtitleLabel;

@end
