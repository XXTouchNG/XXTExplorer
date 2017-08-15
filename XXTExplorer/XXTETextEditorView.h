//
//  XXTETextEditorView.h
//  XXTExplorer
//
//  Created by Zheng Wu on 11/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTETextStorage, XXTELayoutManager;

@interface XXTETextEditorView : UITextView

@property (nonatomic, assign, getter=isLineNumberEnabled) BOOL lineNumberEnabled;
@property (nonatomic, strong) UIColor *gutterBackgroundColor;
@property (nonatomic, strong) UIColor *gutterLineColor;

@property (nonatomic, strong) XXTETextStorage *vTextStorage;
@property (nonatomic, strong) XXTELayoutManager *vLayoutManager;

@end
