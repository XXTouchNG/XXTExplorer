//
//  XXTEEditorMaskView.h
//  XXTExplorer
//
//  Created by Zheng on 2017/11/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEEditorLineMask.h"


@class XXTEEditorTextView;

@interface XXTEEditorMaskView : UIView

- (instancetype)initWithTextView:(XXTEEditorTextView *)textView;

@property (nonatomic, weak, readonly) XXTEEditorTextView *textView;
@property (nonatomic, strong) UIColor *focusColor;
@property (nonatomic, strong) UIColor *flashColor;

- (void)focusRange:(NSRange)range;
- (void)flashRange:(NSRange)range;


#pragma mark - Line Mask

- (void)fillAllLineMasks;
- (void)eraseAllLineMasks;
- (void)scrollToLineMask:(XXTEEditorLineMask *)mask animated:(BOOL)animated;

- (UIColor *)lineMaskColorForType:(XXTEEditorLineMaskType)type;
- (void)setLineMaskColor:(UIColor *)color forType:(XXTEEditorLineMaskType)type;

- (NSArray <XXTEEditorLineMask *> *)allLineMasks;
- (NSArray <XXTEEditorLineMask *> *)lineMasksForType:(XXTEEditorLineMaskType)type;
- (XXTEEditorLineMask *)lineMaskAtIndex:(NSUInteger)idx;
- (NSArray <XXTEEditorLineMask *> *)lineMasksInSet:(NSIndexSet *)maskSet;

- (BOOL)addLineMask:(XXTEEditorLineMask *)mask;
- (BOOL)addLineMasks:(NSArray <XXTEEditorLineMask *> *)masks;

- (void)removeLineMask:(XXTEEditorLineMask *)mask;
- (void)removeLineMasks:(NSArray <XXTEEditorLineMask *> *)masks;
- (void)removeLineMaskAtIndex:(NSUInteger)idx;
- (void)removeLineMasksInSet:(NSIndexSet *)maskSet;
- (void)removeLineMasksForType:(XXTEEditorLineMaskType)type;
- (void)removeAllLineMasks;

- (void)clearAllLineMasks;

@end
