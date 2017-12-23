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
#import "XXTEEditorTextContainer.h"
#import "XXTEEditorTypeSetter.h"
#import "XXTEEditorTextInput.h"
#import "XXTEEditorPreprocessor.h"
#import "XXTEEditorMaskView.h"

// SyntaxKit
#import "SKAttributedParser.h"
#import "SKRange.h"

// Keyboard
#import "XXTEKeyboardRow.h"
#import "XXTEKeyboardToolbarRow.h"

#import "UINavigationController+XXTEFullscreenPopGesture.h"

// Extensions
#import "XXTEEditorController+State.h"
#import "XXTEEditorController+Keyboard.h"
#import "XXTEEditorController+Settings.h"
#import "XXTEEditorController+Menu.h"
#import "XXTEEditorController+NavigationBar.h"

// Toolbar
#import "XXTEEditorToolbar.h"

// Search
#import "XXTEEditorSearchBar.h"
#import "ICTextView.h"
#import "ICRangeUtils.h"
#import "ICRegularExpression.h"

static NSUInteger const kXXTEEditorCachedRangeLength = 30000;

@interface XXTEEditorController () <UIScrollViewDelegate, NSTextStorageDelegate, XXTEEditorSearchBarDelegate, XXTEEditorSearchAccessoryViewDelegate, XXTEKeyboardToolbarRowDelegate>

@property (nonatomic, strong) UIScrollView *containerView;
@property (nonatomic, strong) NSLayoutConstraint *textViewWidthConstraint;

@property (nonatomic, strong) XXTEKeyboardRow *keyboardRow;
@property (nonatomic, strong) XXTEKeyboardToolbarRow *keyboardToolbarRow;
@property (nonatomic, strong) XXTEEditorSearchAccessoryView *searchAccessoryView;

@property (nonatomic, strong) UIBarButtonItem *myBackButtonItem;
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
@property (nonatomic, assign) BOOL shouldReloadSoft;

@property (nonatomic, assign) BOOL shouldHighlightRange;
@property (nonatomic, assign) NSRange highlightRange;

@property (nonatomic, strong) XXTEEditorSearchBar *searchBar;
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *closedSearchBarConstraints;
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *expandedSearchBarConstraints;

@property (nonatomic, assign) BOOL shouldReloadTextViewWidth;

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
        [self setup];
    }
    return self;
}

- (void)setup {
    self.hidesBottomBarWhenPushed = YES;
    self.automaticallyAdjustsScrollViewInsets = NO; // !important
    
    _shouldReloadAll = NO;
    _shouldReloadSoft = NO;
    _shouldReloadAttributes = NO;
    _shouldSaveDocument = NO;
    _shouldFocusTextView = NO;
    _shouldRefreshNagivationBar = NO;
    _shouldHighlightRange = NO;
    _isRendering = NO;
    
    [self registerUndoNotifications];
}

- (void)reloadAll {
    NSString *newContent = [self loadContent];
    [self prepareForView];
    [self reloadTextViewLayout];
    [self reloadTextViewProperties];
    [self reloadContent:newContent];
    [self reloadAttributes];
}

- (void)reloadSoft {
    [self reloadTextViewProperties];
}

- (void)prepareForView {
    
    static NSString * const XXTEDefaultFontName = @"CourierNewPSMT";
    
    // Font
    NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, XXTEDefaultFontName);
    CGFloat fontSize = XXTEDefaultsDouble(XXTEEditorFontSize, 14.0);
    UIFont *font = nil;
    if (fontName) {
        font = [UIFont fontWithName:fontName size:fontSize];
        if (!font) { // not exists, new version?
            XXTEDefaultsSetObject(XXTEEditorFontName, nil); // reset font
            font = [UIFont fontWithName:XXTEDefaultFontName size:fontSize];
        }
        NSAssert(font, @"Cannot load default font from system.");
    }
    
    static NSString * const XXTEDefaultThemeName = @"Mac Classic";
    
    // Theme
    NSString *themeName = XXTEDefaultsObject(XXTEEditorThemeName, XXTEDefaultThemeName);
    if (themeName &&
        fontName && font)
    {
        XXTEEditorTheme *theme = [[XXTEEditorTheme alloc] initWithName:themeName baseFont:font];
        if (!theme) { // not registered, new version?
            XXTEDefaultsSetObject(XXTEEditorThemeName, nil); // reset theme
            theme = [[XXTEEditorTheme alloc] initWithName:XXTEDefaultThemeName baseFont:font];
        }
        NSAssert(theme, @"Cannot load default theme from main bundle.");
        _theme = theme;
    }
    
    // Language
    NSString *entryExtension = [self.entryPath pathExtension];
    if (entryExtension.length > 0)
    {
        XXTEEditorLanguage *language = [[XXTEEditorLanguage alloc] initWithExtension:entryExtension];
        if (!language) { // no such language?
            // TODO: fatal error
        }
        _language = language;
    }
    
    // Parser
    if (self.language.skLanguage && self.theme.skTheme)
    {
        SKAttributedParser *parser = [[SKAttributedParser alloc] initWithLanguage:self.language.skLanguage theme:self.theme.skTheme];
        if (!parser) {
            // TODO: fatal error
        }
        _parser = parser;
    }
    
}

#pragma mark - AFTER -viewDidLoad

- (void)reloadTextViewProperties {
    if (![self isViewLoaded]) return;
    
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    
    // TextView
    XXTEEditorTextView *textView = self.textView;
    textView.keyboardType = UIKeyboardTypeDefault;
    textView.autocapitalizationType = XXTEDefaultsEnum(XXTEEditorAutoCapitalization, UITextAutocapitalizationTypeNone);
    textView.autocorrectionType = XXTEDefaultsEnum(XXTEEditorAutoCorrection, UITextAutocorrectionTypeNo); // config
    textView.spellCheckingType = XXTEDefaultsEnum(XXTEEditorSpellChecking, UITextSpellCheckingTypeNo); // config
    textView.editable = !isReadOnlyMode;
    
    if (textView.vTextInput) {
        textView.vTextInput.language = self.language;
        textView.vTextInput.autoIndent = XXTEDefaultsBool(XXTEEditorAutoIndent, YES);
        textView.vTextInput.autoBrackets = XXTEDefaultsBool(XXTEEditorAutoBrackets, NO);
    }
    
    XXTEKeyboardRow *keyboardRow = self.keyboardRow;
    
    NSUInteger tabWidthEnum = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4);
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
    
    XXTEKeyboardToolbarRow *keyboardToolbarRow = self.keyboardToolbarRow;
    BOOL isKeyboardRowEnabled = XXTEDefaultsBool(XXTEEditorKeyboardRowAccessoryEnabled, NO); // config
    
    if (isReadOnlyMode) // iPad, or read-only
    {
        keyboardRow.textInput = nil;
        textView.inputAccessoryView = nil;
        textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
    }
    else {
        if (XXTE_PAD && XXTE_SYSTEM_9) {
            keyboardRow.textInput = nil;
            textView.inputAccessoryView = nil;
            textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
        } else {
            textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
            if (isKeyboardRowEnabled) {
                keyboardRow.textInput = textView;
                textView.inputAccessoryView = keyboardRow;
            } else {
                keyboardRow.textInput = nil;
                textView.inputAccessoryView = keyboardToolbarRow;
            }
        }
    }
    
    // Shared Menu
    if (NO == isReadOnlyMode && nil != self.language)
    {
        [self registerMenuActions];
    }
    else
    {
        [self dismissMenuActions];
    }
    
}

- (void)reloadTextViewLayout {
    if (![self isViewLoaded]) return;
    
    // Config
    BOOL isLineNumbersEnabled = XXTEDefaultsBool(XXTEEditorLineNumbersEnabled, NO); // config
    BOOL showInvisibleCharacters = XXTEDefaultsBool(XXTEEditorShowInvisibleCharacters, NO); // config
    
    // Theme Appearance
    XXTEEditorTheme *theme = self.theme;
    self.view.backgroundColor = theme.backgroundColor;
    self.view.tintColor = theme.foregroundColor;
    
    XXTEEditorSearchBar *searchBar = self.searchBar;
    searchBar.backgroundColor = theme.backgroundColor;
    searchBar.tintColor = theme.foregroundColor;
    searchBar.textColor = theme.foregroundColor;
    
    // TextView
    XXTEEditorTextView *textView = self.textView;
    textView.backgroundColor = [UIColor clearColor];
    textView.tintColor = theme.caretColor;
    textView.indicatorStyle = [self isDarkMode] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
    
    // Layout Manager
    [textView setShowLineNumbers:isLineNumbersEnabled]; // config
    if (textView.vLayoutManager) {
        UIColor *gutterColor = [theme.foregroundColor colorWithAlphaComponent:.45];
        
        [textView setGutterLineColor:gutterColor];
        [textView setGutterBackgroundColor:theme.backgroundColor];
        
        [textView.vLayoutManager setLineNumberFont:theme.font];
        [textView.vLayoutManager setLineNumberColor:gutterColor];
        
        [textView.vLayoutManager setShowInvisibleCharacters:showInvisibleCharacters];
        [textView.vLayoutManager setInvisibleColor:theme.invisibleColor];
        [textView.vLayoutManager setInvisibleFont:theme.font];
    }
    
    // Text Container
    BOOL indentWrappedLines = XXTEDefaultsBool(XXTEEditorIndentWrappedLines, NO);
    if (textView.vLayoutManager) {
        [textView.vLayoutManager setIndentWrappedLines:indentWrappedLines];
    }
    
    // Type Setter
    NSUInteger tabWidthEnum = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4);
    CGFloat tabWidth = tabWidthEnum * theme.tabWidth;
    if (textView.vTypeSetter) {
        textView.vTypeSetter.tabWidth = tabWidth;
    }
    
    // Keyboard Row
    XXTEKeyboardRow *keyboardRow = self.keyboardRow;
    XXTEKeyboardToolbarRow *keyboardToolbarRow = self.keyboardToolbarRow;
    keyboardToolbarRow.tintColor = theme.foregroundColor;
    
    // Accessories
    XXTEEditorSearchAccessoryView *searchAccessoryView = self.searchAccessoryView;
    searchAccessoryView.tintColor = theme.foregroundColor;
    
    if (NO == [self isDarkMode] || XXTE_PAD)
    {
        searchBar.keyboardAppearance = UIKeyboardAppearanceLight;
        searchAccessoryView.barStyle = UIBarStyleDefault;
        textView.keyboardAppearance = UIKeyboardAppearanceLight;
        
        [keyboardRow setColorStyle:XXTEKeyboardRowStyleLight];
        [keyboardToolbarRow setStyle:XXTEKeyboardToolbarRowStyleLight];
    }
    else
    {
        searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
        searchAccessoryView.barStyle = UIBarStyleBlack;
        textView.keyboardAppearance = UIKeyboardAppearanceDark;
        
        [keyboardRow setColorStyle:XXTEKeyboardRowStyleDark];
        [keyboardToolbarRow setStyle:XXTEKeyboardToolbarRowStyleDark];
    }
    
    // Other Views
    XXTEEditorToolbar *toolbar = self.toolbar;
    toolbar.tintColor = theme.barTextColor;
    toolbar.barTintColor = theme.barTintColor;
    for (UIBarButtonItem *item in toolbar.items) {
        item.tintColor = theme.barTextColor;
    }
    
    // Set Render Flags
    [self setNeedsReloadTextViewWidth];
    [self reloadTextViewWidthIfNecessary];
    [textView setNeedsDisplay];
    [self setNeedsRefreshNavigationBar];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configure];
    
    NSString *newContent = [self loadContent];
    [self prepareForView];
    [self reloadTextViewLayout];
    [self reloadTextViewProperties];
    [self reloadContent:newContent];
    [self reloadAttributes];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self registerStateNotifications];
    [self registerKeyboardNotifications];
    
    [self renderNavigationBarTheme:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadAllIfNecessary];
    [self reloadSoftIfNecessary];
    if (self.shouldRefreshNagivationBar) {
        self.shouldRefreshNagivationBar = NO;
        [UIView animateWithDuration:.4f delay:.2f options:0 animations:^{
            [self renderNavigationBarTheme:NO];
        } completion:^(BOOL finished) {
            
        }];
    }
    if (self.shouldHighlightRange) {
        [self highlightRangeIfNeeded];
    } else {
        if (self.shouldFocusTextView) {
            self.shouldFocusTextView = NO;
            [self.textView becomeFirstResponder];
        }
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        // insets = self.view.safeAreaInsets;
    }
    UITextView *textView = self.textView;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(insets.top, insets.left, insets.bottom + kXXTEEditorToolbarHeight, insets.right);
    textView.contentInset = contentInsets;
    textView.scrollIndicatorInsets = contentInsets;
    [self reloadTextViewWidthIfNecessary];
}

#pragma mark - Layout

- (void)configure {
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = self.myBackButtonItem;
    self.navigationItem.rightBarButtonItem = self.shareButtonItem;
    
    [self.maskView setTextView:self.textView];
    
    // Subviews
    [self.containerView addSubview:self.textView];
    [self.containerView addSubview:self.maskView];
    [self.view addSubview:self.containerView];
    [self.view addSubview:self.toolbar];
    [self.view addSubview:self.searchBar];
    
    // Constraints
    [self.view addConstraints:[self closedSearchBarConstraints]];
    {
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.searchBar attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
          ];
        [self.view addConstraints:constraints];
    }
    {
        NSLayoutConstraint *textViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant:self.containerView.bounds.size.width];
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
          textViewWidthConstraint,
          ];
        [self.containerView addConstraints:constraints];
        self.textViewWidthConstraint = textViewWidthConstraint;
    }
    {
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.maskView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.textView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.maskView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.textView attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.maskView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.textView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.maskView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.textView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
          ];
        [self.containerView addConstraints:constraints];
    }
    {
        NSLayoutConstraint *bottomConstraint = nil;
        if (@available(iOS 11.0, *))
        {
            bottomConstraint = [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        } else {
            bottomConstraint = [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        }
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:kXXTEEditorToolbarHeight],
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
          bottomConstraint,
          ];
        [self.view addConstraints:constraints];
    }
}

#pragma mark - UIView Getters

- (UIScrollView *)containerView {
    if (!_containerView) {
        UIScrollView *containerView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        containerView.scrollEnabled = YES;
        containerView.pagingEnabled = NO;
        containerView.bounces = NO;
        containerView.backgroundColor = [UIColor clearColor];
        containerView.showsVerticalScrollIndicator = NO;
        containerView.scrollsToTop = NO;
        containerView.delegate = self;
        if (@available(iOS 11.0, *)) {
            containerView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _containerView = containerView;
    }
    return _containerView;
}

- (UIBarButtonItem *)myBackButtonItem {
    if (!_myBackButtonItem) {
        UIBarButtonItem *myBackButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarBack"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonItemTapped:)];
        _myBackButtonItem = myBackButtonItem;
    }
    return _myBackButtonItem;
}

- (UIBarButtonItem *)shareButtonItem {
    if (!_shareButtonItem) {
        UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped:)];
        _shareButtonItem = shareButtonItem;
    }
    return _shareButtonItem;
}

- (UIBarButtonItem *)searchButtonItem {
    if (!_searchButtonItem) {
        UIBarButtonItem *searchButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarSearch"] style:UIBarButtonItemStylePlain target:self action:@selector(searchButtonItemTapped:)];
        _searchButtonItem = searchButtonItem;
    }
    return _searchButtonItem;
}

- (UIBarButtonItem *)symbolsButtonItem {
    if (!_symbolsButtonItem) {
        UIBarButtonItem *symbolsButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarSymbols"] style:UIBarButtonItemStylePlain target:self action:@selector(symbolsButtonItemTapped:)];
        _symbolsButtonItem = symbolsButtonItem;
    }
    return _symbolsButtonItem;
}

- (UIBarButtonItem *)statisticsButtonItem {
    if (!_statisticsButtonItem) {
        UIBarButtonItem *statisticsButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarStatistics"] style:UIBarButtonItemStylePlain target:self action:@selector(statisticsButtonItemTapped:)];
        _statisticsButtonItem = statisticsButtonItem;
    }
    return _statisticsButtonItem;
}

- (UIBarButtonItem *)settingsButtonItem {
    if (!_settingsButtonItem) {
        UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarSettings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonItemTapped:)];
        _settingsButtonItem = settingsButtonItem;
    }
    return _settingsButtonItem;
}

- (XXTEEditorTextView *)textView {
    if (!_textView) {
        XXTEEditorTextStorage *textStorage = [[XXTEEditorTextStorage alloc] init];
        textStorage.delegate = self;
        
        XXTEEditorTypeSetter *typeSetter = [[XXTEEditorTypeSetter alloc] init];
        XXTEEditorLayoutManager *layoutManager = [[XXTEEditorLayoutManager alloc] init];
        layoutManager.delegate = typeSetter;
        
        XXTEEditorTextContainer *textContainer = [[XXTEEditorTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
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
        textView.scrollsToTop = YES;
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        textView.returnKeyType = UIReturnKeyDefault;
        textView.dataDetectorTypes = UIDataDetectorTypeNone;
        textView.textAlignment = NSTextAlignmentLeft;
        textView.allowsEditingTextAttributes = NO;
        
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 11.0, *)) {
            textView.smartDashesType = UITextSmartDashesTypeNo;
            textView.smartQuotesType = UITextSmartQuotesTypeNo;
            textView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
//            textView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
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

- (XXTEEditorMaskView *)maskView {
    if (!_maskView) {
        XXTEEditorMaskView *maskView = [[XXTEEditorMaskView alloc] initWithFrame:self.view.bounds];
        maskView.translatesAutoresizingMaskIntoConstraints = NO;
        maskView.maskColor = [UIColor colorWithRed:241.0/255.0 green:196.0/255.0 blue:15.0/255.0 alpha:1.0];
        _maskView = maskView;
    }
    return _maskView;
}

- (XXTEKeyboardRow *)keyboardRow {
    if (!_keyboardRow) {
        XXTEKeyboardRow *keyboardRow = [[XXTEKeyboardRow alloc] init];
        _keyboardRow = keyboardRow;
    }
    return _keyboardRow;
}

- (XXTEKeyboardToolbarRow *)keyboardToolbarRow {
    if (!_keyboardToolbarRow) {
        XXTEKeyboardToolbarRow *keyboardToolbarRow = [[XXTEKeyboardToolbarRow alloc] init];
        keyboardToolbarRow.delegate = self;
        _keyboardToolbarRow = keyboardToolbarRow;
    }
    return _keyboardToolbarRow;
}

- (XXTEEditorSearchAccessoryView *)searchAccessoryView {
    if (!_searchAccessoryView) {
        XXTEEditorSearchAccessoryView *searchAccessoryView = [[XXTEEditorSearchAccessoryView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44.f)];
        searchAccessoryView.accessoryDelegate = self;
        _searchAccessoryView = searchAccessoryView;
    }
    return _searchAccessoryView;
}

- (XXTEEditorToolbar *)toolbar {
    if (!_toolbar) {
        XXTEEditorToolbar *toolbar = [[XXTEEditorToolbar alloc] init];
        if (@available(iOS 11.0, *)) {
            toolbar.translucent = YES;
        } else {
            toolbar.translucent = NO;
        }
        toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        toolbar.items = @[ self.searchButtonItem, flexible, self.symbolsButtonItem, flexible, self.statisticsButtonItem, flexible, self.settingsButtonItem ];
        _toolbar = toolbar;
    }
    return _toolbar;
}

#pragma mark - Getters

- (BOOL)isEditing {
    return _textView.isFirstResponder || _searchBar.isFirstResponder;
}

#pragma mark - Content

static inline NSUInteger GetNumberOfDigits(NSUInteger i)
{
    return i > 0 ? (NSUInteger)log10 ((double) i) + 1 : 1;
}

- (NSString *)loadContent {
    NSString *entryPath = self.entryPath;
    if (!entryPath) return nil;
    NSUInteger numberOfLines = 0;
    NSError *readError = nil;
    NSString *string = [XXTEEditorPreprocessor preprocessedStringWithContentsOfFile:entryPath NumberOfLines:&numberOfLines Error:&readError];
    if (readError) {
        toastMessage(self, [readError localizedDescription]);
        return nil;
    }
    [_textView.vLayoutManager setNumberOfDigits:GetNumberOfDigits(numberOfLines)];
    return string;
}

- (void)reloadContent:(NSString *)content {
    if (!content) return;
    
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    [self resetSearch];
    
    XXTEEditorTheme *theme = self.theme;
    XXTEEditorTextView *textView = self.textView;
    [textView setEditable:NO];
    [textView setFont:theme.font];
    [textView setTextColor:theme.foregroundColor];
    [textView setText:content];
    [textView setEditable:!isReadOnlyMode];
    [textView setSelectedRange:NSMakeRange(0, 0)];
    
    XXTEKeyboardToolbarRow *keyboardToolbarRow = self.keyboardToolbarRow;
    keyboardToolbarRow.redoItem.enabled = NO;
    keyboardToolbarRow.undoItem.enabled = NO;
    keyboardToolbarRow.snippetItem.enabled = (!isReadOnlyMode && self.language != nil);
    {
        [textView.undoManager removeAllActions]; // reset undo manager
    }
    
}

#pragma mark - Attributes

- (void)reloadAttributes {
    [self invalidateSyntaxCaches];
    BOOL isHighlightEnabled = XXTEDefaultsBool(XXTEEditorHighlightEnabled, YES); // config
    if (isHighlightEnabled) {
        NSString *wholeString = self.textView.text;
        UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 0.6);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSMutableArray *rangesArray = [[NSMutableArray alloc] init];
            NSMutableArray *attributesArray = [[NSMutableArray alloc] init];
            [self.parser attributedParseString:wholeString matchCallback:^(NSString * _Nonnull scope, NSRange range, NSDictionary <NSString *, id> * _Nullable attributes) {
                if (attributes) {
                    [rangesArray addObject:[NSValue valueWithRange:range]];
                    [attributesArray addObject:attributes];
                }
            }];
            dispatch_async_on_main_queue(^{
                {
                    self.rangesArray = rangesArray;
                    self.attributesArray = attributesArray;
                    self.renderedSet = [[NSMutableIndexSet alloc] init];
                }
                [self renderSyntaxOnScreen];
                blockInteractions(blockVC, NO);
            });
        });
    }
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
        [textStorage setAttributes:d range:lineRange];
        [textStorage fixAttributesInRange:lineRange];
        [self.parser attributedParseString:text inRange:lineRange matchCallback:^(NSString *scopeName, NSRange range, SKAttributes attributes) {
            if (NO == NSRangeEntirelyContains(lineRange, range)) {
                range = NSIntersectionRange(lineRange, range);
            }
            if (attributes) {
                [textStorage addAttributes:attributes range:range];
                [textStorage fixAttributesInRange:range];
            }
        }];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.textView) {
        [self renderSyntaxOnScreen];
    } else if (scrollView == self.containerView) {
        
    }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if (scrollView == self.textView) {
        [self renderSyntaxOnScreen];
    } else if (scrollView == self.containerView) {
        
    }
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
    if (!self.rangesArray || !self.attributesArray || !self.renderedSet) return;
    
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
                NSDictionary *d = self.theme.defaultAttributes;
                [vStorage setAttributes:d range:range];
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
    self.rangesArray = nil;
    self.attributesArray = nil;
    self.renderedSet = nil;
}

#pragma mark - Highlight

- (void)highlightRangeIfNeeded {
    if (self.shouldHighlightRange) {
        self.shouldHighlightRange = NO;
        [self.maskView flashWithRange:self.highlightRange];
    }
}

#pragma mark - Search

- (void)resetSearch {
    {
        if ([self.searchBar isFirstResponder]) {
            [self.searchBar resignFirstResponder];
        }
        [self.textView resetSearch];
        [self.searchBar setText:@""];
        [self updateCountLabel];
    }
}

- (void)toggleSearchBar:(UIBarButtonItem *)sender animated:(BOOL)animated {
    [self resetSearch];
    if ([self isSearchMode]) {
        [self closeSearchBar:sender animated:animated];
        _searchMode = NO;
    } else {
        [self expandSearchBar:sender animated:animated];
        _searchMode = YES;
    }
}

- (void)expandSearchBar:(UIBarButtonItem *)sender animated:(BOOL)animated {
    if (animated) {
        [self.searchBar setHidden:NO];
        [self.searchBar becomeFirstResponder];
        [self.view layoutIfNeeded];
        [self.view removeConstraints:[self closedSearchBarConstraints]];
        [self.view addConstraints:[self expandedSearchBarConstraints]];
        sender.enabled = NO;
        [UIView animateWithDuration:.2
                         animations:^{
                             [self.view layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             sender.enabled = YES;
                         }];
    } else {
        [self.view removeConstraints:[self closedSearchBarConstraints]];
        [self.view addConstraints:[self expandedSearchBarConstraints]];
    }
}

- (void)closeSearchBar:(UIBarButtonItem *)sender animated:(BOOL)animated {
    if (animated) {
        [self.view layoutIfNeeded];
        [self.view removeConstraints:[self expandedSearchBarConstraints]];
        [self.view addConstraints:[self closedSearchBarConstraints]];
        sender.enabled = NO;
        [UIView animateWithDuration:.2
                         animations:^{
                             [self.view layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             [self.searchBar setHidden:YES];
                             sender.enabled = YES;
                         }];
    } else {
        [self.view removeConstraints:[self expandedSearchBarConstraints]];
        [self.view addConstraints:[self closedSearchBarConstraints]];
    }
}

- (NSArray <NSLayoutConstraint *> *)expandedSearchBarConstraints {
    if (!_expandedSearchBarConstraints) {
        _expandedSearchBarConstraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:XXTEEditorSearchBarHeight],
          ];
    }
    return _expandedSearchBarConstraints;
}

- (NSArray <NSLayoutConstraint *> *)closedSearchBarConstraints {
    if (!_closedSearchBarConstraints) {
        _closedSearchBarConstraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:-XXTEEditorSearchBarHeight],
          [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
          [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant:XXTEEditorSearchBarHeight],
          ];
    }
    return _closedSearchBarConstraints;
}

- (BOOL)isSearchMode {
    return _searchMode;
}

- (XXTEEditorSearchBar *)searchBar {
    if (!_searchBar) {
        XXTEEditorSearchBar *searchBar = [[XXTEEditorSearchBar alloc] init];
        searchBar.backgroundColor = [UIColor whiteColor];
        searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        searchBar.hidden = YES;
        searchBar.inputAccessoryView = self.searchAccessoryView;
        searchBar.delegate = self;
        _searchBar = searchBar;
    }
    return _searchBar;
}

#pragma mark - XXTEEditorSearchBarDelegate

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar textFieldShouldReturn:(UITextField *)textField {
    [self searchNextMatch];
    return YES;
}

- (void)searchBar:(XXTEEditorSearchBar *)searchBar textFieldDidChange:(UITextField *)textField {
    [self searchNextMatch];
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar textFieldShouldClear:(UITextField *)textField {
    [self searchNextMatch];
    return YES;
}

#pragma mark - XXTEEditorSearchAccessoryViewDelegate

- (void)searchAccessoryViewShouldMatchPrev:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self searchPreviousMatch];
}

- (void)searchAccessoryViewShouldMatchNext:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self searchNextMatch];
}

#pragma mark - ICTextView

- (void)searchNextMatch
{
    [self searchMatchInDirection:ICTextViewSearchDirectionForward];
}

- (void)searchPreviousMatch
{
    [self searchMatchInDirection:ICTextViewSearchDirectionBackward];
}

- (void)searchMatchInDirection:(ICTextViewSearchDirection)direction
{
    NSString *searchString = self.searchBar.text;
    
    BOOL caseSensitive = XXTEDefaultsBool(XXTEEditorSearchCaseSensitive, NO);
    if (!caseSensitive) {
        self.textView.searchOptions = NSRegularExpressionCaseInsensitive;
    } else {
        self.textView.searchOptions = 0;
    }
    
    if (searchString.length) {
        BOOL useRegular = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
        if (useRegular) {
            [self.textView scrollToMatch:searchString searchDirection:direction];
        } else {
            [self.textView scrollToString:searchString searchDirection:direction];
        }
    } else {
        [self.textView resetSearch];
    }
    
    [self updateCountLabel];
}

- (void)updateCountLabel
{
    ICTextView *textView = self.textView;
    
    XXTEEditorSearchAccessoryView *searchAccessoryView = self.searchAccessoryView;
    UIBarButtonItem *prevItem = searchAccessoryView.prevItem;
    UIBarButtonItem *nextItem = searchAccessoryView.nextItem;
    UILabel *countLabel = searchAccessoryView.countLabel;
    
    NSUInteger numberOfMatches = textView.numberOfMatches;
    if (numberOfMatches > 0) {
        NSUInteger idx = textView.indexOfFoundString;
        if (idx != NSNotFound) {
            countLabel.text = numberOfMatches ? [NSString stringWithFormat:NSLocalizedString(@"%lu/%lu", nil), (unsigned long)idx + 1, (unsigned long)numberOfMatches] : NSLocalizedString(@"0/0", nil);
            [countLabel sizeToFit];
            if (idx == 0) {
                prevItem.enabled = NO;
                nextItem.enabled = YES;
            } else if (idx == numberOfMatches - 1) {
                prevItem.enabled = YES;
                nextItem.enabled = NO;
            } else {
                prevItem.enabled = YES;
                nextItem.enabled = YES;
            }
        }
    } else {
        countLabel.text = NSLocalizedString(@"0/0", nil);
        prevItem.enabled = NO;
        nextItem.enabled = NO;
    }
}

#pragma mark - TextView Width

- (void)reloadTextViewWidth {
    CGFloat newWidth = CGRectGetWidth(self.view.bounds);
    BOOL autoWrap = XXTEDefaultsBool(XXTEEditorAutoWordWrap, YES);
    if (NO == autoWrap) {
        NSInteger columnW = XXTEDefaultsInt(XXTEEditorWrapColumn, 160);
        if (columnW < 10 || columnW > 10000)
        {
            columnW = 160;
        }
        newWidth = [self textView:self.textView widthForTheme:self.theme columnWidth:columnW];
    }
    self.textViewWidthConstraint.constant = newWidth;
}

- (CGFloat)textView:(XXTEEditorTextView *)textView widthForTheme:(XXTEEditorTheme *)theme columnWidth:(NSInteger)colWidth {
    UIFont *calFont = theme.font;
    if (!calFont) return 0.0;
    
    NSString *calString = [@"" stringByPaddingToLength:colWidth withString:@"0" startingAtIndex:0];
    
    // content width
    CGFloat contentW = [calString sizeWithAttributes:@{ NSFontAttributeName: calFont }].width;
    // content inset
    UIEdgeInsets calInsetsA = textView.contentInset;
    // expected container inset
    UIEdgeInsets calInsetsB = textView.xxteTextContainerInset;
    // scroll indicator width
    CGFloat calIndicatorW = 2.33;
    // line fragment padding
    CGFloat lineFP = textView.textContainer.lineFragmentPadding;
    
    return ceil((contentW) +
                (calInsetsA.left + calInsetsA.right) +
                (calInsetsB.left + calInsetsB.right) +
                (calIndicatorW) +
                (lineFP * 2));
}

#pragma mark - Rotation

XXTE_START_IGNORE_PARTIAL
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self setNeedsReloadTextViewWidth];
}
XXTE_END_IGNORE_PARTIAL

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (XXTE_SYSTEM_8) {
        
    } else { // to be compatible with iOS 7
        [self setNeedsReloadTextViewWidth];
    }
}

#pragma mark - XXTEKeyboardToolbarRowDelegate

- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapUndo:(UIBarButtonItem *)sender {
    NSUndoManager *undoManager = [self.textView undoManager];
    if (undoManager.canUndo) {
        [undoManager undo];
    }
}

- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapRedo:(UIBarButtonItem *)sender {
    NSUndoManager *undoManager = [self.textView undoManager];
    if (undoManager.canRedo) {
        [undoManager redo];
    }
}

- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapDismiss:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
}

- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapSnippet:(UIBarButtonItem *)sender {
    [self menuActionCodeBlocks:nil];
}


- (void)registerUndoNotifications {
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUndoManagerNotification:) name:NSUndoManagerDidUndoChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUndoManagerNotification:) name:NSUndoManagerDidRedoChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUndoManagerNotification:) name:NSUndoManagerDidOpenUndoGroupNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUndoManagerNotification:) name:NSUndoManagerDidCloseUndoGroupNotification object:nil];
    }
}

- (void)dismissUndoNotifications {
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUndoManagerDidUndoChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUndoManagerDidRedoChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUndoManagerDidOpenUndoGroupNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUndoManagerDidCloseUndoGroupNotification object:nil];
    }
}

- (void)handleUndoManagerNotification:(NSNotification *)aNotification {
    NSString *notificationName = aNotification.name;
    if ([notificationName isEqualToString:NSUndoManagerDidOpenUndoGroupNotification]
        || [notificationName isEqualToString:NSUndoManagerDidCloseUndoGroupNotification]
        || [notificationName isEqualToString:NSUndoManagerDidUndoChangeNotification]
        || [notificationName isEqualToString:NSUndoManagerDidRedoChangeNotification]
        ) {
        NSUndoManager *undoManager = aNotification.object;
        if (undoManager == self.textView.undoManager)
        {
            XXTEKeyboardToolbarRow *keyboardToolbarRow = self.keyboardToolbarRow;
            if (undoManager.canRedo) {
                keyboardToolbarRow.redoItem.enabled = YES;
            } else {
                keyboardToolbarRow.redoItem.enabled = NO;
            }
            if (undoManager.canUndo) {
                keyboardToolbarRow.undoItem.enabled = YES;
            } else {
                keyboardToolbarRow.undoItem.enabled = NO;
            }
        } // you may receive undoManager from TextField(s)
    }
}

#pragma mark - Lazy Flags

- (void)setNeedsReload {
    self.shouldReloadAll = YES;
}

- (void)setNeedsSoftReload {
    self.shouldReloadSoft = YES;
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

- (void)setNeedsHighlightRange:(NSRange)range {
    self.highlightRange = range;
    self.shouldHighlightRange = YES;
}

- (void)setNeedsReloadTextViewWidth {
    self.shouldReloadTextViewWidth = YES;
}

#pragma mark - Lazy Load

- (void)reloadAllIfNecessary {
    if (self.shouldReloadAll) {
        self.shouldReloadAll = NO;
        [self reloadAll];
    }
}

- (void)reloadSoftIfNecessary {
    if (self.shouldReloadSoft) {
        self.shouldReloadSoft = NO;
        [self reloadSoft];
    }
}

- (void)reloadAttributesIfNecessary {
    if (!self.shouldReloadAttributes) return;
    self.shouldReloadAttributes = NO;
    [self reloadAttributes];
}

- (void)saveDocumentIfNecessary {
    if (!self.shouldSaveDocument || !self.textView.editable) return;
    self.shouldSaveDocument = NO;
    NSString *documentString = self.textView.textStorage.string;
    NSData *documentData = [documentString dataUsingEncoding:NSUTF8StringEncoding];
    [documentData writeToFile:self.entryPath atomically:YES];
}

- (void)reloadTextViewWidthIfNecessary {
    if (self.shouldReloadTextViewWidth) {
        [self reloadTextViewWidth];
        self.shouldReloadTextViewWidth = NO;
    }
}


#pragma mark - Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self invalidateSyntaxCaches];
}

- (void)dealloc {
    [self dismissUndoNotifications];
#ifdef DEBUG
    NSLog(@"- [XXTEEditorController dealloc]");
#endif
}

@end
