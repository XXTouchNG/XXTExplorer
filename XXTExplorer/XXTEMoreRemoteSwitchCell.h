//
//  XXTEMoreRemoteSwitchCell.h
//  XXTExplorer
//
//  Created by Zheng on 28/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const XXTEMoreRemoteSwitchCellReuseIdentifier = @"XXTEMoreRemoteSwitchCellReuseIdentifier";

@interface XXTEMoreRemoteSwitchCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *optionSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *optionIndicator;

@end
