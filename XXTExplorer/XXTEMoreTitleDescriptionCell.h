//
//  XXTEMoreTitleDescriptionCell.h
//  XXTExplorer
//
//  Created by Zheng Wu on 06/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const XXTEMoreTitleDescriptionCellReuseIdentifier = @"XXTEMoreTitleDescriptionCellReuseIdentifier";

@interface XXTEMoreTitleDescriptionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
