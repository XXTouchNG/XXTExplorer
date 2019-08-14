//
//  XXTEEditorController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditor.h"
#import "XXTEEditorTextProperties.h"
#import "XXTETerminalDelegate.h"


@class SKAttributedParser, XXTEEditorTextView, XXTEEditorToolbar, XXTEEditorTheme, XXTEEditorLanguage, XXTPickerFactory, XXTEEditorMaskView;

@interface XXTEEditorController : UIViewController <XXTEEditor, XXTETerminalViewControllerDelegate, UIPopoverPresentationControllerDelegate>


// syntax properties
@property (nonatomic, strong) XXTEEditorTheme *theme;
@property (nonatomic, strong) XXTEEditorLanguage *language;


// text properties
@property (nonatomic, assign, getter=isLockedState) BOOL lockedState;
@property (nonatomic, assign) BOOL hasLongLine;
@property (nonatomic, assign) CFStringEncoding currentEncoding;
@property (nonatomic, assign) NSStringLineBreakType currentLineBreak;


// public views
@property (nonatomic, strong) XXTEEditorTextView *textView;
@property (nonatomic, strong) XXTEEditorMaskView *maskView;
@property (nonatomic, strong) XXTEEditorToolbar *toolbar;


- (void)setNeedsReload;
- (void)setNeedsSoftReload;
- (void)setNeedsReloadAttributes;
- (void)setNeedsSaveDocument;
- (void)setNeedsFocusTextView;
- (void)setNeedsHighlightRange:(NSRange)range;

- (void)reloadAttributesIfNecessary;
- (BOOL)invalidateSyntaxCachesIfNeeded;
- (void)saveDocumentIfNecessary;

#pragma mark - Search

- (void)toggleSearchBar:(UIBarButtonItem *)sender animated:(BOOL)animated;
@property (nonatomic, assign, getter=isSearchMode) BOOL searchMode;

@end
