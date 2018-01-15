//
//  RMCloudExpandedCell.h
//  XXTExplorer
//
//  Created by Zheng on 15/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const RMCloudExpandedCellReuseIdentifier = @"RMCloudExpandedCellReuseIdentifier";

@interface RMCloudExpandedCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueTextLabel;

@end
