//
//  ICTextHighlight.h
//  XXTExplorer
//
//  Created by Darwin on 8/22/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ICTextHighlight : NSObject
@property (nonatomic, strong) UIView *highlightView;
@property (nonatomic, strong) UITextRange *highlightRange;

@end

NS_ASSUME_NONNULL_END
