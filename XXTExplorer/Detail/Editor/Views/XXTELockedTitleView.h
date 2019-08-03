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

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) BOOL simple;

@end

NS_ASSUME_NONNULL_END
