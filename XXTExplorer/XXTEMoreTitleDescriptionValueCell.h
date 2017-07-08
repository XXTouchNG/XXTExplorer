//
//  XXTEMoreTitleDescriptionValueCell.h
//  XXTExplorer
//
//  Created by Zheng on 08/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const XXTEMoreTitleDescriptionValueCellReuseIdentifier = @"XXTEMoreTitleDescriptionValueCellReuseIdentifier";

@interface XXTEMoreTitleDescriptionValueCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end
