//
//  XUIImageCell.m
//  XXTExplorer
//
//  Created by Zheng on 30/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIImageCell.h"

@interface XUIImageCell ()

@property (weak, nonatomic) IBOutlet UIImageView *xui_imageView;

@end

@implementation XUIImageCell

+ (BOOL)xibBasedLayout {
    return YES;
}

+ (BOOL)layoutNeedsTextLabel {
    return NO;
}

+ (BOOL)layoutNeedsImageView {
    return NO;
}

+ (BOOL)layoutRequiresDynamicRowHeight {
    return NO;
}

+ (NSDictionary <NSString *, Class> *)entryValueTypes {
    return
    @{
      @"path": [NSString class]
      };
}

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    BOOL superResult = [super checkEntry:cellEntry withError:error];
    return superResult;
}

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setXui_path:(NSString *)xui_path {
    _xui_path = xui_path;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_8) {
        UIImage *image = [UIImage imageNamed:xui_path inBundle:self.bundle compatibleWithTraitCollection:nil];
        self.xui_imageView.image = image;
    } else {
        NSString *imagePath = [self.bundle pathForResource:xui_path ofType:nil];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        self.xui_imageView.image = image;
    }
    XXTE_END_IGNORE_PARTIAL
}

@end
