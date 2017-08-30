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
    
//    self.iconImageView.layer.cornerRadius = 6.f;
//    self.iconImageView.layer.masksToBounds = YES;
//    self.iconImageView.layer.shouldRasterize = YES;
//    self.iconImageView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
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