//
//  XXTEEditorLayoutManager.h
//  XXTExplorer
//
//  Created by Zheng Wu on 15/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEEditorLayoutManager : NSLayoutManager

@property (nonatomic, assign) BOOL showLineNumbers;
@property (nonatomic, assign) BOOL showInvisibleCharacters;
@property (nonatomic, assign) BOOL indentWrappedLines;

@property (nonatomic, strong) UIColor *invisibleColor;  // not updated
@property (nonatomic, strong) UIFont *invisibleFont;  // not updated

@property (nonatomic, strong) UIFont *lineNumberFont;
@property (nonatomic, strong) UIColor *lineNumberColor;  // not updated
@property (nonatomic, strong) UIColor *bulletColor;  // not updated
@property (nonatomic, assign) NSUInteger numberOfDigits;
@property (nonatomic, assign, readonly) CGFloat gutterWidth;

@property (nonatomic, assign) CGFloat tabWidth;
@property (nonatomic, assign) CGFloat fontLineHeight;
@property (nonatomic, assign) CGFloat lineHeightScale;
@property (nonatomic, assign) CGFloat baseLineOffset;

@property (nonatomic, assign, readonly) UIEdgeInsets lineAreaInset;
@property (nonatomic, assign, readonly) CGFloat fontPointSize;

//- (UIEdgeInsets)insetsForLineStartingAtCharacterIndex:(NSUInteger)characterIndex;
- (UIEdgeInsets)insetsForLineStartingAtCharacterIndex:(NSUInteger)characterIndex textContainer:(NSTextContainer *)container;

@end
