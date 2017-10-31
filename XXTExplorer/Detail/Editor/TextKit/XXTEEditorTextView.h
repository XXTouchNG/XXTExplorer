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

@property (nonatomic, strong) XXTEEditorTextStorage *vTextStorage;
@property (nonatomic, strong) XXTEEditorLayoutManager *vLayoutManager;
@property (nonatomic, strong) XXTEEditorTypeSetter *vTypeSetter;
@property (nonatomic, strong) XXTEEditorTextInput *vTextInput;

@end
