//
//  XXTEEditorController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController.h"
#import "XXTECodeViewerController.h"

// Pre-Defines
#import "XXTEAppDefines.h"
#import "XXTEEditorDefaults.h"
#import "XXTEDispatchDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENotificationCenterDefines.h"

// Theme & Language
#import "XXTEEditorTheme.h"
#import "XXTEEditorLanguage.h"

// TextKit
#import "XXTEEditorTextView.h"
#import "XXTEEditorTextStorage.h"
#import "XXTEEditorLayoutManager.h"
#import "XXTEEditorTypeSetter.h"
#import "XXTEEditorTextInput.h"
#import "XXTEEditorPreprocessor.h"

// SyntaxKit
#import "SKAttributedParser.h"
#import "SKRange.h"

// Keyboard
#import "XXTEKeyboardRow.h"
#import "UINavigationController+XXTEFullscreenPopGesture.h"

// Extensions
#import "XXTEEditorController+State.h"
#import "XXTEEditorController+Keyboard.h"
#import "XXTEEditorController+Settings.h"
#import "XXTEEditorController+Menu.h"
#import "XXTEEditorController+NavigationBar.h"

// Toolbar
#import "XXTEEditorToolbar.h"

static NSUInteger const kXXTEEditorCachedRangeLength = 10000;

@interface XXTEEditorController () <UIScrollViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *statusBarConstraints;

@property (nonatomic, strong) UIView *fakeStatusBar;
@property (nonatomic, strong) XXTEKeyboardRow *keyboardRow;

@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;

@property (nonatomic, strong) UIBarButtonItem *searchButtonItem;
@property (nonatomic, strong) UIBarButtonItem *symbolsButtonItem;
@property (nonatomic, strong) UIBarButtonItem *statisticsButtonItem;
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;

@property (nonatomic, strong, readonly) SKAttributedParser *parser;
@property (nonatomic, assign) BOOL isRendering;
@property (atomic, strong) NSMutableIndexSet *renderedSet;
@property (atomic, strong) NSMutableArray <NSValue *> *rangesArray;
@property (atomic, strong) NSMutableArray <NSDictionary *> *attributesArray;

@property (nonatomic, assign) BOOL shouldSaveDocument;
@property (nonatomic, assign) BOOL shouldReloadAttributes;
@property (nonatomic, assign) BOOL shouldFocusTextView;
@property (nonatomic, assign) BOOL shouldRefreshNagivationBar;
@property (nonatomic, assign) BOOL shouldReloadAll;

@end

@implementation XXTEEditorController

@synthesize entryPath = _entryPath;

#pragma mark - Editor

+ (NSString *)editorName {
    return NSLocalizedString(@"Text Editor", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return [XXTECodeViewerController suggestedExtensions];
}

#pragma mark - Initializers

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        _rangesArray = [[NSMutableArray alloc] init];
        _attributesArray = [[NSMutableArray alloc] init];
        _renderedSet = [[NSMutableIndexSet alloc] init];
        [self setup];
    }
    return self;
}

- (void)setup {
    self.hidesBottomBarWhenPushed = YES;
}

- (void)reloadAll {
    [self prepareForView];
    [self reloadConstraints];
    [self reloadTextView];
    [self reloadContent];
    [self reloadAttributes];
}

- (void)prepareForView {
    // Theme
    NSString *themeName = XXTEDefaultsObject(XXTEEditorThemeName, @"Mac Classic");
    NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, @"CourierNewPSMT");
    CGFloat fontSize = XXTEDefaultsDouble(XXTEEditorFontSize, 14.0);
    UIFont *font = [UIFont fontWithName:fontName size:fontSize]; // config
    if (themeName && fontName && font)
    {
        XXTEEditorTheme *theme = [[XXTEEditorTheme alloc] initWithName:themeName font:font];
        _theme = theme;
    }
    
    // Language
    NSString *entryExtension = [self.entryPath pathExtension];
    if (entryExtension.length > 0)
    {
        XXTEEditorLanguage *language = [[XXTEEditorLanguage alloc] initWithExtension:entryExtension];
        _language = language;
    }
    
    // Parser
    if (self.language.rawLanguage && self.theme.rawTheme)
    {
        SKAttributedParser *parser = [[SKAttributedParser alloc] initWithLanguage:self.language.rawLanguage theme:self.theme.rawTheme];
        _parser = parser;
    }
}

#pragma mark - AFTER -viewDidLoad

- (void)reloadConstraints {
    if (XXTE_PAD) {
        
    } else {
        CGRect frame = CGRectNull;
        if (NO == [self.navigationController isNavigationBarHidden]) frame = CGRectZero;
        else frame = [[UIApplication sharedApplication] statusBarFrame];
        
        {
            NSArray <NSLayoutConstraint *> *constraints =
            @[
              [NSLayoutConstraint constraintWithItem:self.fakeStatusBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0],
              [NSLayoutConstraint constraintWithItem:self.fakeStatusBar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
              [NSLayoutConstraint constraintWithItem:self.fakeStatusBar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
              [NSLayoutConstraint constraintWithItem:self.fakeStatusBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:frame.size.height],
              ];
            if (self.statusBarConstraints) {
                [self.view removeConstraints:self.statusBarConstraints];
            }
            [self.view addConstraints:constraints];
            self.statusBarConstraints = constraints;
        }
        
    }
    [self updateViewConstraints]; // TODO: back gesture will break this method :-(
}

- (void)reloadTextView {
    if (![self isViewLoaded]) return;
    
    // Config
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    BOOL isLineNumbersEnabled = XXTEDefaultsBool(XXTEEditorLineNumbersEnabled, NO); // config
    BOOL isKeyboardRowEnabled = XXTEDefaultsBool(XXTEEditorKeyboardRowEnabled, YES); // config
    BOOL showInvisibleCharacters = XXTEDefaultsBool(XXTEEditorShowInvisibleCharacters, NO); // config
    
    // Theme Appearance
    XXTEEditorTheme *theme = self.theme;
    self.view.backgroundColor = theme.backgroundColor;
    self.view.tintColor = theme.foregroundColor;
    
    // TextView
    XXTEEditorTextView *textView = self.textView;
    textView.keyboardType = UIKeyboardTypeDefault;
    textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    textView.autocapitalizationType = XXTEDefaultsEnum(XXTEEditorAutoCapitalization, UITextAutocapitalizationTypeNone);
    textView.autocorrectionType = XXTEDefaultsEnum(XXTEEditorAutoCorrection, UITextAutocorrectionTypeNo); // config
    textView.spellCheckingType = XXTEDefaultsEnum(XXTEEditorSpellChecking, UITextSpellCheckingTypeNo); // config
    textView.backgroundColor = theme.backgroundColor;
    textView.editable = !isReadOnlyMode;
    textView.tintColor = theme.caretColor;
    
    // Layout Manager
    [textView setShowLineNumbers:isLineNumbersEnabled]; // config
    if (textView.vLayoutManager) {
        [textView setGutterLineColor:theme.foregroundColor];
        [textView setGutterBackgroundColor:theme.backgroundColor];
        
        [textView.vLayoutManager setLineNumberFont:theme.font];
        [textView.vLayoutManager setLineNumberColor:theme.foregroundColor];
        
        [textView.vLayoutManager setShowInvisibleCharacters:showInvisibleCharacters];
        [textView.vLayoutManager setInvisibleColor:theme.invisibleColor];
        [textView.vLayoutManager setInvisibleFont:theme.font];
    }
    
    // Type Setter
    NSUInteger tabWidthEnum = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4); // config
    CGFloat tabWidth = tabWidthEnum * theme.tabWidth;
    textView.vTypeSetter.tabWidth = tabWidth;
    
    // Text Input
    textView.vTextInput.language = self.language;
    textView.vTextInput.autoIndent = XXTEDefaultsBool(XXTEEditorAutoIndent, YES);
    
    // Keyboard Row
    XXTEKeyboardRow *keyboardRow = self.keyboardRow;
    NSString *tabWidthString = [@"" stringByPaddingToLength:tabWidthEnum withString:@" " startingAtIndex:0];
    BOOL softTabEnabled = XXTEDefaultsBool(XXTEEditorSoftTabs, NO);
    if (softTabEnabled)
    {
        keyboardRow.tabString = tabWidthString;
        textView.vTextInput.tabWidthString = tabWidthString;
    }
    else
    {
        keyboardRow.tabString = @"\t";
        textView.vTextInput.tabWidthString = @"\t";
    }
    
    // Keyboard Appearance
    if (NO == [self isDarkMode] || XXTE_PAD)
    {
        textView.keyboardAppearance = UIKeyboardAppearanceLight;
        keyboardRow.colorStyle = XXTEKeyboardRowStyleLight;
    }
    else
    {
        textView.keyboardAppearance = UIKeyboardAppearanceDark;
        keyboardRow.colorStyle = XXTEKeyboardRowStyleDark;
    }
    if (isKeyboardRowEnabled && NO == isReadOnlyMode)
    {
        keyboardRow.textInput = textView;
        textView.inputAccessoryView = self.keyboardRow;
    }
    else
    {
        keyboardRow.textInput = nil;
        textView.inputAccessoryView = nil;
    }
    
    // Shared Menu
    if (NO == isReadOnlyMode && nil != self.language) {
        [self registerMenuActions];
    } else {
        [self dismissMenuActions];
    }
    
    // Set Render Flags
    [textView setNeedsDisplay];
    [self setNeedsRefreshNavigationBar];
    
    // Other Views
    self.toolbar.tintColor = theme.foregroundColor;
    self.toolbar.barTintColor = theme.backgroundColor;
    for (UIBarButtonItem *item in self.toolbar.items) {
        item.tintColor = theme.foregroundColor;
    }
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configure];
    
    [self prepareForView];
    [self reloadConstraints];
    [self reloadTextView];
    [self reloadContent];
    [self reloadAttributes];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
}

- (void)viewWillAppear:(BOOL)animated {
    [self registerStateNotifications];
    [self registerKeyboardNotifications];
    [self renderNavigationBarTheme:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.shouldReloadAll) {
        self.shouldReloadAll = NO;
        [self reloadAll];
    }
    if (self.shouldRefreshNagivationBar) {
        self.shouldRefreshNagivationBar = NO;
        [UIView animateWithDuration:.4f delay:.2f options:0 animations:^{
            [self renderNavigationBarTheme:NO];
        } completion:^(BOOL finished) {
            
        }];
    }
    if (self.shouldFocusTextView) {
        self.shouldFocusTextView = NO;
        [self.textView becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self dismissKeyboardNotifications];
    [self dismissStateNotifications];
    [super viewWillDisappear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        self.parser.aborted = YES;
        [self saveDocumentIfNecessary];
    }
    [super didMoveToParentViewController:parent];
}

#pragma mark - Layout

- (void)configure {
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = self.shareButtonItem;
    
    // Subviews
    if (XXTE_PAD) {
        
    } else {
        [self.view addSubview:self.fakeStatusBar];
    }
    [self.view addSubview:self.textView];
    [self.view addSubview:self.toolbar];
    
    // Constraints
    if (XXTE_PAD)
    {
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
          ];
        [self.view addConstraints:constraints];
    }
    else
    {
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.fakeStatusBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
          ];
        [self.view addConstraints:constraints];
    }
    
    NSArray <NSLayoutConstraint *> *constraints =
    @[
      [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:kXXTEEditorToolbarHeight],
      [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
      [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
      [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
      ];
    [self.view addConstraints:constraints];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)shareButtonItem {
    if (!_shareButtonItem) {
        UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarShare"] style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonItemTapped:)];
        _shareButtonItem = shareButtonItem;
    }
    return _shareButtonItem;
}

- (UIBarButtonItem *)settingsButtonItem {
    if (!_settingsButtonItem) {
        UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarSettings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonItemTapped:)];
        _settingsButtonItem = settingsButtonItem;
    }
    return _settingsButtonItem;
}

- (UIView *)fakeStatusBar {
    if (!_fakeStatusBar) {
        CGRect frame = [[UIApplication sharedApplication] statusBarFrame];
        UIView *fakeStatusBar = [[UIView alloc] initWithFrame:frame];
        fakeStatusBar.backgroundColor = [UIColor clearColor];
        fakeStatusBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        fakeStatusBar.translatesAutoresizingMaskIntoConstraints = NO;
        _fakeStatusBar = fakeStatusBar;
    }
    return _fakeStatusBar;
}

- (XXTEEditorTextView *)textView {
    if (!_textView) {
        XXTEEditorTextStorage *textStorage = [[XXTEEditorTextStorage alloc] init];
        textStorage.delegate = self;
        
        XXTEEditorTypeSetter *typeSetter = [[XXTEEditorTypeSetter alloc] init];
        XXTEEditorLayoutManager *layoutManager = [[XXTEEditorLayoutManager alloc] init];
        layoutManager.delegate = typeSetter;
        
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        textContainer.lineBreakMode = NSLineBreakByWordWrapping;
        textContainer.widthTracksTextView = YES;
        
        [layoutManager addTextContainer:textContainer];
        [textStorage removeLayoutManager:textStorage.layoutManagers.firstObject];
        [textStorage addLayoutManager:layoutManager];
        
        XXTEEditorTextInput *textInput = [[XXTEEditorTextInput alloc] init];
        textInput.scrollViewDelegate = self;
        
        XXTEEditorTextView *textView = [[XXTEEditorTextView alloc] initWithFrame:self.view.bounds textContainer:textContainer];
        textView.delegate = textInput;
        textView.selectable = YES;
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        textView.returnKeyType = UIReturnKeyDefault;
        textView.dataDetectorTypes = UIDataDetectorTypeNone;
        textView.textAlignment = NSTextAlignmentLeft;
        textView.allowsEditingTextAttributes = NO;
        
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kXXTEEditorToolbarHeight, 0.0);
        textView.contentInset = contentInsets;
        textView.scrollIndicatorInsets = contentInsets;
        
        textView.indicatorStyle = [self isDarkMode] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
        
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 11.0, *)) {
            textView.smartDashesType = UITextSmartDashesTypeNo;
            textView.smartQuotesType = UITextSmartQuotesTypeNo;
            textView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
            textView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
        XXTE_END_IGNORE_PARTIAL
        
        textView.vTextStorage = textStorage;
        textView.vTypeSetter = typeSetter;
        textView.vLayoutManager = layoutManager;
        textView.vTextInput = textInput;
        
        _textView = textView;
    }
    return _textView;
}

- (XXTEKeyboardRow *)keyboardRow {
    if (!_keyboardRow) {
        XXTEKeyboardRow *keyboardRow = [[XXTEKeyboardRow alloc] init];
        _keyboardRow = keyboardRow;
    }
    return _keyboardRow;
}

- (XXTEEditorToolbar *)toolbar {
    if (!_toolbar) {
        XXTEEditorToolbar *toolbar = [[XXTEEditorToolbar alloc] init];
        toolbar.translucent = NO;
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        toolbar.items = @[ flexible, self.settingsButtonItem ];
        _toolbar = toolbar;
    }
    return _toolbar;
}

#pragma mark - Getters

- (BOOL)isEditing {
    return self.textView.isFirstResponder;
}

#pragma mark - Content

- (void)reloadContent {
    NSString *entryPath = self.entryPath;
    if (!entryPath) return;
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    NSError *readError = nil;
    NSString *string = [XXTEEditorPreprocessor preprocessedStringWithContentsOfFile:self.entryPath Error:&readError];
    if (readError) {
        toastMessage(self, [readError localizedDescription]);
        return;
    }
    XXTEEditorTheme *theme = self.theme;
    XXTEEditorTextView *textView = self.textView;
    textView.editable = NO;
    [textView setFont:theme.font];
    [textView setTextColor:theme.foregroundColor];
    [textView setText:string];
    textView.editable = !isReadOnlyMode;
}

#pragma mark - Attributes

- (void)reloadAttributes {
    [self invalidateSyntaxCaches];
    BOOL isHighlightEnabled = XXTEDefaultsBool(XXTEEditorHighlightEnabled, YES); // config
    if (isHighlightEnabled) {
        NSString *wholeString = self.textView.text;
        NSDictionary *d = self.theme.defaultAttributes;
        blockInteractions(self, YES);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @weakify(self);
            [self.parser attributedParseString:wholeString matchCallback:^(NSString * _Nonnull scope, NSRange range, NSDictionary <NSString *, id> * _Nullable attributes) {
                @strongify(self);
                [self.rangesArray addObject:[NSValue valueWithRange:range]];
                if (attributes) {
                    [self.attributesArray addObject:attributes];
                } else {
                    [self.attributesArray addObject:d];
                }
            }];
            dispatch_async_on_main_queue(^{
                [self renderSyntaxOnScreen];
                blockInteractions(self, NO);
            });
        });
    }
}

- (void)reloadAttributesIfNecessary {
    if (!self.shouldReloadAttributes) return;
    self.shouldReloadAttributes = NO;
    [self reloadAttributes];
}

#pragma mark - NSTextStorageDelegate

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta
{
    if (!self.textView.editable) return;
    if (editedMask & NSTextStorageEditedCharacters) {
        NSString *text = textStorage.string;
        NSUInteger s, e;
        [text getLineStart:&s end:NULL contentsEnd:&e forRange:editedRange];
        NSRange lineRange = NSMakeRange(s, e - s);
        NSDictionary *d = self.theme.defaultAttributes;
//        [textStorage setAttributes:d range:lineRange];
//        [textStorage fixAttributesInRange:lineRange];
        [self.parser attributedParseString:text inRange:lineRange matchCallback:^(NSString *scopeName, NSRange range, SKAttributes attributes) {
            if (NO == NSRangeEntirelyContains(lineRange, range)) {
                range = NSIntersectionRange(lineRange, range);
            }
            if (attributes) {
                [textStorage addAttributes:attributes range:range];
            } else {
                [textStorage setAttributes:d range:range];
            }
            [textStorage fixAttributesInRange:range];
        }];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self renderSyntaxOnScreen];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self renderSyntaxOnScreen];
}

#pragma mark - Render Engine

- (NSRange)rangeShouldRenderOnScreen {
    XXTEEditorTextView *textView = self.textView;
    NSUInteger textLength = textView.text.length;
    
    CGRect bounds = textView.bounds;
    UITextPosition *start = [textView characterRangeAtPoint:bounds.origin].start;
    UITextPosition *end = [textView characterRangeAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))].end;
    
    NSInteger beginOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:start];
    beginOffset -= kXXTEEditorCachedRangeLength;
    if (beginOffset < 0) beginOffset = 0;
    NSInteger endLength = [textView offsetFromPosition:start toPosition:end];
    endLength += kXXTEEditorCachedRangeLength * 2;
    if (beginOffset + endLength > 0 + textLength) endLength = 0 + textLength - beginOffset;
    
    NSRange range = NSMakeRange((NSUInteger) beginOffset, (NSUInteger) endLength);
    return range;
}

- (void)renderSyntaxOnScreen {
    if (self.parser.aborted) return;
    
    NSArray *rangesArray = self.rangesArray;
    NSArray *attributesArray = self.attributesArray;
    NSMutableIndexSet *renderedSet = self.renderedSet;
    XXTEEditorTextView *textView = self.textView;
    NSTextStorage *vStorage = textView.vTextStorage;
    
    NSRange range = [self rangeShouldRenderOnScreen];
    
    if ([renderedSet containsIndexesInRange:range]) return;
    [renderedSet addIndexesInRange:range];
    
    NSUInteger rangesArrayLength = rangesArray.count;
    NSUInteger attributesArrayLength = attributesArray.count;
    if (rangesArrayLength != attributesArrayLength) return;
    
    // Single
    if (self.isRendering) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        self.isRendering = YES;
        
        // Filter
        NSMutableArray <NSNumber *> *renderIndexes = [[NSMutableArray alloc] init];
        for (NSUInteger idx = 0; idx < rangesArrayLength; idx++) {
            NSValue *rangeValue = rangesArray[idx];
            NSRange preparedRange = [rangeValue rangeValue];
            if (NSIntersectionRange(range, preparedRange).length != 0) {
                [renderIndexes addObject:@(idx)];
            }
        }
        
        // Render
        if (!self.parser.aborted) {
            dispatch_async_on_main_queue(^{
                [vStorage beginEditing];
                NSUInteger renderLength = renderIndexes.count;
                for (NSUInteger idx = 0; idx < renderLength; idx++) {
                    NSUInteger index = [renderIndexes[idx] unsignedIntegerValue];
                    NSValue *rangeValue = rangesArray[index];
                    NSRange preparedRange = [rangeValue rangeValue];
                    [vStorage addAttributes:attributesArray[index] range:preparedRange];
                }
                [vStorage endEditing];
            });
        }
        
        self.isRendering = NO;
    });
}

- (void)invalidateSyntaxCaches {
    [self.rangesArray removeAllObjects];
    [self.attributesArray removeAllObjects];
    [self.renderedSet removeAllIndexes];
}

#pragma mark - Lazy Flags

- (void)setNeedsReload {
    self.shouldReloadAll = YES;
}

- (void)setNeedsSaveDocument {
    self.shouldSaveDocument = YES;
}

- (void)setNeedsReloadAttributes {
    self.shouldReloadAttributes = YES;
}

- (void)setNeedsFocusTextView {
    self.shouldFocusTextView = YES;
}

- (void)setNeedsRefreshNavigationBar {
    self.shouldRefreshNagivationBar = YES;
}

#pragma mark - Save Document

- (void)saveDocumentIfNecessary {
    if (!self.shouldSaveDocument || !self.textView.editable) return;
    self.shouldSaveDocument = NO;
    NSString *documentString = self.textView.textStorage.string;
    NSData *documentData = [documentString dataUsingEncoding:NSUTF8StringEncoding];
    [documentData writeToFile:self.entryPath atomically:YES];
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self invalidateSyntaxCaches];
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEEditorController dealloc]");
#endif
}

@end
