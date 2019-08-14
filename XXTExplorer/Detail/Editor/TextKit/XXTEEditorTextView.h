//
//  XXTEEditorTextView.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICTextView.h"

@class XXTEEditorTextStorage, XXTEEditorLayoutManager, XXTEEditorTypeSetter, XXTEEditorTextInput;

@interface XXTEEditorTextView : ICTextView

@property (nonatomic, assign) BOOL showLineNumbers;
@property (nonatomic, strong) UIColor *gutterBackgroundColor;
@property (nonatomic, strong) UIColor *gutterLineColor;

@property (nonatomic, assign, readonly) BOOL showLineHighlight;
@property (nonatomic, assign, readonly) NSRange lineHighlightRange;
- (void)setShowLineHighlight:(BOOL)highlight lineRange:(NSRange)range;

@property (nonatomic, assign, readonly) BOOL needsUpdateLineHighlight;
- (void)setNeedsUpdateLineHighlight;
@property (nonatomic, assign) CGRect lineHighlightRect;

@property (nonatomic, strong) XXTEEditorTextStorage *vTextStorage;
@property (nonatomic, strong) XXTEEditorLayoutManager *vLayoutManager;
@property (nonatomic, strong) XXTEEditorTypeSetter *vTypeSetter;
@property (nonatomic, strong) XXTEEditorTextInput *vTextInput;

@property (nonatomic, assign, readonly) UIEdgeInsets xxteTextContainerInset;

@end
