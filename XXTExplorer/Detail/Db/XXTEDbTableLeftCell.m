//
//  XXTEDbTableLeftCell.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEDbTableLeftCell.h"

@implementation XXTEDbTableLeftCell

+ (instancetype)cellWithTableView:(UITableView *)tableView
{
    static NSString *identifier = @"XXTEDbTableLeftCell";
    XXTEDbTableLeftCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[XXTEDbTableLeftCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        UILabel *textLabel               = [[UILabel alloc] initWithFrame:CGRectZero];
        textLabel.textAlignment          = NSTextAlignmentCenter;
        textLabel.font                   = [UIFont systemFontOfSize:13.0];
        textLabel.backgroundColor        = [UIColor clearColor];
        textLabel.textColor              = XXTColorPlainTitleText();
        [cell.contentView addSubview:textLabel];
        cell.titlelabel = textLabel;
    }
    return cell;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.titlelabel.frame = self.contentView.frame;
}
@end
