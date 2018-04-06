//
//  XXTEMoreValueViewCell.h
//  XXTExplorer
//
//  Created by Zheng Wu on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEMoreValueView;

@interface XXTEMoreValueViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet XXTEMoreValueView *valueView;
@property (nonatomic, assign) CGFloat valueViewWidth;

@end
