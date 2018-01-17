//
//  RMCloudProjectDetailCell.h
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMProject.h"

static NSString * const RMCloudProjectDetailCellReuseIdentifier = @"RMCloudProjectDetailCellReuseIdentifier";

@interface RMCloudProjectDetailCell : UITableViewCell

@property (nonatomic, strong) RMProject *project;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIView *additionalArea;

@end
