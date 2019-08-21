//
//  XXTEMoreApplicationCell.m
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreApplicationCell.h"

@interface XXTEMoreApplicationCell ()
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *applicationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *applicationBundleIDLabel;

@end

@implementation XXTEMoreApplicationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.applicationNameLabel.textColor = XXTColorPlainTitleText();
    self.applicationBundleIDLabel.textColor = XXTColorForeground();
    self.backgroundColor = XXTColorPlainBackground();
    self.tintColor = XXTColorForeground();
    
    UIView *selectionBackground = [[UIView alloc] init];
    selectionBackground.backgroundColor = XXTColorCellSelected();
    self.selectedBackgroundView = selectionBackground;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setApplicationName:(NSString *)name {
    self.applicationNameLabel.text = name;
}

- (void)setApplicationBundleID:(NSString *)bundleID {
    self.applicationBundleIDLabel.text = bundleID;
}

- (void)setApplicationIconImage:(UIImage *)image {
    self.iconImageView.image = image;
}

- (NSString *)applicationBundleID {
    return self.applicationBundleIDLabel.text;
}

@end
