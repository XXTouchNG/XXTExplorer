//
//  XXTEEditorController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditor.h"

@class SKAttributedParser, XXTEEditorTextView, XXTEEditorToolbar, XXTEEditorTheme, XXTEEditorLanguage, XXTPickerFactory;

@interface XXTEEditorController : UIViewController <XXTEEditor>

@property (nonatomic, strong) XXTEEditorTheme *theme;
@property (nonatomic, strong) XXTEEditorLanguage *language;

@property (nonatomic, strong) XXTEEditorTextView *textView;
@property (nonatomic, strong) XXTEEditorToolbar *toolbar;

- (void)setNeedsReload;
- (void)setNeedsReloadAttributes;
- (void)setNeedsSaveDocument;
- (void)setNeedsFocusTextView;

- (void)reloadConstraints;
- (void)reloadAttributesIfNecessary;

- (void)invalidateSyntaxCaches;
- (void)saveDocumentIfNecessary;

@end
