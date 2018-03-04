//
//  XXTEMoreTitleValueCell.h
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEAutoLabel.h"

static NSString * const XXTEMoreTitleValueCellReuseIdentifier = @"XXTEMoreTitleValueCellReuseIdentifier";

@interface XXTEMoreTitleValueCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet XXTEAutoLabel *valueLabel;

@end
