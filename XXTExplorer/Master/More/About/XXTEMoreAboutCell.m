//
//  XXTEMoreAboutCell.m
//  XXTExplorer
//
//  Created by Zheng on 03/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreAboutCell.h"
#import "XXTEAppDefines.h"

@interface XXTEMoreAboutCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

@implementation XXTEMoreAboutCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.titleLabel.text = [NSString stringWithFormat:@"%@\nv%@", uAppDefine(@"PRODUCT_NAME"), uAppDefine(@"DAEMON_VERSION")];
    self.subtitleLabel.text = [NSString stringWithFormat:@"%@\n%@", uAppDefine(@"OFFICIAL_SITE"), uAppDefine(@"COPYRIGHT_STRING")];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
