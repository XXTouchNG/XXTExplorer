//
//  XXTEEditorMaskView.h
//  XXTExplorer
//
//  Created by Zheng on 2017/11/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEEditorMaskView : UIView

- (instancetype)initWithTextView:(UITextView *)textView;

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIColor *maskColor;

- (void)highlightWithRange:(NSRange)range;
- (void)highlightWithRange:(NSRange)range duration:(NSTimeInterval)duration;

@end
