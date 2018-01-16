//
//  RMCloudProjectDescriptionCell.m
//  XXTExplorer
//
//  Created by Zheng on 14/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudProjectDescriptionCell.h"

@interface RMCloudProjectDescriptionCell ()

@end

@implementation RMCloudProjectDescriptionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.descriptionTextLabel.text = @"";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Setters

- (void)setProject:(RMProject *)project {
    _project = project;
    if (project.projectRemark.length > 0) {
        self.descriptionTextLabel.text = project.projectRemark;
    } else {
        self.descriptionTextLabel.text = NSLocalizedString(@"No description.", nil);
    }
}

@end
