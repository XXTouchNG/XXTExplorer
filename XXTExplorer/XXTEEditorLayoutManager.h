//
//  XXTEEditorLayoutManager.h
//  XXTExplorer
//
//  Created by Zheng Wu on 15/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEEditorLayoutManager : NSLayoutManager

@property (nonatomic, strong) UIFont *lineNumberFont;
@property (nonatomic, strong) UIColor *lineNumberColor;
@property (nonatomic, assign, readonly) CGFloat gutterWidth;

@end
