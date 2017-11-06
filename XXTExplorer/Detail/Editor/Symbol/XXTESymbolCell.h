//
//  XXTESymbolCell.h
//  XXTExplorer
//
//  Created by Zheng on 06/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const XXTESymbolCellReuseIdentifier;

@interface XXTESymbolCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *typeLabel;
@property (nonatomic, strong) IBOutlet UILabel *symbolLabel;
@property (nonatomic, strong) IBOutlet UIView *typeBackgroundView;

@end
