//
//  XXTEMoreValueView.h
//  XXTouchApp
//
//  Created by Zheng on 02/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEMoreValueView;

@protocol XXTEMoreValueViewDelegate <NSObject>
- (void)valueViewValueDidChanged:(XXTEMoreValueView *)view;

@end

@interface XXTEMoreValueView : UIView

@property (nonatomic, assign) CGFloat value;
@property (nonatomic, assign) CGFloat maxValue;
@property (nonatomic, assign) CGFloat minValue;
@property (nonatomic, assign) CGFloat stepValue;

@property (nonatomic, assign) BOOL isInteger;
@property (nonatomic, copy) NSString *unitString;
@property (nonatomic, weak) id<XXTEMoreValueViewDelegate> delegate;

@end
