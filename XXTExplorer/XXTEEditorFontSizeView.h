//
//  XXTEEditorFontSizeView.h
//  XXTouchApp
//
//  Created by Zheng on 02/11/2016.
//  Copyright © 2016 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

#define MAX_FONT_SIZE 24
#define MIN_FONT_SIZE 10

@class XXTEEditorFontSizeView;

@protocol XXTEEditorFontSizeViewDelegate <NSObject>
- (void)fontViewSizeDidChanged:(XXTEEditorFontSizeView *)view;

@end

@interface XXTEEditorFontSizeView : UIView
@property (nonatomic, assign) NSUInteger fontSize;
@property (nonatomic, weak) id<XXTEEditorFontSizeViewDelegate> delegate;

@end
