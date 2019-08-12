//
//  XXTEDbTableContentCell.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEDbTableContentCell.h"
#import "XXTEMultiColumnTableView.h"

@interface XXTEDbTableContentCell ()

@end

@implementation XXTEDbTableContentCell

+ (instancetype)cellWithTableView:(UITableView *)tableView columnNumber:(NSInteger)number;
{
    static NSString *identifier = @"XXTEDbTableContentCell";
    XXTEDbTableContentCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[XXTEDbTableContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        NSMutableArray<UILabel *> *labels = [NSMutableArray array];
        for (int i = 0; i < number ; i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            if (@available(iOS 13.0, *)) {
                label.backgroundColor = [UIColor systemBackgroundColor];
            } else {
                label.backgroundColor = [UIColor whiteColor];
            }
            label.font            = [UIFont systemFontOfSize:13.0];
            label.textAlignment   = NSTextAlignmentLeft;
            // label.backgroundColor = [UIColor greenColor];
            [labels addObject:label];
            
            UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:cell
                                                                                      action:@selector(labelDidTap:)];
            [label addGestureRecognizer:gesture];
            label.userInteractionEnabled = YES;
            
            [cell.contentView addSubview:label];
            if (@available(iOS 13.0, *)) {
                cell.contentView.backgroundColor = [UIColor systemBackgroundColor];
            } else {
                cell.contentView.backgroundColor = [UIColor whiteColor];
            }
        }
        cell.labels = labels;
    }
    return cell;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat labelWidth  = self.contentView.frame.size.width / self.labels.count;
    CGFloat labelHeight = self.contentView.frame.size.height;
    for (int i = 0; i < self.labels.count; i++) {
        UILabel *label = self.labels[i];
        label.frame = CGRectMake(labelWidth * i + 5, 0, (labelWidth - 10), labelHeight);
    }
}


- (void)labelDidTap:(UIGestureRecognizer *)gesture
{
    UILabel *label = (UILabel *)gesture.view;
    if ([self.delegate respondsToSelector:@selector(tableContentCell:labelDidTapWithText:)]) {
        [self.delegate tableContentCell:self labelDidTapWithText:label.text];
    }
}

@end
