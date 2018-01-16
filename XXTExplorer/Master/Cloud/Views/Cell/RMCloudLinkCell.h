//
//  RMCloudLinkCell.h
//  XXTExplorer
//
//  Created by Zheng on 15/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMCloudExpandable.h"

static NSString * const RMCloudLinkCellReuseIdentifier = @"RMCloudLinkCellReuseIdentifier";

@interface RMCloudLinkCell : UITableViewCell <RMCloudExpandable>
@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) UILabel *valueTextLabel;
@property (weak, nonatomic) IBOutlet UIImageView *linkIconImageView;
@property (weak, nonatomic) IBOutlet UIView *topSepatator;
@property (weak, nonatomic) IBOutlet UIView *bottomSepatator;

@end
