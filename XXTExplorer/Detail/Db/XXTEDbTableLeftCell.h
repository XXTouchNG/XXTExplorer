//
//  XXTEDbTableLeftCell.h
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEDbTableLeftCell : UITableViewCell

@property (nonatomic, strong) UILabel *titlelabel;

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end
