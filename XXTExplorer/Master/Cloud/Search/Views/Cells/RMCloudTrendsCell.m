//
//  RMCloudTrendsCell.m
//  XXTExplorer
//
//  Created by Zheng on 20/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudTrendsCell.h"

@implementation RMCloudTrendsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = XXTColorPlainBackground();
    self.tintColor = XXTColorForeground();
    
    self.tagView.scrollView.scrollEnabled = NO;
    self.tagView.contentInset = UIEdgeInsetsZero;
    self.tagView.scrollDirection = XUITagCollectionScrollDirectionVertical;
    
    self.tagView.defaultConfig.tagCornerRadius = 4.f;
    self.tagView.defaultConfig.tagSelectedCornerRadius = 4.f;
    
    self.tagView.defaultConfig.tagShadowColor = UIColor.clearColor;
    
    self.tagView.defaultConfig.tagBorderColor = UIColor.clearColor;
    self.tagView.defaultConfig.tagSelectedBorderColor = UIColor.clearColor;
    
    self.tagView.defaultConfig.tagBorderWidth = 1.f;
    self.tagView.defaultConfig.tagSelectedBorderWidth = 1.f;
    
    self.tagView.defaultConfig.tagTextFont = [UIFont systemFontOfSize:14.0];
    
    // Alignment
    self.tagView.alignment = XUITagCollectionAlignmentLeft;
    
    // Use manual calculate height
    self.tagView.delegate = self;
    self.tagView.manualCalculateHeight = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tagView.preferredMaxLayoutWidth = CGRectGetWidth(self.frame) - 32.f;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(CGRectGetWidth(self.bounds), self.tagView.intrinsicContentSize.height + 44.f + 1.f);
}

#pragma mark - Setters

- (void)setHotWords:(NSArray<RMHotWord *> *)hotWords {
    _hotWords = hotWords;
    NSMutableArray <NSString *> *validTitles = [[NSMutableArray alloc] init];
    [hotWords enumerateObjectsUsingBlock:^(RMHotWord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [validTitles addObject:obj.word];
    }];
    [self.tagView removeAllTags];
    [self.tagView addTags:validTitles];
    [self.tagView reload];
}

#pragma mark - XUITextTagCollectionViewDelegate

- (void)textTagCollectionView:(XUITextTagCollectionView *)textTagCollectionView
                    didTapTag:(NSString *)tagText
                      atIndex:(NSUInteger)index
                     selected:(BOOL)selected
{
    [textTagCollectionView setTagAtIndex:index selected:NO];
    if (index < self.hotWords.count) {
        RMHotWord *word = self.hotWords[index];
        if ([_delegate respondsToSelector:@selector(trendsCell:didSelectHotWord:)]) {
            [_delegate trendsCell:self didSelectHotWord:word];
        }
    }
}

@end
