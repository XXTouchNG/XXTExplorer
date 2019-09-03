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
@property (nonatomic, strong, readonly) XXTEEditorTheme *theme;
@property (nonatomic, strong, readonly) XXTEEditorLanguage *language;


// text properties
@property (nonatomic, assign, getter=isLockedState, readonly) BOOL lockedState;
@property (nonatomic, assign, readwrite) BOOL hasLongLine;
@property (nonatomic, assign, readwrite) CFStringEncoding currentEncoding;
@property (nonatomic, assign, readwrite) NSStringLineBreakType currentLineBreak;


// keyboard properties
@property (nonatomic, assign, readwrite) CGRect keyboardFrame;


// public views
@property (nonatomic, strong, readonly) XXTEEditorTextView *textView;
@property (nonatomic, strong, readonly) XXTEEditorMaskView *maskView;
@property (nonatomic, strong, readonly) XXTEEditorToolbar *toolbar;


- (void)setNeedsReload:(NSString *)defaultKey;
- (void)setNeedsReloadAll;
- (void)setNeedsReloadAttributes;  // called from keyboard events
- (void)setNeedsSaveDocument;  // called from keyboard events

- (void)setNeedsFocusTextView;  // called from menu
- (void)setNeedsHighlightRange:(NSRange)range;  // called from symbol controller

- (void)preloadIfNecessary;
- (void)reloadAttributesIfNecessary;  // called from states
- (void)saveDocumentIfNecessary;  // called from keyboard events
- (void)focusTextViewIfNecessary;  // called from picker collection

#pragma mark - Search

- (void)toggleSearchBar:(UIBarButtonItem *)sender animated:(BOOL)animated;
@property (nonatomic, assign, getter=isSearchMode, readonly) BOOL searchMode;

#pragma mark - Rename

- (void)setRenamedEntryPath:(NSString *)entryPath;

@end
