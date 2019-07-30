//
//  XXTELockedTitleView.h
//  XXTExplorer
//
//  Created by Darwin on 7/31/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XXTELockedTitleView : UIView

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *lockImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lockWidth;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL locked;

@end

NS_ASSUME_NONNULL_END
