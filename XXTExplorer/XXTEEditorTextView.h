//
//  XXTEEditorTextView.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTEEditorTextStorage, XXTEEditorLayoutManager;

@interface XXTEEditorTextView : UITextView

@property (nonatomic, assign, getter=isLineNumberEnabled) BOOL lineNumberEnabled;
@property (nonatomic, strong) UIColor *gutterBackgroundColor;
@property (nonatomic, strong) UIColor *gutterLineColor;

@property (nonatomic, strong) XXTEEditorTextStorage *vTextStorage;
@property (nonatomic, strong) XXTEEditorLayoutManager *vLayoutManager;

@end
