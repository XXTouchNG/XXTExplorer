//
//  XXTELogCell.h
//  XXTExplorer
//
//  Created by Zheng on 2018/4/14.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const XXTELogCellReuseIdentifier = @"XXTELogCellReuseIdentifier";

@interface XXTELogCell : UITableViewCell
@property (nonatomic, copy) NSString *logText;

@end
