//
//  RMCloudTrendsCell.h
//  XXTExplorer
//
//  Created by Zheng on 20/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XUI/XUITextTagCollectionView.h>
#import "RMHotWord.h"

@class RMCloudTrendsCell;
@protocol RMCloudTrendsCellDelegate <NSObject>
- (void)trendsCell:(RMCloudTrendsCell *)cell didSelectHotWord:(RMHotWord *)word;
@end

@interface RMCloudTrendsCell : UITableViewCell <XUITextTagCollectionViewDelegate>
@property (weak, nonatomic) IBOutlet XUITextTagCollectionView *tagView;
@property (nonatomic, strong) NSArray <RMHotWord *> *hotWords;
@property (nonatomic, weak) id <RMCloudTrendsCellDelegate> delegate;

@end
