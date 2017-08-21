//
//  XXTEEditorController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditor.h"

@class XXTEEditorTextView, XXTEEditorTheme;

@interface XXTEEditorController : UIViewController <XXTEEditor>

@property (nonatomic, strong) XXTEEditorTextView *textView;
@property (nonatomic, strong) XXTEEditorTheme *theme;
@property (nonatomic, assign) CGFloat tabWidthValue;
- (void)renderNavigationBarTheme:(BOOL)restore;
- (void)reloadViewStyle;
- (void)reloadViewConstraints;

@end
