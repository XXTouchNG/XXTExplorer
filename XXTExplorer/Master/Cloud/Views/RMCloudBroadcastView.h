//
//  RMCloudBroadcastView.h
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/11.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMCloudBroadcastView;

@protocol RMCloudBroadcastViewDelegate <NSObject>
- (void)broadcastViewDidTapped:(RMCloudBroadcastView *)view;
@end

@interface RMCloudBroadcastView : UIView

@property (nonatomic, weak) id <RMCloudBroadcastViewDelegate> delegate;
- (void)reloadScrollViewWithText:(NSString *)text;

@end
