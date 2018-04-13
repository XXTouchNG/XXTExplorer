//
//  XXTEDbTableContentCell.h
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEDbTableContentCell;
@protocol XXTEDbTableContentCellDelegate <NSObject>

@optional
- (void)tableContentCell:(XXTEDbTableContentCell *)tableView labelDidTapWithText:(NSString *)text;

@end

@interface XXTEDbTableContentCell : UITableViewCell

@property (nonatomic, strong) NSArray<UILabel *> *labels;

@property (nonatomic, weak) id<XXTEDbTableContentCellDelegate> delegate;

+ (instancetype)cellWithTableView:(UITableView *)tableView columnNumber:(NSInteger)number;

@end
