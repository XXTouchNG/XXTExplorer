//
//  XXTEEditorController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
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
#import "XXTETextPreprocessor.h"
#import "XXTEEditorMaskView.h"
#import "UITextView+VisibleRange.h"

// SyntaxKit
#import "SKAttributedParser.h"
#import "SKRange.h"
#import "XXTEEditorSyntaxCache.h"

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


static NSUInteger const kXXTEEditorCachedRangeLengthCompact = 1024 * 30;  // 30k

@interface XXTEEditorController () <UIScrollViewDelegate, NSTextStorageDelegate, XXTEEditorSearchBarDelegate, XXTEEditorSearchAccessoryViewDelegate, XXTEKeyboardToolbarRowDelegate, XXTEKeyboardButtonDelegate>

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
@property (atomic, strong) XXTEEditorSyntaxCache *syntaxCache;

@property (nonatomic, assign) NSUInteger initialNumberOfLines;

@property (nonatomic, assign) BOOL shouldReopenDocument;
@property (nonatomic, assign) BOOL shouldSaveDocument;
@property (nonatomic, assign) BOOL shouldReloadAttributes;
@property (nonatomic, assign) BOOL shouldResetAttributes;
@property (nonatomic, assign) BOOL shouldFocusTextView;
@property (nonatomic, assign) BOOL shouldEraseAllLineMasks;
@property (nonatomic, assign) BOOL shouldReloadTextViewWidth;
@property (nonatomic, assign) BOOL shouldReloadNagivationBar;

@property (nonatomic, assign) BOOL shouldReloadAll;
@property (nonatomic, strong) NSMutableArray <NSString *> *defaultsKeysToReload;

@property (nonatomic, assign) BOOL shouldHighlightRange;
@property (nonatomic, assign) NSRange highlightRange;
@property (nonatomic, assign, getter=isHighlightEnabled) BOOL highlightEnabled;

@property (nonatomic, strong) XXTEEditorSearchBar *searchBar;
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *closedSearchBarConstraints;
@property (nonatomic, strong) NSArray <NSLayoutConstraint *> *expandedSearchBarConstraints;

@end

@implementation XXTEEditorController {
    BOOL isFirstTimeAppeared;
    BOOL isFirstLayout;
    BOOL isRendering;
    BOOL isParsing;
    BOOL _lockedState;
}

@synthesize entryPath = _entryPath;
@synthesize textView = _textView;
@synthesize maskView = _maskView;
@synthesize toolbar = _toolbar;
@synthesize searchMode = _searchMode;

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
    
    _shouldReloadAttributes = NO;
    _shouldResetAttributes = NO;
    _shouldReopenDocument = NO;
    _shouldSaveDocument = NO;
    _shouldFocusTextView = NO;
    _shouldHighlightRange = NO;
    
    _defaultsKeysToReload = [NSMutableArray array];
    _shouldReloadTextViewWidth = NO;
    _shouldReloadNagivationBar = NO;
    _shouldEraseAllLineMasks = NO;
    _lockedState = NO;
    
    isFirstTimeAppeared = NO;
    isFirstLayout = NO;
    isRendering = NO;
    isParsing = NO;
    
    NSInteger encodingIndex = XXTEDefaultsInt(XXTExplorerDefaultEncodingKey, 0);
    CFStringEncoding encoding = [XXTEEncodingHelper encodingAtIndex:encodingIndex];
    _currentEncoding = encoding;
    _currentLineBreak = NSStringLineBreakTypeLF;
    _keyboardFrame = CGRectNull;
    
    [self registerUndoNotifications];
}

- (void)preloadDefaults {
    NSMutableArray <NSString *> *keysToReload = self.defaultsKeysToReload;
    
    // Language
    BOOL languageReloaded = NO;
    if (!self.language) {
        // TODO: reload language definition
        NSString *entryExtension = [self.entryPath pathExtension];
        if (entryExtension.length > 0)
        {
            XXTEEditorLanguage *language = [[XXTEEditorLanguage alloc] initWithExtension:entryExtension];
            if (!language) { // no such language?
                
            }
            _language = language;
            languageReloaded = YES;
        }
        else
        {
            _language = nil;
            languageReloaded = YES;
        }
        [keysToReload addObject:XXTEEditorLanguageReloaded];
    }
    
    // Font
    UIFont *themeFont = self.theme.font;
    if (!themeFont || [keysToReload containsObject:XXTEEditorFontName] || [keysToReload containsObject:XXTEEditorFontSize]) {
        static NSString * const XXTEDefaultFontName = @"Courier";
        NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, XXTEDefaultFontName);
        CGFloat fontSize = XXTEDefaultsDouble(XXTEEditorFontSize, 14.0);
        if (fontName) {
            themeFont = [UIFont fontWithName:fontName size:fontSize];
            if (!themeFont) { // not exists, new version?
                XXTEDefaultsSetObject(XXTEEditorFontName, nil); // reset font
                themeFont = [UIFont fontWithName:XXTEDefaultFontName size:fontSize];
            }
        }
        [keysToReload addObject:XXTEEditorThemeName];  // if font changes, theme must be reloaded.
    }
    NSAssert(themeFont, @"Cannot load default font from system.");
    
    // Theme
    if (!self.theme || [keysToReload containsObject:XXTEEditorThemeName]) {
        static NSString * const XXTEDefaultThemeName = @"Tomorrow Night";
        NSString *themeName = XXTEDefaultsObject(XXTEEditorThemeName, XXTEDefaultThemeName);
        if (themeName && themeFont)
        {
            XXTEEditorTheme *theme = [[XXTEEditorTheme alloc] initWithName:themeName baseFont:themeFont];
            if (!theme) { // not registered, new version?
                XXTEDefaultsSetObject(XXTEEditorThemeName, nil); // reset theme
                theme = [[XXTEEditorTheme alloc] initWithName:XXTEDefaultThemeName baseFont:themeFont];
            }
            _theme = theme;
        }
        else
        {
            _theme = nil;
        }
    }
    NSAssert(self.theme, @"Cannot load default theme from main bundle.");
    
    // Parser
    if (languageReloaded || [keysToReload containsObject:XXTEEditorThemeName]) {
        if (self.language.skLanguage && self.theme.skTheme)
        {
            SKAttributedParser *parser = [[SKAttributedParser alloc] initWithLanguage:self.language.skLanguage theme:self.theme.skTheme];
            if (!parser) {
                
            }
            _parser = parser;
            [self invalidateSyntaxCaches];
        }
        else
        {
            _parser = nil;
            [self invalidateSyntaxCaches];
        }
        [self setNeedsResetAttributes];
    }
}

- (void)reloadDefaults {
    if (![self isViewLoaded]) return;
    NSMutableArray <NSString *> *keysToReload = self.defaultsKeysToReload;
    
    // Main View
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        self.view.backgroundColor = self.theme.backgroundColor;
        self.view.tintColor = self.theme.foregroundColor;
    }
    
    // Title View
    if ([keysToReload containsObject:XXTEEditorSimpleTitleView]) {
        BOOL isSimpleTitle = XXTEDefaultsBool(XXTEEditorSimpleTitleView, (XXTE_IS_IPAD ? NO : YES));
        [self.lockedTitleView setSimple:isSimpleTitle];
    }
    if ([keysToReload containsObject:XXTEEditorReadOnly] || [keysToReload containsObject:XXTEEditorLockedStateChanged]) {
        BOOL shouldLocked = ([self isReadOnly] || [self isLockedState]);
        [self.lockedTitleView setLocked:shouldLocked];
    }
    
    // Search Bar
    if ([keysToReload containsObject:XXTEEditorThemeName] || [keysToReload containsObject:XXTEEditorSearchRegularExpression]) {
        BOOL useRegular = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
        self.searchBar.backgroundColor = self.theme.backgroundColor;
        self.searchBar.tintColor = self.theme.foregroundColor;
        self.searchBar.textColor = self.theme.foregroundColor;
        self.searchBar.separatorColor = [self.theme.foregroundColor colorWithAlphaComponent:0.2];
        [self.searchBar setRegexMode:useRegular];
        [self.searchBar updateView];
    }
    
    // Search Accessories
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        self.searchAccessoryView.tintColor = self.theme.foregroundColor;
    }
    
    // Text View
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        self.textView.tintColor = self.theme.caretColor;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.indicatorStyle = self.isDarkMode ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
    }
    if ([keysToReload containsObject:XXTEEditorReadOnly] || [keysToReload containsObject:XXTEEditorLockedStateChanged]) {
        BOOL shouldLocked = ([self isReadOnly] || [self isLockedState]);
        self.textView.editable = !shouldLocked;
    }
    if ([keysToReload containsObject:XXTEEditorAutoCapitalization]) {
        self.textView.autocapitalizationType = XXTEDefaultsEnum(XXTEEditorAutoCapitalization, UITextAutocapitalizationTypeNone);
    }
    if ([keysToReload containsObject:XXTEEditorAutoCorrection]) {
        self.textView.autocorrectionType = XXTEDefaultsEnum(XXTEEditorAutoCorrection, UITextAutocorrectionTypeNo);
    }
    if ([keysToReload containsObject:XXTEEditorSpellChecking]) {
        self.textView.spellCheckingType = XXTEDefaultsEnum(XXTEEditorSpellChecking, UITextSpellCheckingTypeNo);
    }
    if ([keysToReload containsObject:XXTEEditorSearchCircular]) {
        self.textView.circularSearch = XXTEDefaultsBool(XXTEEditorSearchCircular, YES);
    }
    if ([keysToReload containsObject:XXTEEditorKeyboardASCIIPreferred]) {
        self.textView.keyboardType = XXTEDefaultsBool(XXTEEditorKeyboardASCIIPreferred, NO) ? UIKeyboardTypeASCIICapable : UIKeyboardTypeDefault;
    }
    // Set the fucking smart types again
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 11.0, *)) {
        self.textView.smartDashesType = UITextSmartDashesTypeNo;
        self.textView.smartQuotesType = UITextSmartQuotesTypeNo;
        self.textView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    } else {
        // Fallback on earlier versions
    }
    XXTE_END_IGNORE_PARTIAL
    
    // Text View - Text Input Delegate
    self.textView.vTextInput.inputLanguage = self.language;
    self.textView.vTextInput.inputMaskView = self.maskView;
    if ([keysToReload containsObject:XXTEEditorAutoIndent]) {
        self.textView.vTextInput.autoIndent = XXTEDefaultsBool(XXTEEditorAutoIndent, YES);
    }
    if ([keysToReload containsObject:XXTEEditorAutoBrackets]) {
        self.textView.vTextInput.autoBrackets = XXTEDefaultsBool(XXTEEditorAutoBrackets, YES);
    }
    
    // Tab Width
    if ([keysToReload containsObject:XXTEEditorTabWidth] || [keysToReload containsObject:XXTEEditorThemeName]) {
        NSUInteger tabWidthEnum = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4);
        CGFloat tabWidth = tabWidthEnum * self.theme.fontSpaceWidth;
        // Text View - Type Setter
        if (self.textView.vTypeSetter) {
            [self.textView.vTypeSetter setTabWidth:tabWidth];
        }
    }
    
    BOOL shouldInvalidateTextViewLayouts = NO;
    if ([keysToReload containsObject:XXTEEditorInitialNumberOfLinesChanged]) {
        [self.textView.vLayoutManager setNumberOfDigits:GetNumberOfDigits(self.initialNumberOfLines)];
        shouldInvalidateTextViewLayouts = YES;
    }
    if ([keysToReload containsObject:XXTEEditorLineNumbersEnabled]) {
        BOOL isLineNumbersEnabled = XXTEDefaultsBool(XXTEEditorLineNumbersEnabled, (XXTE_IS_IPAD ? YES : NO));
        [self.textView setShowLineNumbers:isLineNumbersEnabled];
        [self.textView.vLayoutManager setShowLineNumbers:isLineNumbersEnabled];
        shouldInvalidateTextViewLayouts = YES;
    }
    if ([keysToReload containsObject:XXTEEditorShowInvisibleCharacters]) {
        BOOL showInvisibleCharacters = XXTEDefaultsBool(XXTEEditorShowInvisibleCharacters, NO);
        [self.textView.vLayoutManager setShowInvisibleCharacters:showInvisibleCharacters];
        shouldInvalidateTextViewLayouts = YES;
    }
    if ([keysToReload containsObject:XXTEEditorIndentWrappedLines]) {
        BOOL indentWrappedLines = XXTEDefaultsBool(XXTEEditorIndentWrappedLines, YES);
        [self.textView.vLayoutManager setIndentWrappedLines:indentWrappedLines];
        shouldInvalidateTextViewLayouts = YES;
    }
    if ([keysToReload containsObject:XXTEEditorTabWidth] || [keysToReload containsObject:XXTEEditorThemeName]) {
        NSUInteger tabWidthEnum = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4);
        CGFloat tabWidth = tabWidthEnum * self.theme.fontSpaceWidth;
        [self.textView.vLayoutManager setTabWidth:tabWidth];
        shouldInvalidateTextViewLayouts = YES;
    }
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        UIColor *bulletColor = [self.theme.foregroundColor colorWithAlphaComponent:.12];
        UIColor *gutterColor = [self.theme.foregroundColor colorWithAlphaComponent:.25];
        UIColor *gutterBackgroundColor = [self.theme.foregroundColor colorWithAlphaComponent:.033];
        
        [self.textView setGutterLineColor:gutterColor];
        [self.textView setGutterBackgroundColor:gutterBackgroundColor];
        [self.textView.vLayoutManager setLineNumberFont:self.theme.font];
        [self.textView.vLayoutManager setLineNumberColor:gutterColor];
        [self.textView.vLayoutManager setBulletColor:bulletColor];
        [self.textView.vLayoutManager setInvisibleFont:self.theme.font];
        [self.textView.vLayoutManager setInvisibleColor:self.theme.invisibleColor];
        [self.textView.vLayoutManager setFontLineHeight:self.theme.fontLineHeight];
        [self.textView.vLayoutManager setLineHeightScale:self.theme.lineHeightScale];
        [self.textView.vLayoutManager setBaseLineOffset:self.theme.baseLineOffset];
    }
    
    // Layouts
    if (shouldInvalidateTextViewLayouts) {
        [self.textView setNeedsReloadContainerInsets];
        [self.textView.vLayoutManager invalidateLayout];
    }
    
    // Keyboard Row
    if ([keysToReload containsObject:XXTEEditorLanguageReloaded]) {
        self.keyboardRow = ({
            [[XXTEKeyboardRow alloc] initWithKeymap:self.language.keymap];
        });
    }
    if ([keysToReload containsObject:XXTEEditorSoftTabs] || [keysToReload containsObject:XXTEEditorTabWidth]) {
        BOOL softTabEnabled = XXTEDefaultsBool(XXTEEditorSoftTabs, NO);
        NSUInteger tabWidthEnum = XXTEDefaultsEnum(XXTEEditorTabWidth, XXTEEditorTabWidthValue_4);
        NSString *tabWidthString = [@"" stringByPaddingToLength:tabWidthEnum withString:@" " startingAtIndex:0];
        if (softTabEnabled) {
            self.keyboardRow.tabString = tabWidthString;
            self.textView.vTextInput.tabWidthString = tabWidthString;
        } else {
            self.keyboardRow.tabString = @"\t";
            self.textView.vTextInput.tabWidthString = @"\t";
        }
    }
    
    // Keyboard Toolbar Row
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        self.keyboardToolbarRow.tintColor = self.theme.foregroundColor;
    }
    if ([keysToReload containsObject:XXTEEditorReadOnly] || [keysToReload containsObject:XXTEEditorLockedStateChanged]) {
        BOOL shouldLocked = ([self isReadOnly] || [self isLockedState]);
        self.keyboardToolbarRow.snippetItem.enabled = (self.language && !shouldLocked);
    }
    if (XXTE_IS_IPAD) {
        self.searchBar.searchKeyboardAppearance = UIKeyboardAppearanceLight;
        self.searchBar.replaceKeyboardAppearance = UIKeyboardAppearanceLight;
        self.searchAccessoryView.barStyle = UIBarStyleDefault;
        self.textView.keyboardAppearance = UIKeyboardAppearanceLight;
        
        [self.keyboardRow setColorStyle:XXTEKeyboardRowStyleLight];
        [self.keyboardToolbarRow setStyle:XXTEKeyboardToolbarRowStyleLight];
    } else {
        if ([keysToReload containsObject:XXTEEditorThemeName]) {
            if (![self isDarkMode]) {
                self.searchBar.searchKeyboardAppearance = UIKeyboardAppearanceLight;
                self.searchBar.replaceKeyboardAppearance = UIKeyboardAppearanceLight;
                self.searchAccessoryView.barStyle = UIBarStyleDefault;
                self.textView.keyboardAppearance = UIKeyboardAppearanceLight;
                
                [self.keyboardRow setColorStyle:XXTEKeyboardRowStyleLight];
                [self.keyboardToolbarRow setStyle:XXTEKeyboardToolbarRowStyleLight];
            } else {
                self.searchBar.searchKeyboardAppearance = UIKeyboardAppearanceDark;
                self.searchBar.replaceKeyboardAppearance = UIKeyboardAppearanceDark;
                self.searchAccessoryView.barStyle = UIBarStyleBlack;
                self.textView.keyboardAppearance = UIKeyboardAppearanceDark;
                
                [self.keyboardRow setColorStyle:XXTEKeyboardRowStyleDark];
                [self.keyboardToolbarRow setStyle:XXTEKeyboardToolbarRowStyleDark];
            }
        }
    }
    
    // Config Keyboard Rows
    if ([keysToReload containsObject:XXTEEditorReadOnly] || [keysToReload containsObject:XXTEEditorKeyboardRowAccessoryEnabled]) {
        BOOL isReadOnlyMode = [self isReadOnly];
        BOOL isKeyboardRowEnabled = XXTEDefaultsBool(XXTEEditorKeyboardRowAccessoryEnabled, NO); // config
        if (isReadOnlyMode) {
            [self.keyboardRow setTextInput:nil];
            [self.keyboardRow setActionDelegate:nil];
            [self.textView setInputAccessoryView:nil];
        } else {
            if (XXTE_IS_IPAD && XXTE_SYSTEM_9) {
                [self.keyboardRow setTextInput:nil];
                [self.keyboardRow setActionDelegate:nil];
                [self.textView setInputAccessoryView:nil];
            } else {
                if (isKeyboardRowEnabled) {
                    [self.keyboardRow setTextInput:self.textView];
                    [self.keyboardRow setActionDelegate:self];
                    [self.textView setInputAccessoryView:self.keyboardRow];
                } else {
                    [self.keyboardRow setTextInput:nil];
                    [self.keyboardRow setActionDelegate:nil];
                    [self.textView setInputAccessoryView:self.keyboardToolbarRow];
                }
            }
        }
    }
    
    // Mask
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        self.maskView.flashColor = self.theme.caretColor;
    }
    
    // Bottom Bar
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        self.toolbar.tintColor = self.theme.barTextColor;
        self.toolbar.barTintColor = self.theme.barTintColor;
        for (UIBarButtonItem *item in self.toolbar.items) {
            item.tintColor = self.theme.barTextColor;
        }
    }
    
    // Bottom Buttons
    [self.launchButtonItem setEnabled:[self isLaunchItemAvailable]];
    [self.searchButtonItem setEnabled:[self isSearchButtonItemAvailable]];
    [self.symbolsButtonItem setEnabled:[self isSymbolsButtonItemAvailable]];
    [self.statisticsButtonItem setEnabled:[self isStatisticsButtonItemAvailable]];
    [self.settingsButtonItem setEnabled:[self isSettingsButtonItemAvailable]];
    
    // Locked State
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        self.actionView.titleLabel.textColor = self.theme.foregroundColor ?: [UIColor blackColor];
        self.actionView.descriptionLabel.textColor = self.theme.foregroundColor ?: [UIColor blackColor];
        if (![self isDarkMode]) {
            self.actionView.iconImageView.image = [UIImage imageNamed:@"XXTEBugIcon"];
        } else {
            self.actionView.iconImageView.image = [UIImage imageNamed:@"XXTEBugIconLight"];
        }
    }
    
    if ([self isLockedState]) {
        if (![self.view.subviews containsObject:self.actionView]) {
            [self.view addSubview:self.actionView];
        }
        if (self.textView.hidden == NO) {
            [self.textView setHidden:YES];
        }
    } else {
        if (self.textView.hidden == YES) {
            [self.textView setHidden:NO];
        }
        [self.actionView removeFromSuperview];
    }
    
    // Shared Menu
    if ([keysToReload containsObject:XXTEEditorReadOnly] || [keysToReload containsObject:XXTEEditorLockedStateChanged]) {
        BOOL shouldLocked = ([self isReadOnly] || [self isLockedState]);
        
        if (!shouldLocked && self.language) {
            [self registerMenuActions];
        } else {
            [self dismissMenuActions];
        }
    }
    
    // Auto Word Wrap
    if ([keysToReload containsObject:XXTEEditorAutoWordWrap] || [keysToReload containsObject:XXTEEditorWrapColumn]) {
        [self setNeedsReloadTextViewWidth];
    }
    
    // Attributes Related
    if ([keysToReload containsObject:XXTEEditorFontName] ||
        [keysToReload containsObject:XXTEEditorFontSize] ||
        [keysToReload containsObject:XXTEEditorThemeName] ||
        [keysToReload containsObject:XXTEEditorHighlightEnabled])
    {
        [self setNeedsReloadAttributes];
    }
    
    // Redraw Text View
    if (
        shouldInvalidateTextViewLayouts ||
        [keysToReload containsObject:XXTEEditorFontName] ||
        [keysToReload containsObject:XXTEEditorFontSize] ||
        [keysToReload containsObject:XXTEEditorHighlightEnabled] ||
        [keysToReload containsObject:XXTEEditorAutoWordWrap] ||
        [keysToReload containsObject:XXTEEditorWrapColumn]
        )
    {
        [self.textView setNeedsDisplay];
    }
    
    // Line Masks Related
    if ([keysToReload containsObject:XXTEEditorFontName] ||
        [keysToReload containsObject:XXTEEditorFontSize] ||
        [keysToReload containsObject:XXTEEditorLineNumbersEnabled] ||
        [keysToReload containsObject:XXTEEditorIndentWrappedLines] ||
        [keysToReload containsObject:XXTEEditorAutoWordWrap] ||
        [keysToReload containsObject:XXTEEditorWrapColumn]
        )
    {
        [self setNeedsEraseAllLineMasks];
    }
    
    // Navigation Bar
    if ([keysToReload containsObject:XXTEEditorThemeName]) {
        [self setNeedsReloadNavigationBar];
    }
    
    [keysToReload removeAllObjects];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _configure];
    
    [self updateControllerTitles];
    [self reloadAllImmediately];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewControllerWillChangeDisplayMode:) name:XXTENotificationEvent object:self.splitViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    // Save Document
    [self saveDocumentIfNecessary];
    
    // Notifications
    [self registerStateNotifications];
    [self registerKeyboardNotifications];
    
    // Navigation Bar
    [self renderNavigationBarTheme:NO];
    
    // Reload Defaults
    if (isFirstTimeAppeared) {
        if (self.shouldReopenDocument) {
            [self reopenDocumentIfNecessary];
        } else {
            [self preloadDefaults];
            [self reloadDefaults];
            [self reloadTextViewWidthIfNecessary];
            [self reloadNavigationBarIfNecessary];
            [self reloadAttributesIfNecessary];
        }
    }
    [self eraseAllLineMasksIfNecessary];
    
    // Super
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    // Super
    [super viewDidAppear:animated];
    
    // Hmmm...
    if (isFirstTimeAppeared) {
        [self reloadNavigationBarIfNecessary];
        [self reloadAttributesIfNecessary];
        [self fillAllLineMasks];
    }
    
    // Focus Symbol
    if (self.shouldHighlightRange) {
        [self highlightRangeIfNecessary];
    } else {
        [self focusTextViewIfNecessary];
    }
    
    isFirstTimeAppeared = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    // Notifications
    [self dismissKeyboardNotifications];
    [self dismissStateNotifications];
    
    // Super
    [super viewWillDisappear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    // Navigation Bar
    if (parent == nil) {
        [self renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    // Save Documents
    if (parent == nil) {
        self.parser.aborted = YES;
        [self saveDocumentIfNecessary];
    }
    [super didMoveToParentViewController:parent];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (!isFirstLayout) {
        [self setNeedsReloadTextViewWidth];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!isFirstLayout) {
        [self fixTextViewInsets];
        [self reloadTextViewWidthIfNecessary];
        isFirstLayout = YES;
    } else {
        [self reloadTextViewWidthIfNecessary];
    }
}

- (void)viewControllerWillChangeDisplayMode:(NSNotification *)aNotification
{
    NSDictionary *userInfo = aNotification.userInfo;
    if ([userInfo[XXTENotificationEventType] isEqualToString:XXTENotificationEventTypeSplitViewControllerWillChangeDisplayMode])
    {
        [self fixTextViewInsets];
        [self setNeedsReloadTextViewWidth];
    }
}

#pragma mark - Interface: Layouts

- (void)_configure {
    self.navigationItem.leftItemsSupplementBackButton = NO;
    self.navigationItem.hidesBackButton = YES;
    
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    self.navigationItem.leftBarButtonItems = @[self.myBackButtonItem];
    if (isOS9Above() && isAppStore()) {
        self.navigationItem.rightBarButtonItems = @[self.launchButtonItem, self.shareButtonItem];
    } else {
        self.navigationItem.rightBarButtonItems = @[self.shareButtonItem];
    }
    self.navigationItem.titleView = self.lockedTitleView;
    
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
    
    [self setNeedsReloadAll];
}

#pragma mark - Interface: Titles

- (void)updateControllerTitles {
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    self.lockedTitleView.title = self.title;
    self.lockedTitleView.subtitle = XXTTiledPath(self.entryPath);
}

#pragma mark - Interface: Rotation

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self setNeedsReloadTextViewWidth];
    [self setNeedsEraseAllLineMasks];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     { // usually on iPad
        [self fixTextViewInsets];
        [self reloadTextViewWidthIfNecessary];
        [self eraseAllLineMasksIfNecessary];
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
        [self fillAllLineMasks];
     }];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
    XXTE_END_IGNORE_PARTIAL
}

XXTE_START_IGNORE_PARTIAL
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self setNeedsReloadTextViewWidth];
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (XXTE_SYSTEM_8) {
        
    } else { // to be compatible with iOS 7
        [self setNeedsReloadTextViewWidth];
    }
}
XXTE_END_IGNORE_PARTIAL

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

- (XXTEEditorSearchBar *)searchBar {
    if (!_searchBar) {
        XXTEEditorSearchBar *searchBar = [[XXTEEditorSearchBar alloc] init];
        if (@available(iOS 13.0, *)) {
            searchBar.backgroundColor = [UIColor systemBackgroundColor];
        } else {
            searchBar.backgroundColor = [UIColor whiteColor];
        }
        searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        searchBar.hidden = YES;
        searchBar.searchInputAccessoryView = self.searchAccessoryView;
        searchBar.replaceInputAccessoryView = self.searchAccessoryView;
        searchBar.delegate = self;
        _searchBar = searchBar;
    }
    return _searchBar;
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
        textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
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
        XXTEEditorMaskView *maskView = [[XXTEEditorMaskView alloc] initWithTextView:self.textView];
        [maskView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [maskView setLineMaskColor:[UIColor clearColor] forType:XXTEEditorLineMaskNone];
        [maskView setLineMaskColor:XXTColorFixed() forType:XXTEEditorLineMaskInfo];
        [maskView setLineMaskColor:XXTColorSuccess() forType:XXTEEditorLineMaskSuccess];
        [maskView setLineMaskColor:XXTColorWarning() forType:XXTEEditorLineMaskWarning];
        [maskView setLineMaskColor:XXTColorDanger() forType:XXTEEditorLineMaskError];
        _maskView = maskView;
    }
    return _maskView;
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
        XXTEEditorToolbar *toolbar = [[XXTEEditorToolbar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 44.0, CGRectGetWidth(self.view.bounds), 44.0)];
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

- (BOOL)isReadOnly {
    return XXTEDefaultsBool(XXTEEditorReadOnly, NO);
}

- (BOOL)isLockedState {
    return _lockedState;
}

- (BOOL)isHighlightEnabled {
    _highlightEnabled = _hasLongLine == NO && XXTEDefaultsBool(XXTEEditorHighlightEnabled, YES) == YES;
    return _highlightEnabled;
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
        NSRange textRange = NSMakeRange(0, text.length);
        
        NSUInteger s, e;
        [text getLineStart:&s end:NULL contentsEnd:&e forRange:editedRange];
        NSRange lineRange = NSMakeRange(s, e - s);
        NSRange visibleRange = [self.textView visibleRange];
        if (NO == NSRangeEntirelyContains(visibleRange, lineRange)) {
            visibleRange = NSUnionRange(visibleRange, lineRange);
        }
        NSRange renderRange = NSIntersectionRange(visibleRange, textRange);
        
        NSDictionary *d = self.theme.defaultAttributes;
        [textStorage setAttributes:d range:renderRange];
        [textStorage fixAttributesInRange:renderRange];
        [self.parser attributedParseString:text inRange:renderRange matchCallback:^(NSString *scopeName, NSRange range, SKAttributes attributes) {
            if (attributes) {
                [textStorage addAttributes:attributes range:range];
                [textStorage fixAttributesInRange:range];
            }
        }];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self scrollViewDidFinishScrolling:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollViewDidFinishScrolling:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidFinishScrolling:scrollView];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self scrollViewDidFinishScrolling:scrollView];
}

- (void)scrollViewDidFinishScrolling:(UIScrollView *)scrollView {
    if (scrollView == self.textView) {
        [self renderSyntaxTextAttributesOnScreen];
    } else if (scrollView == self.containerView) {
        
    }
}

#pragma mark - XXTEEncodingControllerDelegate

#ifdef APPSTORE
- (void)encodingControllerDidConfirm:(XXTEEncodingController *)controller shouldSave:(BOOL)save
{
    [self setCurrentEncoding:controller.selectedEncoding];
    if (save) {
        [self setNeedsSaveDocument];
    }
    [self setNeedsReopenDocument];
    [controller dismissViewControllerAnimated:YES completion:^{
        if (!XXTE_IS_FULLSCREEN(controller)) {
            [self reopenDocumentIfNecessary];
        }
    }];
}
#endif

#ifdef APPSTORE
- (void)encodingControllerDidChange:(XXTEEncodingController *)controller shouldSave:(BOOL)save
{
    [self setCurrentEncoding:controller.selectedEncoding];
    if (save) {
        [self setNeedsSaveDocument];
    }
    [self setNeedsReopenDocument];
}
#endif

#ifdef APPSTORE
- (void)encodingControllerDidCancel:(XXTEEncodingController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
#endif

#pragma mark - Editor: Locked State

#ifdef APPSTORE
- (void)actionViewTapped:(XXTESingleActionView *)actionView {
    XXTEEncodingController *controller = [[XXTEEncodingController alloc] initWithStyle:UITableViewStylePlain];
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

#pragma mark - Editor: Content

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
    NSString *string = [XXTETextPreprocessor preprocessedStringWithContentsOfFile:entryPath NumberOfLines:&numberOfLines Encoding:&tryEncoding LineBreak:&tryLineBreak MaximumLength:NULL Error:&readError];
    if (!string) {
        _lockedState = YES;
        if ([readError.domain isEqualToString:kXXTErrorInvalidStringEncodingDomain]) {
            self.actionView.titleLabel.text = NSLocalizedString(@"Bad Encoding", nil);
#ifdef APPSTORE
            self.actionView.descriptionLabel.text = readError ? [NSString stringWithFormat:NSLocalizedString(@"%@\nTap here to change encoding.", nil), readError.localizedDescription] : NSLocalizedString(@"Unknown reason.", nil);
#else
            self.actionView.descriptionLabel.text = readError.localizedDescription ?: NSLocalizedString(@"Unknown reason.", nil);
#endif
        } else {
            self.actionView.titleLabel.text = NSLocalizedString(@"Error", nil);
            self.actionView.descriptionLabel.text = readError.localizedDescription ?: NSLocalizedString(@"Unknown reason.", nil);
        }
    } else {
        _lockedState = NO;
    }
    
    [self setInitialNumberOfLines:numberOfLines];
    [self setCurrentEncoding:tryEncoding];
    [self setCurrentLineBreak:tryLineBreak];
    [self setHasLongLine:[XXTETextPreprocessor stringHasLongLine:string LineBreak:NSStringLineBreakTypeLF]];
    
    [self setNeedsReload:XXTEEditorLockedStateChanged];
    [self setNeedsReload:XXTEEditorInitialNumberOfLinesChanged];
    
    return string;
}

- (void)reloadContent:(NSString *)content {
    if (![self isViewLoaded]) return;
    if (!content) return;
    
    BOOL isLockedState = self.isLockedState;
    BOOL isReadOnlyMode = self.isReadOnly;
    [self resetSearch];
    
    XXTEEditorTheme *theme = self.theme;
    XXTEEditorTextView *textView = self.textView;
    
    [textView.undoManager disableUndoRegistration];
    
    [textView setEditable:NO];
    [textView setFont:theme.font];
    [textView setTextColor:theme.foregroundColor];
    [textView setText:content];
    [textView setEditable:(isReadOnlyMode == NO && isLockedState == NO)];
    
    [textView.undoManager enableUndoRegistration];  // enable undo
    
    XXTEKeyboardToolbarRow *keyboardToolbarRow = self.keyboardToolbarRow;
    keyboardToolbarRow.redoItem.enabled = NO;
    keyboardToolbarRow.undoItem.enabled = NO;
    
    [textView.undoManager removeAllActions];  // reset undo manager
    [self invalidateSyntaxCaches];
}

#pragma mark - Editor: Render Engine

- (void)reloadAttributes {
    if (![self isViewLoaded]) return;
    if ([self isLockedState]) return;
    if ([self isHighlightEnabled]) {
        [self resetThemeTextAttributesOnScreen];
        
#ifdef DEBUG
        NSLog(@"start parsing (full)...");
#endif
        if (isParsing) return;
        isParsing = YES;
        
        NSString *wholeString = self.textView.text;
        UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 1.0);
        @weakify(self);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @strongify(self);
            NSMutableArray *rangesArray = [[NSMutableArray alloc] init];
            NSMutableArray *attributesArray = [[NSMutableArray alloc] init];
            [self.parser attributedParseString:wholeString matchCallback:^(NSString * _Nonnull scope, NSRange range, NSDictionary <NSString *, id> * _Nullable attributes) {
                if (attributes) {
                    [rangesArray addObject:[NSValue valueWithRange:range]];
                    [attributesArray addObject:attributes];
                }
            }];
            dispatch_async_on_main_queue(^{
                self->isParsing = NO;
                
                XXTEEditorSyntaxCache *syntaxCache = [[XXTEEditorSyntaxCache alloc] init];
                syntaxCache.referencedParser = self.parser;
                syntaxCache.text = wholeString;
                syntaxCache.rangesArray = rangesArray;
                syntaxCache.attributesArray = attributesArray;
                syntaxCache.renderedSet = [[NSMutableIndexSet alloc] init];
                [self setSyntaxCache:syntaxCache];
                [self renderSyntaxTextAttributesOnScreen];
                blockInteractions(blockVC, NO);
            });
        });
    } else {
        [self invalidateSyntaxCaches];
        [self resetAttributesIfNecessary];
    }
}

// TODO: calculate screen range more efficiently
- (NSRange)rangeShouldRenderOnScreen {
    XXTEEditorTextView *textView = self.textView;
    NSUInteger textLength = textView.text.length;
    
    CGRect bounds = textView.bounds;
    UITextPosition *start = [textView characterRangeAtPoint:bounds.origin].start;
    UITextPosition *end = [textView characterRangeAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))].end;
    
    NSInteger beginOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:start];
    beginOffset -= kXXTEEditorCachedRangeLengthCompact;
    if (beginOffset < 0) beginOffset = 0;
    NSInteger endLength = [textView offsetFromPosition:start toPosition:end];
    endLength += kXXTEEditorCachedRangeLengthCompact;
    if (beginOffset + endLength > 0 + textLength) endLength = 0 + textLength - beginOffset;
    
    NSRange range = NSMakeRange((NSUInteger) beginOffset, (NSUInteger) endLength);
    return range;
}

// theme-related attributes
- (void)resetThemeTextAttributes {
    if (isRendering) return;
    if ([self isLockedState]) return;
    
#ifdef DEBUG
    NSLog(@"reset attributes (full)...");
#endif
    
    NSTextStorage *vStorage = self.textView.vTextStorage;
    NSDictionary *defaultAttributes = self.theme.defaultAttributes;
    
    [vStorage beginEditing];
    [vStorage setAttributes:defaultAttributes range:NSMakeRange(0, vStorage.length)];
    [vStorage endEditing];
}

// theme-related attributes
- (void)resetThemeTextAttributesOnScreen {
    if (isRendering) return;
    if ([self isLockedState]) return;
    
#ifdef DEBUG
    NSLog(@"reset attributes (screen)...");
#endif
    
    NSTextStorage *vStorage = self.textView.vTextStorage;
    NSDictionary *defaultAttributes = self.theme.defaultAttributes;
    
    NSRange range = [self rangeShouldRenderOnScreen];
    [vStorage beginEditing];
    [vStorage setAttributes:defaultAttributes range:range];
    [vStorage endEditing];
}

// parser-related syntax attributes (cached)
- (void)renderSyntaxTextAttributesOnScreen {
    if ([self.parser aborted]) return;
    if ([self isLockedState]) return;
    if (![self isHighlightEnabled]) return;
    if (![self _isValidSyntaxCache]) return;
    
    XXTEEditorSyntaxCache *cache = self.syntaxCache;
    NSArray *rangesArray = cache.rangesArray;
    NSArray *attributesArray = cache.attributesArray;
    NSMutableIndexSet *renderedSet = cache.renderedSet;
    
    NSDictionary *defaultAttributes = self.theme.defaultAttributes;
    XXTEEditorTextView *textView = self.textView;
    NSTextStorage *vStorage = textView.vTextStorage;
    
    NSRange range = [self rangeShouldRenderOnScreen];
    
    if ([renderedSet containsIndexesInRange:range]) return;
    [renderedSet addIndexesInRange:range];
    
    NSUInteger rangesArrayLength = rangesArray.count;
    NSUInteger attributesArrayLength = attributesArray.count;
    if (rangesArrayLength != attributesArrayLength) return;
    
    if (isRendering) return;
    isRendering = YES;
    
#ifdef DEBUG
    NSLog(@"start rendering (screen)...");
#endif
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @strongify(self);
        
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
                [vStorage setAttributes:defaultAttributes range:range];
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
        
        self->isRendering = NO;
    });
}

- (BOOL)_isValidSyntaxCache {
    if (![self _hasSyntaxCache]) {
        return NO;
    }
    if (self.syntaxCache.referencedParser == nil || self.parser == nil) {
        return NO;
    }
    if ([self.syntaxCache.referencedParser isEqual:self.parser] &&
        [self.syntaxCache.text isEqualToString:self.textView.text]) {
        return YES;
    }
    return NO;
}

- (BOOL)_hasSyntaxCache {
    return (self.syntaxCache != nil);
}

- (void)invalidateSyntaxCaches {
    // NSAssert([NSThread isMainThread], @"- [%@ invalidateSyntaxCaches] called in non-main thread!", NSStringFromClass([self class]));
    if ([self _hasSyntaxCache]) {
        self.syntaxCache = nil;
        [self setNeedsResetAttributes];
    }
}

- (void)invalidateSyntaxCachesIfInvalid {
    // NSAssert([NSThread isMainThread], @"- [%@ invalidateSyntaxCachesIfNeeded] called in non-main thread!", NSStringFromClass([self class]));
    if ([self _isValidSyntaxCache]) {
        return;
    }
    [self invalidateSyntaxCaches];
}

#pragma mark - Editor: Search

- (void)resetSearch {
    {
        if ([self.searchBar isFirstResponder]) {
            [self.searchBar resignFirstResponder];
        }
        NSUInteger beginLocation = self.textView.selectedRange.location;
        [self.textView resetSearch];
        [self.textView setSearchIndex:beginLocation];
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

- (void)searchNextMatch
{
    NSString *target = self.searchBar.searchText;
    [self searchMatch:target inDirection:ICTextViewSearchDirectionForward];
}

- (void)replaceNextMatch
{
    // NSString *target = self.searchBar.searchText;
    NSString *replacement = self.searchBar.replaceText;
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
        [self searchNextMatch];
    } else {
        // cannot find matching contents
    }
}

- (void)replaceAllMatches
{
    NSString *target = self.searchBar.searchText;
    NSString *replacement = self.searchBar.replaceText;
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
                [self reloadAttributesIfNecessary];
            }
        }
        else
        {
            NSString *newString = [text stringByReplacingOccurrencesOfString:target withString:replacement options:searchOptions range:textRange];
            [textView setText:newString];
            [self reloadAttributesIfNecessary];
        }
        [self searchNextMatch];
    }
}

- (void)searchPreviousMatch
{
    NSString *target = self.searchBar.searchText;
    [self searchMatch:target inDirection:ICTextViewSearchDirectionBackward];
}

- (void)searchMatch:(NSString *)target inDirection:(ICTextViewSearchDirection)direction
{
    BOOL caseSensitive = XXTEDefaultsBool(XXTEEditorSearchCaseSensitive, NO);
    if (!caseSensitive) {
        self.textView.searchOptions = NSRegularExpressionCaseInsensitive;
    } else {
        self.textView.searchOptions = kNilOptions;
    }
    if (target.length) {
        BOOL isCircular = NO;
        NSUInteger currentIndex = self.textView.rangeOfFoundString.location;
        
        BOOL searchSucceed = NO;
        BOOL useRegular = XXTEDefaultsBool(XXTEEditorSearchRegularExpression, NO);
        if (useRegular) {
            searchSucceed =
            [self.textView scrollToMatch:target searchDirection:direction];
        } else {
            searchSucceed =
            [self.textView scrollToString:target searchDirection:direction];
        }
        
        NSUInteger succeedIndex = self.textView.rangeOfFoundString.location;
        if (currentIndex != NSNotFound && succeedIndex != NSNotFound) {
            if (direction == ICTextViewSearchDirectionForward) {
                if (succeedIndex < currentIndex) {
                    isCircular = YES;
                }
            } else if (direction == ICTextViewSearchDirectionBackward) {
                if (succeedIndex > currentIndex) {
                    isCircular = YES;
                }
            }
        }
        
        if (searchSucceed) {
            NSRange foundRange = self.textView.rangeOfFoundString;
            if (foundRange.location != NSNotFound) {
                [self.textView setSelectedRange:foundRange];
            }
        }
        
        if (isCircular) {
            if (direction == ICTextViewSearchDirectionForward) {
                [self displayKeyboardTip:NSLocalizedString(@"From Top", nil)];
            } else if (direction == ICTextViewSearchDirectionBackward) {
                [self displayKeyboardTip:NSLocalizedString(@"From Bottom", nil)];
            }
        }
    } else {
        NSUInteger beginLocation = self.textView.selectedRange.location;
        [self.textView resetSearch];
        [self.textView setSearchIndex:beginLocation];
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
            if (!textView.circularSearch && idx == 0) {
                prevItem.enabled = NO;
                nextItem.enabled = YES;
            } else if (!textView.circularSearch && idx == numberOfMatches - 1) {
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

#pragma mark - Editor: Auto Word Wrap

- (void)fixTextViewInsets
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        // insets = self.view.safeAreaInsets;
    }
    UITextView *textView = self.textView;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(insets.top, insets.left, insets.bottom + kXXTEEditorToolbarHeight, insets.right);
    textView.contentInset = contentInsets;
    textView.scrollIndicatorInsets = contentInsets;
}

- (void)reloadTextViewWidth {
    if (![self isViewLoaded]) return;
    CGFloat newWidth = CGRectGetWidth(self.view.bounds);
    BOOL autoWrap = XXTEDefaultsBool(XXTEEditorAutoWordWrap, YES);
    if (NO == autoWrap) {
        NSInteger columnW = XXTEDefaultsInt(XXTEEditorWrapColumn, 120);
        if (columnW < 10 || columnW > 1000)
        {
            columnW = 120;
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

#pragma mark - Editor: Undo Manager

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
        }  // you may receive undoManager from TextField(s)
    }
}

#pragma mark - XXTEEditorSearchBarDelegate

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldReturn:(UITextField *)textField {
    [self searchNextMatch];
    return YES;
}

- (void)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldDidChange:(UITextField *)textField {
    [UIView cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchNextMatch) object:nil];
    [self performSelector:@selector(searchNextMatch) withObject:nil afterDelay:0.33];
//    [self searchNextMatch:searchBar.searchText];
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldShouldClear:(UITextField *)textField {
    [self searchNextMatch];
    return YES;
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldReturn:(UITextField *)textField {
    [self searchNextMatch];
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
    BOOL isReadOnlyMode = self.isReadOnly; // config
    [searchAccessoryView setAllowReplacement:(NO == isReadOnlyMode && NO == isLockedState)];
    [searchAccessoryView setReplaceMode:NO];
    [searchAccessoryView updateAccessoryView];
    NSUInteger beginLocation = self.textView.selectedRange.location;
    [self.textView setSearchIndex:beginLocation];
    [self searchNextMatch];
    return YES;
}

- (BOOL)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldShouldBeginEditing:(UITextField *)textField {
    XXTEEditorSearchAccessoryView *searchAccessoryView = self.searchAccessoryView;
    BOOL isLockedState = self.isLockedState;
    BOOL isReadOnlyMode = self.isReadOnly; // config
    [searchAccessoryView setAllowReplacement:(NO == isReadOnlyMode && NO == isLockedState)];
    [searchAccessoryView setReplaceMode:YES];
    [searchAccessoryView updateAccessoryView];
    NSUInteger beginLocation = self.textView.selectedRange.location;
    [self.textView setSearchIndex:beginLocation];
    [self searchNextMatch];
    return YES;
}

- (void)searchBar:(XXTEEditorSearchBar *)searchBar searchFieldDidEndEditing:(UITextField *)textField {
    
}

- (void)searchBar:(XXTEEditorSearchBar *)searchBar replaceFieldDidEndEditing:(UITextField *)textField {
    
}

- (void)searchBarDidCancel:(XXTEEditorSearchBar *)searchBar {
    [self resetSearch];
    [self closeSearchBar:nil animated:YES];
}

#pragma mark - XXTEEditorSearchAccessoryViewDelegate

- (void)searchAccessoryViewShouldMatchPrev:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self searchPreviousMatch];
}

- (void)searchAccessoryViewShouldMatchNext:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self searchNextMatch];
}

- (void)searchAccessoryViewShouldReplace:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self replaceNextMatch];
}

- (void)searchAccessoryViewShouldReplaceAll:(XXTEEditorSearchAccessoryView *)accessoryView {
    [self replaceAllMatches];
}

#pragma mark - XXTEKeyboardToolbarRowDelegate

- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapUndo:(UIBarButtonItem *)sender {
    [self performGlobalUndoAction:row];
}

- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapRedo:(UIBarButtonItem *)sender {
    [self performGlobalRedoAction:row];
}

- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapDismiss:(UIBarButtonItem *)sender {
    [self performGlobalKeyboardDismissalAction:row];
}

- (void)keyboardToolbarRow:(XXTEKeyboardToolbarRow *)row didTapSnippet:(UIBarButtonItem *)sender {
    [self performGlobalCodeBlocksAction:row];
}

- (void)searchAccessoryView:(XXTEEditorSearchAccessoryView *)accessoryView didTapDismiss:(UIBarButtonItem *)sender {
    [self performGlobalKeyboardDismissalAction:accessoryView];
}

#pragma mark - XXTEKeyboardButtonDelegate

- (void)keyboardButton:(XXTEKeyboardButton *)button didTriggerAction:(XXTEKeyboardButtonAction)action {
    switch (action) {
        case XXTEKeyboardButtonActionUndo:
            [self performGlobalUndoAction:button];
            break;
        case XXTEKeyboardButtonActionRedo:
            [self performGlobalRedoAction:button];
            break;
        case XXTEKeyboardButtonActionBackspace:
            [self performGlobalBackspaceAction:button];
            break;
        case XXTEKeyboardButtonActionKeyboardDismissal:
            [self performGlobalKeyboardDismissalAction:button];
            break;
        default:
            break;
    }
}

#pragma mark - Global Actions

- (void)displayKeyboardTip:(NSString *)tip {
    if (CGRectIsNull(self.keyboardFrame) || tip.length == 0) {
        return;
    }
    CGPoint textViewTipPosition = [self.view convertPoint:CGPointMake(CGRectGetWidth(self.toolbar.frame) / 2.0, CGRectGetMinY(self.toolbar.frame) - 36.0) toView:nil];
    toastMessageTip(self, tip, CGPointMake(CGRectGetWidth(self.keyboardFrame) / 2.0, MIN(CGRectGetMinY(self.keyboardFrame) - 36.0, textViewTipPosition.y)));
}

- (void)performGlobalUndoAction:(id)sender {
    NSUndoManager *undoManager = [self.textView undoManager];
    if (undoManager.canUndo) {
        [undoManager undo];
        [self displayKeyboardTip:NSLocalizedString(@"Undo", nil)];
    }
}

- (void)performGlobalRedoAction:(id)sender {
    NSUndoManager *undoManager = [self.textView undoManager];
    if (undoManager.canRedo) {
        [undoManager redo];
        [self displayKeyboardTip:NSLocalizedString(@"Redo", nil)];
    }
}

- (void)performGlobalBackspaceAction:(id)sender {
    if ([self.textView isFirstResponder]) {
        [self.textView deleteBackward];
    }
}

- (void)performGlobalSelectToLineBreakAction:(id)sender {
    
}

- (void)performGlobalKeyboardDismissalAction:(id)sender {
    BOOL dismissalSucceed = NO;
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
        dismissalSucceed = YES;
    }
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
        dismissalSucceed = YES;
    }
    if (dismissalSucceed) {
        [self displayKeyboardTip:NSLocalizedString(@"Keyboard Dismissal", nil)];
    }
}

- (void)performGlobalCodeBlocksAction:(id)sender {
    [self menuActionCodeBlocks:nil];
}

#pragma mark - Lazy Flags

- (NSArray <NSString *> *)defaultsKeysShouldPreload {
    return
    @[
      XXTEEditorFontName,
      XXTEEditorFontSize,
      XXTEEditorThemeName,
      XXTEEditorHighlightEnabled,
      ];
}

- (void)setNeedsReload:(NSString *)defaultKey {
    if (![self.defaultsKeysToReload containsObject:defaultKey]) {
        [self.defaultsKeysToReload addObject:defaultKey];
    }
}

- (void)setNeedsReloadAll {
    [self.defaultsKeysToReload removeAllObjects];
    [self.defaultsKeysToReload addObjectsFromArray:
  @[ XXTEEditorFontName,
     XXTEEditorFontSize,
     XXTEEditorThemeName,
     XXTEEditorHighlightEnabled,
     XXTEEditorSimpleTitleView,
     XXTEEditorFullScreenWhenEditing,
     XXTEEditorLineNumbersEnabled,
     XXTEEditorShowInvisibleCharacters,
     XXTEEditorAutoIndent,
     XXTEEditorSoftTabs,
     XXTEEditorTabWidth,
     XXTEEditorIndentWrappedLines,
     XXTEEditorAutoWordWrap,
     XXTEEditorWrapColumn,
     XXTEEditorReadOnly,
     XXTEEditorKeyboardRowAccessoryEnabled,
     XXTEEditorKeyboardASCIIPreferred,
     XXTEEditorAutoBrackets,
     XXTEEditorAutoCorrection,
     XXTEEditorAutoCapitalization,
     XXTEEditorSpellChecking,
     XXTEEditorSearchRegularExpression,
     XXTEEditorSearchCaseSensitive,
     XXTEEditorSearchCircular,
     ]];
    _shouldReloadAll = YES;
}

- (void)setNeedsReopenDocument {
    self.shouldReopenDocument = YES;
}

- (void)setNeedsSaveDocument {
    self.shouldSaveDocument = YES;
}

- (void)setNeedsReloadAttributes {
    self.shouldReloadAttributes = YES;
}

- (void)setNeedsResetAttributes {
    self.shouldResetAttributes = YES;
}

- (void)setNeedsFocusTextView {
    self.shouldFocusTextView = YES;
}

- (void)setNeedsEraseAllLineMasks {
    self.shouldEraseAllLineMasks = YES;
}

- (void)setNeedsReloadNavigationBar {
    self.shouldReloadNagivationBar = YES;
}

- (void)setNeedsHighlightRange:(NSRange)range {
    self.highlightRange = range;
    self.shouldHighlightRange = YES;
}

- (void)setNeedsReloadTextViewWidth {
    self.shouldReloadTextViewWidth = YES;
}

#pragma mark - Lazy Load

- (void)fillAllLineMasks {
    [self.maskView fillAllLineMasks];
}

- (void)reloadNavigationBarIfNecessary {
    if (self.shouldReloadNagivationBar) {
        self.shouldReloadNagivationBar = NO;
        [UIView animateWithDuration:.4f delay:.2f options:0 animations:^{
            [self renderNavigationBarTheme:NO];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)reloadAttributesIfNecessary {
    BOOL isValidSyntaxCache = [self _isValidSyntaxCache];
    if (isValidSyntaxCache) {  // no need to reload
        if (!self.shouldReloadAttributes) {
            return;
        }
        self.shouldReloadAttributes = NO;
    } else {
        [self invalidateSyntaxCaches];
    }
    [self reloadAttributes];
    self.shouldReloadAttributes = NO;
}

- (void)resetAttributesIfNecessary {
    if (self.shouldResetAttributes) {
        [self resetThemeTextAttributes];
        self.shouldResetAttributes = NO;
    }
}

- (void)eraseAllLineMasksIfNecessary {
    if (self.shouldEraseAllLineMasks) {
        [self.maskView eraseAllLineMasks];
        self.shouldEraseAllLineMasks = NO;
    }
}

- (void)preloadIfNecessary {
    BOOL shouldPreload = NO;
    for (NSString *defaultsKey in self.defaultsKeysToReload) {
        if ([[self defaultsKeysShouldPreload] containsObject:defaultsKey]) {
            shouldPreload = YES;
            break;
        }
    }
    if (shouldPreload) {
        [self preloadDefaults];
    }
}

- (void)reloadAllImmediately {
    [self setNeedsReloadAll];
    [self reloadAllIfNeeded];
}

- (void)reloadAllIfNeeded {
    if (self.shouldReloadAll) {
        self.shouldReloadAll = NO;
        [self reloadProcedure];
    }
}

- (void)reopenDocumentIfNecessary {
    if (self.shouldReopenDocument) {
        self.shouldReopenDocument = NO;
        [self reloadProcedure];
    }
}

- (void)reloadProcedure {
    NSString *newContent = [self loadContent];
    [self preloadDefaults];
    [self reloadDefaults];
    [self reloadTextViewWidthIfNecessary];
    [self reloadNavigationBarIfNecessary];
    [self reloadContent:newContent];
    [self reloadAttributesIfNecessary];
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
    NSData *documentData = CFBridgingRelease(data);
    NSString *entryPath = self.entryPath;
    promiseFixPermission(entryPath, NO); // fix permission
    
    struct stat entryStat;
    lstat(entryPath.fileSystemRepresentation, &entryStat);
    if (S_ISLNK(entryStat.st_mode)) {
        // support symbolic link
        NSString *originalPath = nil;
        char *resolved_path = (char *)malloc(PATH_MAX + 1);
        ssize_t resolved_len = readlink(entryPath.fileSystemRepresentation, resolved_path, PATH_MAX);
        resolved_path[resolved_len] = '\0';
        if (resolved_len >= 0) {
            originalPath = [[NSString alloc] initWithUTF8String:resolved_path];
        }
        free(resolved_path);
        
        [documentData writeToFile:originalPath atomically:YES];
    } else {
        [documentData writeToFile:entryPath atomically:YES];
    }
    
#ifdef DEBUG
    NSLog(@"document saved with encoding %@: %@", [XXTEEncodingHelper encodingNameForEncoding:[self currentEncoding]], entryPath);
#endif
}

- (void)reloadTextViewWidthIfNecessary {
    if (self.shouldReloadTextViewWidth) {
        [self reloadTextViewWidth];
        self.shouldReloadTextViewWidth = NO;
    }
}

- (void)highlightRangeIfNecessary {
    if (self.shouldHighlightRange) {
        self.shouldHighlightRange = NO;
        [self.maskView focusRange:self.highlightRange];
    }
}

- (void)focusTextViewIfNecessary {
    if (self.shouldFocusTextView) {
        self.shouldFocusTextView = NO;
        [self.textView becomeFirstResponder];
    }
}

#pragma mark - Rename

- (void)setRenamedEntryPath:(NSString *)entryPath {
    _entryPath = entryPath;
    _language = nil;  // needs reload language
    [self updateControllerTitles];
    [self setNeedsSaveDocument];
    [self setNeedsReloadAll];
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
