//
//  XXTEMoreLicenseCell.m
//  XXTExplorer
//
//  Created by Zheng on 01/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreLicenseCell.h"

@implementation XXTEMoreLicenseCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.licenseField.textColor = XXTColorDefault();
    self.licenseField.tintColor = XXTColorDefault();
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
