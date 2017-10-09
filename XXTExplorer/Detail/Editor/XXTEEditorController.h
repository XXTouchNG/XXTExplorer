//
//  XXTEEditorController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditor.h"

@class SKAttributedParser, XXTEEditorTextView, XXTEEditorTheme, XXTEEditorLanguage, XXTPickerFactory;

@interface XXTEEditorController : UIViewController <XXTEEditor>

@property (nonatomic, strong) XXTEEditorTheme *theme;
@property (nonatomic, strong) XXTEEditorLanguage *language;
@property (nonatomic, strong) XXTEEditorTextView *textView;

- (void)setNeedsReload;
- (void)setNeedsSaveDocument;
- (void)setNeedsFocusTextView;

- (void)reloadConstraints;

- (void)invalidateSyntaxCaches;
- (void)saveDocumentIfNecessary;

@end