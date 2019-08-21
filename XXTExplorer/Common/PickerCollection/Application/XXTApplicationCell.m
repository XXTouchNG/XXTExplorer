//
//  XXTApplicationCell.m
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTApplicationCell.h"

@interface XXTApplicationCell ()
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UILabel *bundleIDLabel;

@end

@implementation XXTApplicationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.appLabel.textColor = XXTColorPlainTitleText();
    self.bundleIDLabel.textColor = XXTColorForeground();
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
    self.appLabel.text = name;
}

- (void)setApplicationBundleID:(NSString *)bundleID {
    self.bundleIDLabel.text = bundleID;
}

- (void)setApplicationIconImage:(UIImage *)image {
    self.iconImageView.image = image;
}

- (NSString *)applicationBundleID {
    return self.bundleIDLabel.text;
}

@end
