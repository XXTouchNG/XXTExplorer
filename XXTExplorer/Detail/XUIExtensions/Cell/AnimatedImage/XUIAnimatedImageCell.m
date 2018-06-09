//
//  XUIAnimatedImageCell.m
//  XXTExplorer
//
//  Created by Zheng Wu on 13/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIAnimatedImageCell.h"
#import <YYWebImage/YYWebImage.h>

@interface XUIAnimatedImageCell ()

@property (weak, nonatomic) IBOutlet YYAnimatedImageView *cellImageView;

@end

@implementation XUIAnimatedImageCell

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

- (void)setupCell {
    [super setupCell];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setXui_path:(NSString *)xui_path {
    _xui_path = xui_path;
    NSURL *imageURL = [NSURL URLWithString:xui_path];
    NSString *urlScheme = [imageURL scheme];
    if (urlScheme.length > 0) {
        UIImageView *imageView = self.cellImageView;
        [imageView yy_setImageWithURL:imageURL options:(YYWebImageOptionShowNetworkActivity | YYWebImageOptionProgressive)];
    } else {
        NSString *imagePath = [self.adapter.bundle pathForResource:xui_path ofType:nil];
        YYImage *image = [YYImage imageWithContentsOfFile:imagePath];
        [self.cellImageView setImage:image];
    }
}

@end
