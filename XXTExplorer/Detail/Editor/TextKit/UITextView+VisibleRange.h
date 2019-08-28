//
//  UITextView+VisibleRange.h
//  XXTExplorer
//
//  Created by Darwin on 8/7/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITextView (VisibleRange)

- (NSRange)visibleRange;

@end

NS_ASSUME_NONNULL_END
