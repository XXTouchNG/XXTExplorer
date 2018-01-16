//
//  RMCloudProjectCell.h
//  XXTExplorer
//
//  Created by Zheng on 13/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMProject.h"
#import <YYImage/YYImage.h>

static NSString * const RMCloudProjectCellReuseIdentifier = @"RMCloudProjectCellReuseIdentifier";

@class RMCloudProjectCell;

@protocol RMCloudProjectCellDelegate <NSObject>

- (void)projectCell:(RMCloudProjectCell *)cell downloadButtonTapped:(UIButton *)button;

@end

@interface RMCloudProjectCell : UITableViewCell

@property (nonatomic, strong) RMProject *project;
@property (weak, nonatomic) IBOutlet UILabel *titleTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet YYAnimatedImageView *iconImageView;

@property (weak, nonatomic) id <RMCloudProjectCellDelegate> delegate;

@end
