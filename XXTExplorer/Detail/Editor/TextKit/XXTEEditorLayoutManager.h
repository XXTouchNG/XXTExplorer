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

@property (nonatomic, strong) UIColor *invisibleColor;
@property (nonatomic, strong) UIFont *invisibleFont;

@property (nonatomic, strong) UIFont *lineNumberFont;
@property (nonatomic, strong) UIColor *lineNumberColor;
@property (nonatomic, strong) UIColor *bulletColor;
@property (nonatomic, assign) NSUInteger numberOfDigits;
@property (nonatomic, assign, readonly) CGFloat gutterWidth;

@property (nonatomic, assign) CGFloat tabWidth;
@property (nonatomic, assign) CGFloat fontLineHeight;
@property (nonatomic, assign) CGFloat lineHeightScale;
@property (nonatomic, assign) CGFloat baseLineOffset;

@property (nonatomic, assign, readonly) UIEdgeInsets lineAreaInset;
@property (nonatomic, assign, readonly) CGFloat fontPointSize;

- (void)invalidateLayout;  // you must call this method manually
- (UIEdgeInsets)insetsForLineStartingAtCharacterIndex:(NSUInteger)characterIndex lineFragmentRect:(CGRect)fragmentRect;

@end
