//
//  RMCloudExpandableCell.h
//  XXTExplorer
//
//  Created by Zheng on 15/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMCloudExpandable.h"

static NSString * const RMCloudExpandableCellReuseIdentifier = @"RMCloudExpandableCellReuseIdentifier";

@interface RMCloudExpandableCell : UITableViewCell <RMCloudExpandable>
@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *expandButton;
@property (weak, nonatomic) IBOutlet UIView *topSepatator;
@property (weak, nonatomic) IBOutlet UIView *bottomSepatator;

@end
