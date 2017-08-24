//
//  XXTEEditorController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditor.h"
#import "XXTExplorerItemPicker.h"

@class SKHelper, SKAttributedParser, XXTEEditorTextView, XXTEEditorTheme;

@interface XXTEEditorController : UIViewController <XXTEEditor, XXTExplorerItemPickerDelegate>

@property (nonatomic, strong, readonly) SKHelper *helper;
@property (nonatomic, strong, readonly) SKAttributedParser *parser;

@property (nonatomic, strong) XXTEEditorTextView *textView;
@property (nonatomic, strong) XXTEEditorTheme *theme;

@property (nonatomic, assign) CGFloat tabWidthValue;

- (void)setNeedsReload;
- (void)setNeedsRefresh;
- (void)setNeedsFocusTextView;

- (void)renderNavigationBarTheme:(BOOL)restore;
- (void)reloadViewConstraints;

- (void)saveDocumentIfNecessary;
- (void)setNeedsSaveDocument;

@end
