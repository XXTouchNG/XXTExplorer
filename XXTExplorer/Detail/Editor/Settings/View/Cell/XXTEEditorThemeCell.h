//
//  XXTEEditorThemeCell.h
//  XXTExplorer
//
//  Created by Zheng on 21/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const XXTEEditorThemeCellReuseIdentifier = @"XXTEEditorThemeCellReuseIdentifier";
static CGFloat const XXTEEditorThemeCellHeight = 160.0;

@interface XXTEEditorThemeCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UIImageView *selectFlagView;

@end
