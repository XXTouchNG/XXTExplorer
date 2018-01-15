//
//  RMCloudProjectCell.h
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMProject.h"

static NSString * const RMCloudProjectCellReuseIdentifier = @"RMCloudProjectCellReuseIdentifier";

@interface RMCloudProjectCell : UITableViewCell

@property (nonatomic, strong) RMProject *project;

@end
