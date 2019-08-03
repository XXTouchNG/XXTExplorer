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
#import "XXTEEditorDefaults.h"

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

// Views
#import "XXTELockedTitleView.h"
#import "XXTESingleActionView.h"

// Search
#import "XXTEEditorSearchBar.h"
#import "ICTextView.h"
#import "ICRangeUtils.h"
#import "ICRegularExpression.h"

// Replace
#import "SKParser.h"

// Encoding
#import "XXTEEditorEncodingHelper.h"
#import "XXTENavigationController.h"
#import "XXTEEditorEncodingController.h"


static NSUInteger const kXXTEEditorCachedRangeLength = 30000;

#ifdef APPSTORE
@interface XXTEEditorController () <UIScrollViewDelegate, NSTextStorageDelegate, XXTEEditorSearchBarDelegate, XXTEEditorSearchAccessoryViewDelegate, XXTEKeyboardToolbarRowDelegate, XXTEEditorEncodingControllerDelegate>
#else
@interface XXTEEditorController () <UIScrollViewDelegate, NSTextStorageDelegate, XXTEEditorSearchBarDelegate, XXTEEditorSearchAccessoryViewDelegate, XXTEKeyboardToolbarRowDelegate>
#endif

@property (nonatomic, strong) XXTELockedTitleView *lockedTitleView;
@property (nonatomic, strong) XXTESingleActionView *actionView;

@property (nonatomic, strong) UIScrollView *containerView;
@property (nonatomic, strong) NSLayoutConstraint *textViewWidthConstraint;

@property (nonatomic, strong) XXTEKeyboardRow *keyboardRow;
@property (nonatomic, strong) XXTEKeyboardToolbarRow *keyboardToolbarRow;
@property (nonatomic, strong) XXTEEditorSearchAccessoryView *searchAccessoryView;

@property (nonatomic, strong) UIBarButtonItem *myBackButtonItem;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;
@property (nonatomic, strong) UIBarButtonItem *launchButtonItem;

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
@property (nonatomic, assign, getter=isHighlightEnabled) BOOL highlightEnabled;

@property (nonatomic, strong) XXTEEditorSearchBar *searchBar;
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *closedSearchBarConstraints;
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *expandedSearchBarConstraints;

@property (nonatomic, assign) BOOL shouldReloadTextViewWidth;

@end

@implementation XXTEEditorController {
    BOOL isFirstTimeLoaded;
    BOOL _lockedState;
}

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
    
    _lockedState = NO;
    _currentEncoding = kCFStringEncodingUTF8;
    _currentLineBreak = NSStringLineBreakTypeLF;
    
    [self registerUndoNotifications];
}

- (void)reloadAll {
    NSString *newContent = [self loadContent];
    [self prepareForView];
    [self reloadUI];
    [self reloadTextViewLayout];
    [self reloadTextViewProperties];
    [self reloadContent:newContent];
    [self reloadAttributes];
}

- (void)reloadSoft {
    [self reloadUI];
    [self reloadTextViewProperties];
}

- (void)prepareForView {
    
    static NSString * const XXTEDefaultFontName = @"Courier";
    
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
    
    BOOL isLockedState = self.isLockedState;
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    
    // TextView
    XXTEEditorTextView *textView = self.textView;
    textView.keyboardType = UIKeyboardTypeDefault;
    textView.autocapitalizationType = XXTEDefaultsEnum(XXTEEditorAutoCapitalization, UITextAutocapitalizationTypeNone);
    textView.autocorrectionType = XXTEDefaultsEnum(XXTEEditorAutoCorrection, UITextAutocorrectionTypeNo); // config
    textView.spellCheckingType = XXTEDefaultsEnum(XXTEEditorSpellChecking, UITextSpellCheckingTypeNo); // config
    textView.editable = (isReadOnlyMode == NO && isLockedState == NO);
    
    // Set the fucking smart types again
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 11.0, *)) {
        textView.smartDashesType = UITextSmartDashesTypeNo;
        textView.smartQuotesType = UITextSmartQuotesTypeNo;
        textView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    } else {
        // Fallback on earlier versions
    }
    XXTE_END_IGNORE_PARTIAL
    
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
        if (XXTE_IS_IPAD && XXTE_SYSTEM_9) {
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

- (void)reloadUI {
    BOOL useRegular = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
    XXTEEditorSearchBar *searchBar = self.searchBar;
    [searchBar setRegexMode:useRegular];
    [searchBar updateView];
    
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO);
    BOOL isLockedState = self.isLockedState;
    [self.lockedTitleView setLocked:(isReadOnlyMode || isLockedState)];
    
    [self.launchButtonItem setEnabled:[self isLaunchItemAvailable]];
    [self.searchButtonItem setEnabled:[self isSearchButtonItemAvailable]];
    [self.symbolsButtonItem setEnabled:[self isSymbolsButtonItemAvailable]];
    [self.statisticsButtonItem setEnabled:[self isStatisticsButtonItemAvailable]];
    [self.settingsButtonItem setEnabled:[self isSettingsButtonItemAvailable]];
    
    UIColor *newColor = self.theme.foregroundColor;
    if (!newColor) newColor = [UIColor blackColor];
    self.actionView.titleLabel.textColor = newColor;
    self.actionView.descriptionLabel.textColor = newColor;
    if (![self isDarkMode]) {
        self.actionView.iconImageView.image = [UIImage imageNamed:@"XXTEBugIcon"];
    } else {
        self.actionView.iconImageView.image = [UIImage imageNamed:@"XXTEBugIconLight"];
    }
    
    if (isLockedState)
    {
        if (![self.view.subviews containsObject:self.actionView])
        {
            [self.view addSubview:self.actionView];
        }
        [self.textView setHidden:YES];
    }
    else
    {
        [self.textView setHidden:NO];
        [self.actionView removeFromSuperview];
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
    searchBar.separatorColor = [theme.foregroundColor colorWithAlphaComponent:0.2];
    
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
    
    if (NO == [self isDarkMode] || XXTE_IS_IPAD)
    {
        searchBar.searchKeyboardAppearance = UIKeyboardAppearanceLight;
        searchBar.replaceKeyboardAppearance = UIKeyboardAppearanceLight;
        searchAccessoryView.barStyle = UIBarStyleDefault;
        textView.keyboardAppearance = UIKeyboardAppearanceLight;
        
        [keyboardRow setColorStyle:XXTEKeyboardRowStyleLight];
        [keyboardToolbarRow setStyle:XXTEKeyboardToolbarRowStyleLight];
    }
    else
    {
        searchBar.searchKeyboardAppearance = UIKeyboardAppearanceDark;
        searchBar.replaceKeyboardAppearance = UIKeyboardAppearanceDark;
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
    [self reloadUI];
    [self reloadTextViewLayout];
    [self reloadTextViewProperties];
    [self reloadContent:newContent];
    [self reloadAttributes];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
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
    
    [self saveDocumentIfNecessary];
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
    // fixed - unnecessary textview width fix
    if (NO == isFirstTimeLoaded) {
        [self fixTextViewInsetsAndWidth];
        isFirstTimeLoaded = YES;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     { // usually on iPad
         [self fixTextViewInsetsAndWidth];
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     }];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
    XXTE_END_IGNORE_PARTIAL
}

- (void)fixTextViewInsetsAndWidth
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        // insets = self.view.safeAreaInsets;
    }
    UITextView *textView = self.textView;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(insets.top, insets.left, insets.bottom + kXXTEEditorToolbarHeight, insets.right);
    textView.contentInset = contentInsets;
    textView.scrollIndicatorInsets = contentInsets;
    [self setNeedsReloadTextViewWidth]; // fixed
    [self reloadTextViewWidthIfNecessary];
}

#pragma mark - Layout

- (void)configure {
    if (self.title.length == 0) {
        NSString *entryPath = self.entryPath;
        if (entryPath) {
            NSString *entryName = [entryPath lastPathComponent];
            self.title = entryName;
        }
    }
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.leftBarButtonItems = @[self.myBackButtonItem];
    if (isOS9Above() && isAppStore()) {
        self.navigationItem.rightBarButtonItems = @[self.shareButtonItem, self.launchButtonItem];
    } else {
        self.navigationItem.rightBarButtonItems = @[self.shareButtonItem];
    }
    self.lockedTitleView.title = self.title;
    self.navigationItem.titleView = self.lockedTitleView;
    
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

- (XXTELockedTitleView *)lockedTitleView {
    if (!_lockedTitleView) {
        _lockedTitleView = (XXTELockedTitleView *)[[[UINib nibWithNibName:@"XXTELockedTitleView" bundle:nil] instantiateWithOwner:nil options:nil] lastObject];
    }
    return _lockedTitleView;
}

- (XXTESingleActionView *)actionView {
    if (!_actionView) {
        XXTESingleActionView *actionView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTESingleActionView class]) owner:nil options:nil] lastObject];
        actionView.frame = self.view.bounds;
        actionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionViewTapped:)];
        [actionView addGestureRecognizer:tapGesture];
        _actionView = actionView;
    }
    return _actionView;
}

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

- (UIBarButtonItem *)launchButtonItem {
    if (!_launchButtonItem) {
        _launchButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(launchItemTapped:)];
    }
    return _launchButtonItem;
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
        
        textView.circularSearch = YES;
        textView.scrollPosition = ICTextViewScrollPositionMiddle;
        
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 11.0, *)) {
            textView.smartDashesType = UITextSmartDashesTypeNo;
            textView.smartQuotesType = UITextSmartQuotesTypeNo;
            textView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
        } else {
            // Fallback on earlier versions
        }
        XXTE_END_IGNORE_PARTIAL
        
        textView.keyboardType = UIKeyboardTypeDefault;
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textView.autocorrectionType = UITextAutocorrectionTypeNo; // config
        textView.spellCheckingType = UITextSpellCheckingTypeNo; // config
        
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

#pragma mark - Actions

#ifdef APPSTORE
- (void)actionViewTapped:(XXTESingleActionView *)actionView {
    XXTEEditorEncodingController *controller = [[XXTEEditorEncodingController alloc] initWithStyle:UITableViewStylePlain];
    controller.title = NSLocalizedString(@"Select Encoding", nil);
    controller.delegate = self;
    controller.reopenMode = YES;
    XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:controller];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navigationController animated:YES completion:nil];
}
#else
- (void)actionViewTapped:(XXTESingleActionView *)actionView {
    
}
#endif

#pragma mark - Getters

- (BOOL)isEditing {
    return _textView.isFirstResponder || _searchBar.isFirstResponder;
}

- (BOOL)isLockedState {
    return _lockedState;
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
    CFStringEncoding tryEncoding = [self currentEncoding];
    NSStringLineBreakType tryLineBreak = [self currentLineBreak];
    NSString *string = [XXTEEditorPreprocessor preprocessedStringWithContentsOfFile:entryPath NumberOfLines:&numberOfLines Encoding:&tryEncoding LineBreak:&tryLineBreak Error:&readError];
    if (!string) {
        [self setLockedState:YES];
        self.actionView.titleLabel.text = NSLocalizedString(@"Bad Encoding", nil);
        self.actionView.descriptionLabel.text = readError ? [NSString stringWithFormat:NSLocalizedString(@"%@\nTap here to change encoding.", nil), readError.localizedDescription] : NSLocalizedString(@"Unknown reason.", nil);
        return nil;
    } else {
        [self setLockedState:NO];
    }
    [self setCurrentEncoding:tryEncoding];
    [self setCurrentLineBreak:tryLineBreak];
    [_textView.vLayoutManager setNumberOfDigits:GetNumberOfDigits(numberOfLines)];
    return string;
}

- (void)reloadContent:(NSString *)content {
    if (!content) return;
    
    BOOL isLockedState = self.isLockedState;
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    [self resetSearch];
    
    XXTEEditorTheme *theme = self.theme;
    XXTEEditorTextView *textView = self.textView;
    [textView setEditable:NO];
    [textView setFont:theme.font];
    [textView setTextColor:theme.foregroundColor];
    [textView setText:content];
    [textView setEditable:(isReadOnlyMode == NO && isLockedState == NO)];
    [textView setSelectedRange:NSMakeRange(0, 0)];
    
    XXTEKeyboardToolbarRow *keyboardToolbarRow = self.keyboardToolbarRow;
    keyboardToolbarRow.redoItem.enabled = NO;
    keyboardToolbarRow.undoItem.enabled = NO;
    keyboardToolbarRow.snippetItem.enabled = (NO == isReadOnlyMode && NO == isLockedState && self.language != nil);
    {
        [textView.undoManager removeAllActions]; // reset undo manager
    }
    
}

#pragma mark - Attributes

- (void)reloadAttributes {
    [self invalidateSyntaxCaches];
    self.highlightEnabled = XXTEDefaultsBool(XXTEEditorHighlightEnabled, YES); // config
    if ([self isHighlightEnabled]) {
        NSString *wholeString = self.textView.text;
        UIViewController *blockVC = blockInteractions(self, YES);
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
    if (NO == self.textView.editable) return;
    if (![self isHighlightEnabled]) {
        return;
    }
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

#pragma mark - XXTEEditorEncodingControllerDelegate

#ifdef APPSTORE
- (void)encodingControllerDidConfirm:(XXTEEditorEncodingController *)controller
{
    [self setCurrentEncoding:controller.selectedEncoding];
    // [self setNeedsSaveDocument];
    [self setNeedsReload];
    [controller dismissViewControllerAnimated:YES completion:^{
        
    }];
}
#endif

#ifdef APPSTORE
- (void)encodingControllerDidCancel:(XXTEEditorEncodingController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
#endif

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
        [self updateCountLabel];
    }
}

- (void)toggleSearchBar:(UIBarButtonItem *)sender animated:(BOOL)animated {
    [self resetSearch];
    if ([self isSearchMode]) {
        [self closeSearchBar:sender animated:animated];
    } else {
        [self expandSearchBar:sender animated:animated];
    }
}

- (void)expandSearchBar:(UIBarButtonItem *)sender animated:(BOOL)animated {
    [self.searchBar setSearchText:@""];
    [self.searchBar setReplaceText:@""];
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
    _searchMode = YES;
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
    _searchMode = NO;
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
        searchBar.searchInputAccessoryView = self.searchAccessoryView;
        searchBar.replaceInputAccessoryView = self.searchAccessoryView;
        searchBar.delegate = self;
        _searchBar = searchBar;
    }
    return _searchBar;
}

#pragma mark - XXTEEditorSearchBarDelegate

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldReturn:(UITextField *)textField {
    [self searchNextMatch:searchBar.searchText];
    return YES;
}

- (void)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldDidChange:(UITextField *)textField {
    [self searchNextMatch:searchBar.searchText];
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldClear:(UITextField *)textField {
    [self searchNextMatch:searchBar.searchText];
    return YES;
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldReturn:(UITextField *)textField {
    [self searchNextMatch:searchBar.searchText];
    return YES;
}

- (void)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldDidChange:(UITextField *)textField {
    // nothing to do...
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldClear:(UITextField *)textField {
    // nothing to do...
    return YES;
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldBeginEditing:(UITextField *)textField {
    XXTEEditorSearchAccessoryView *searchAccessoryView = self.searchAccessoryView;
    BOOL isLockedState = self.isLockedState;
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    [searchAccessoryView setAllowReplacement:(NO == isReadOnlyMode && NO == isLockedState)];
    [searchAccessoryView setReplaceMode:NO];
    [searchAccessoryView updateAccessoryView];
    [self.textView resetSearch];
    [self searchNextMatch:searchBar.searchText];
    return YES;
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldBeginEditing:(UITextField *)textField {
    XXTEEditorSearchAccessoryView *searchAccessoryView = self.searchAccessoryView;
    BOOL isLockedState = self.isLockedState;
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    [searchAccessoryView setAllowReplacement:(NO == isReadOnlyMode && NO == isLockedState)];
    [searchAccessoryView setReplaceMode:YES];
    [searchAccessoryView updateAccessoryView];
    [self.textView resetSearch];
    [self searchNextMatch:searchBar.searchText];
    return YES;
}

- (void)searchBarDidCancel:(XXTEEditorSearchBar *)searchBar {
    [self resetSearch];
    [self closeSearchBar:nil animated:YES];
}

#pragma mark - XXTEEditorSearchAccessoryViewDelegate

- (void)searchAccessoryViewShouldMatchPrev:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self searchPreviousMatch:self.searchBar.searchText];
}

- (void)searchAccessoryViewShouldMatchNext:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self searchNextMatch:self.searchBar.searchText];
}

- (BOOL)searchAccessoryViewAllowReplacement:(XXTEEditorSearchAccessoryView *)accessoryView {
    return YES;
}

- (void)searchAccessoryViewShouldReplace:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self replaceNextMatch:self.searchBar.searchText replacement:self.searchBar.replaceText];
}

- (void)searchAccessoryViewShouldReplaceAll:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self replaceAll:self.searchBar.searchText replacement:self.searchBar.replaceText];
}

#pragma mark - ICTextView

- (void)searchNextMatch:(NSString *)target
{
    [self searchMatch:target inDirection:ICTextViewSearchDirectionForward];
}

- (void)replaceNextMatch:(NSString *)target replacement:(NSString *)replacement
{
    BOOL useRegular = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
    XXTEEditorTextView *textView = self.textView;
    NSTextCheckingResult *match = [textView matchOfFoundString];
    if (match.range.location != NSNotFound &&
        match.range.length > 0) {
        UITextPosition *beginPos = [textView positionFromPosition:textView.beginningOfDocument offset:match.range.location];
        UITextPosition *endPos = [textView positionFromPosition:beginPos offset:match.range.length];
        UITextRange *textRange = [textView textRangeFromPosition:beginPos toPosition:endPos];
        if (useRegular && match.numberOfRanges >= 2) {
            NSString *expandedRepl = [SKParser expandExpressionStringBackReferences:replacement withMatch:match withString:textView.text];
            [textView replaceRange:textRange withText:expandedRepl];
        } else {
            [textView replaceRange:textRange withText:replacement];
        }
        [textView setSearchIndex:match.range.location];
        [self searchNextMatch:target];
    } else {
        // cannot find matching contents
    }
}

- (void)replaceAll:(NSString *)target replacement:(NSString *)replacement
{
    BOOL caseSensitive = XXTEDefaultsBool(XXTEEditorSearchCaseSensitive, NO);
    BOOL useRegular = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
    NSStringCompareOptions searchOptions;
    if (caseSensitive) {
        searchOptions = 0;
    } else {
        searchOptions = NSCaseInsensitiveSearch;
    }
    NSRegularExpressionOptions replaceOptions;
    if (caseSensitive) {
        replaceOptions = 0;
    } else {
        replaceOptions = NSRegularExpressionCaseInsensitive;
    }
    XXTEEditorTextView *textView = self.textView;
    NSTextCheckingResult *match = [textView matchOfFoundString];
    if (match.range.location != NSNotFound &&
        match.range.length > 0) {
        NSString *text = textView.text;
        NSRange textRange = NSMakeRange(0, text.length);
        if (useRegular)
        {
            NSError *regexError = nil;
            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:target options:replaceOptions error:&regexError];
            if (regex)
            {
                NSString *newString = [regex stringByReplacingMatchesInString:text options:0 range:textRange withTemplate:[SKParser convertToICUBackReferencedString:replacement]];
                [textView setText:newString];
                [self reloadAttributes];
            }
        }
        else
        {
            NSString *newString = [text stringByReplacingOccurrencesOfString:target withString:replacement options:searchOptions range:textRange];
            [textView setText:newString];
            [self reloadAttributes];
        }
        [self searchNextMatch:target];
    }
}

- (void)searchPreviousMatch:(NSString *)target
{
    [self searchMatch:target inDirection:ICTextViewSearchDirectionBackward];
}

- (void)searchMatch:(NSString *)target inDirection:(ICTextViewSearchDirection)direction
{
    BOOL caseSensitive = XXTEDefaultsBool(XXTEEditorSearchCaseSensitive, NO);
    if (!caseSensitive) {
        self.textView.searchOptions = NSRegularExpressionCaseInsensitive;
    } else {
        self.textView.searchOptions = 0;
    }
    if (target.length) {
        BOOL useRegular = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
//        BOOL searchSucceed = NO;
        if (useRegular) {
//            searchSucceed =
            [self.textView scrollToMatch:target searchDirection:direction];
        } else {
//            searchSucceed =
            [self.textView scrollToString:target searchDirection:direction];
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
    if (
        self.shouldSaveDocument == NO ||
        self.textView.editable == NO ||
        self.isLockedState == YES
        )
    {
        return;
    }
    self.shouldSaveDocument = NO;
    NSString *string = self.textView.textStorage.string;
    if ([self currentLineBreak] == NSStringLineBreakTypeCRLF) {
        string = [string stringByReplacingOccurrencesOfString:@NSStringLineBreakLF withString:@NSStringLineBreakCRLF];
    } else if ([self currentLineBreak] == NSStringLineBreakTypeCR) {
        string = [string stringByReplacingOccurrencesOfString:@NSStringLineBreakLF withString:@NSStringLineBreakCR];
    }
    CFDataRef data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, (__bridge CFStringRef)string, [self currentEncoding], 0);
    NSData *documentData = (__bridge NSData *)(data);
    NSString *entryPath = self.entryPath;
    promiseFixPermission(entryPath, NO); // fix permission
    [documentData writeToFile:entryPath atomically:YES];
#ifdef DEBUG
    NSLog(@"document saved with encoding %@: %@", [XXTEEditorEncodingHelper encodingNameForEncoding:[self currentEncoding]], entryPath);
#endif
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
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
