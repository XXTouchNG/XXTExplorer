//
//  RMCloudProjectDescriptionCell.h
//  XXTExplorer
//
//  Created by Zheng on 14/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMProject.h"

static NSString * const RMCloudProjectDescriptionCellReuseIdentifier = @"RMCloudProjectDescriptionCellReuseIdentifier";

@interface RMCloudProjectDescriptionCell : UITableViewCell
@property (nonatomic, strong) RMProject *project;
@property (weak, nonatomic) IBOutlet UILabel *descriptionTextLabel;

@end
