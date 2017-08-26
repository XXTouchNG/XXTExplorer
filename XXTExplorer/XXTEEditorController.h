//
//  XXTEEditorController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditor.h"

@class SKHelper, SKAttributedParser, XXTEEditorTextView, XXTEEditorTheme, XXTPickerFactory;

@interface XXTEEditorController : UIViewController <XXTEEditor>

@property (nonatomic, strong, readonly) SKHelper *helper;
@property (nonatomic, strong, readonly) SKAttributedParser *parser;

@property (nonatomic, strong) XXTEEditorTextView *textView;
@property (nonatomic, strong) XXTEEditorTheme *theme;

@property (nonatomic, assign) CGFloat tabWidthValue;

@property (nonatomic, strong) XXTPickerFactory *pickerFactory;

- (void)setNeedsReload;
- (void)setNeedsRefresh;
- (void)setNeedsFocusTextView;

- (void)renderNavigationBarTheme:(BOOL)restore;
- (void)reloadViewConstraints;

- (void)saveDocumentIfNecessary;
- (void)setNeedsSaveDocument;

@end
