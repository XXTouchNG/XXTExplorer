//
//  XUISegmentCell.m
//  XXTExplorer
//
//  Created by Zheng on 30/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUISegmentCell.h"

@interface XUISegmentCell ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *xui_segmentControl;

@end

@implementation XUISegmentCell

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

+ (BOOL)checkEntry:(NSDictionary *)cellEntry withError:(NSError **)error {
    return YES;
}

- (void)setupCell {
    [super setupCell];
}

- (void)setXui_validTitles:(NSArray <NSString *> *)xui_validTitles {
    _xui_validTitles = xui_validTitles;
    [self.xui_segmentControl removeAllSegments];
    NSUInteger titleIdx = 0;
    for (NSString *validTitle in xui_validTitles) {
        [self.xui_segmentControl insertSegmentWithTitle:validTitle atIndex:titleIdx animated:NO];
        titleIdx++;
    }
    if (self.xui_value) {
        NSInteger selectedIdx = [self.xui_value integerValue];
        [self.xui_segmentControl setSelectedSegmentIndex:selectedIdx];
    }
}

- (void)setXui_value:(id)xui_value {
    [super setXui_value:xui_value];
    NSInteger selectedIdx = [xui_value integerValue];
    if (self.xui_segmentControl.numberOfSegments > selectedIdx) {
        [self.xui_segmentControl setSelectedSegmentIndex:selectedIdx];
    }
}

@end
