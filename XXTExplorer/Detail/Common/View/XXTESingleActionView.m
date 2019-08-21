//
//  XXTESingleActionView.m
//  XXTExplorer
//
//  Created by Zheng on 18/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTESingleActionView.h"

@implementation XXTESingleActionView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.titleLabel.textColor = XXTColorPlainTitleText();
    self.descriptionLabel.textColor = XXTColorPlainSubtitleText();
    self.tintColor = XXTColorForeground();
}

@end
