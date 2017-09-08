//
//  XXTEEditorController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController.h"
#import "XXTECodeViewerController.h"

#import "XXTEAppDefines.h"
#import "XXTEEditorDefaults.h"
#import "XXTEDispatchDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENotificationCenterDefines.h"

#import "XXTEEditorTheme.h"
#import "XXTEEditorLanguage.h"

#import "XXTEEditorTextView.h"
#import "XXTEEditorTextStorage.h"
#import "XXTEEditorLayoutManager.h"
#import "XXTEEditorTypeSetter.h"
#import "XXTEEditorTextInput.h"

#import "XXTEKeyboardRow.h"

#import <Masonry/Masonry.h>
#import "UINavigationController+XXTEFullscreenPopGesture.h"

#import "XXTEEditorController+State.h"
#import "XXTEEditorController+Keyboard.h"
#import "XXTEEditorController+Settings.h"
#import "XXTEEditorController+Menu.h"

#import "SKAttributedParser.h"
#import "SKRange.h"

#import "XXTPickerSnippet.h"
#import "XXTPickerFactory.h"

static NSUInteger const kXXTEEditorCachedRangeLength = 10000;

@interface XXTEEditorController () <UIScrollViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) UIView *fakeStatusBar;
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;
@property (nonatomic, strong) XXTEKeyboardRow *keyboardRow;

@property (nonatomic, strong, readonly) SKAttributedParser *parser;
@property (nonatomic, assign) BOOL isRendering;
@property (atomic, strong) NSMutableIndexSet *renderedSet;
@property (atomic, strong) NSMutableArray <NSValue *> *rangesArray;
@property (atomic, strong) NSMutableArray <NSDictionary *> *attributesArray;

@property (nonatomic, assign) BOOL shouldSaveDocument;
@property (nonatomic, assign) BOOL shouldFocusTextView;
@property (nonatomic, assign) BOOL shouldRefreshNagivationBar;
@property (nonatomic, assign) BOOL shouldReloadAll;

@end

@implementation XXTEEditorController

@synthesize entryPath = _entryPath;

#pragma mark - Restore State

- (NSString *)restorationIdentifier {
    return [NSString stringWithFormat:@"com.xxtouch.restoration.%@", NSStringFromClass(self.class)];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    if (_entryPath) {
        [coder encodeObject:_entryPath forKey:@"entryPath"];
    }
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    _entryPath = [coder decodeObjectForKey:@"entryPath"];
    [super decodeRestorableStateWithCoder:coder];
}

#pragma mark - Editor

+ (NSString *)editorName {
    return NSLocalizedString(@"Text Editor", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return [XXTECodeViewerController suggestedExtensions];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([self isDarkMode]) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (BOOL)isDarkMode
{
    UIColor *newColor = self.theme.backgroundColor;
    if (!newColor) newColor = XXTE_COLOR;
    const CGFloat *componentColors = CGColorGetComponents(newColor.CGColor);
    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    if (colorBrightness < 0.5)
        return YES;
    else
        return NO;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)xxte_prefersNavigationBarHidden {
    return [self prefersNavigationBarHidden];
}

- (BOOL)prefersNavigationBarHidden {
    if (XXTE_PAD || NO == XXTEDefaultsBool(XXTEEditorFullScreenWhenEditing, NO)) {
        return NO;
    }
    return [self isEditing];
}

#pragma mark - Navigation Bar Color

- (void)renderNavigationBarTheme:(BOOL)restore {
    if (XXTE_PAD) return;
    UIColor *backgroundColor = XXTE_COLOR;
    UIColor *foregroundColor = [UIColor whiteColor];
    if (restore) {
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : foregroundColor}];
        self.navigationController.navigationBar.tintColor = foregroundColor;
        self.navigationController.navigationBar.barTintColor = backgroundColor;
        self.settingsButtonItem.tintColor = foregroundColor;
    } else {
        if (self.theme) {
            if (self.theme.foregroundColor)
                foregroundColor = self.theme.foregroundColor;
            if (self.theme.backgroundColor)
                backgroundColor = self.theme.backgroundColor;
        }
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : foregroundColor}];
        self.navigationController.navigationBar.tintColor = foregroundColor;
        self.navigationController.navigationBar.barTintColor = backgroundColor;
        self.settingsButtonItem.tintColor = foregroundColor;
    }
    [self setNeedsStatusBarAppearanceUpdate];
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
    [self setRestorationIdentifier:self.restorationIdentifier];
        
    self.hidesBottomBarWhenPushed = YES;
    self.rangesArray = [[NSMutableArray alloc] init];
    self.attributesArray = [[NSMutableArray alloc] init];
    self.renderedSet = [[NSMutableIndexSet alloc] init];
    
    [self reloadDefaults];
    [self reloadTheme];
    [self reloadLanguage];
    [self reloadParser];
}

- (void)reloadAll {
    [self reloadDefaults];
    [self reloadTheme];
    [self reloadLanguage];
    [self reloadParser];
    [self reloadViewConstraints];
    [self reloadViewStyle];
    [self reloadContent];
    [self reloadAttributes];
}

#pragma mark - BEFORE -viewDidLoad

- (void)reloadDefaults {
    
}

- (void)reloadTheme {
    NSString *themeName = XXTEDefaultsObject(XXTEEditorThemeName, @"Mac Classic");
    
    NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, @"CourierNewPSMT");
    CGFloat fontSize = XXTEDefaultsDouble(XXTEEditorFontSize, 14.0);
    UIFont *font = [UIFont fontWithName:fontName size:fontSize]; // config
    
    XXTEEditorTheme *theme = [[XXTEEditorTheme alloc] initWithName:themeName font:font];
    _theme = theme;
}

- (void)reloadLanguage {
    NSString *entryExtension = [self.entryPath pathExtension];
    if (entryExtension.length == 0)
        return;
    XXTEEditorLanguage *language = [[XXTEEditorLanguage alloc] initWithExtension:entryExtension];
    _language = language;
}

- (void)reloadParser {
    if (!self.language.rawLanguage || !self.theme.rawTheme)
        return;
    SKAttributedParser *parser = [[SKAttributedParser alloc] initWithLanguage:self.language.rawLanguage theme:self.theme.rawTheme];
    _parser = parser;
}

#pragma mark - AFTER -viewDidLoad

- (void)reloadViewConstraints {
    if (XXTE_PAD) {
        
    } else {
        CGRect frame = CGRectNull;
        if (NO == [self.navigationController isNavigationBarHidden]) frame = CGRectZero;
        else frame = [[UIApplication sharedApplication] statusBarFrame];
        [self.fakeStatusBar mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.leading.trailing.equalTo(self.view);
            make.height.equalTo(@(frame.size.height));
        }];
    }
    [self updateViewConstraints]; // TODO: back gesture will break this method :-(
}

- (void)reloadViewStyle {
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
    
    XXTEEditorTextView *textView = self.textView;
    textView.keyboardType = UIKeyboardTypeDefault;
    textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
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
        keyboardRow.style = XXTEKeyboardRowStyleLight;
    }
    else
    {
        textView.keyboardAppearance = UIKeyboardAppearanceDark;
        keyboardRow.style = XXTEKeyboardRowStyleDark;
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
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configure];
    [self configureSubviews];
    [self configureConstraints];
    
    [self reloadViewConstraints];
    [self reloadViewStyle];
    
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
    self.navigationItem.rightBarButtonItem = self.settingsButtonItem;
}

- (void)configureSubviews {
    if (XXTE_PAD) {
        
    } else {
        [self.view addSubview:self.fakeStatusBar];
    }
    [self.view addSubview:self.textView];
}

- (void)configureConstraints {
    if (XXTE_PAD)
    {
        [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    else
    {
        [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.fakeStatusBar.mas_bottom);
            make.leading.trailing.bottom.equalTo(self.view);
        }];
    }
}

#pragma mark - UIView Getters

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
        textView.returnKeyType = UIReturnKeyDefault;
        textView.dataDetectorTypes = UIDataDetectorTypeNone;
        
        textView.indicatorStyle = [self isDarkMode] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
        
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

#pragma mark - Getters

- (BOOL)isEditing {
    return self.textView.isFirstResponder;
}

#pragma mark - Content

- (void)reloadContent {
    BOOL isReadOnlyMode = XXTEDefaultsBool(XXTEEditorReadOnly, NO); // config
    NSError *readError = nil;
    NSString *string = [NSString stringWithContentsOfFile:self.entryPath encoding:NSUTF8StringEncoding error:&readError];
    if (readError) {
        showUserMessage(self, [readError localizedDescription]);
        return;
    }
    XXTEEditorTextView *textView = self.textView;
    textView.editable = NO;
    [textView setFont:self.theme.font];
    [textView setTextColor:self.theme.foregroundColor];
    [textView setText:string];
    textView.editable = !isReadOnlyMode;
}

#pragma mark - Attributes

- (void)reloadAttributes {
    [self invalidateSyntaxCaches];
    BOOL isHighlightEnabled = XXTEDefaultsBool(XXTEEditorHighlightEnabled, YES); // config
    if (isHighlightEnabled) {
        NSString *wholeString = self.textView.text;
        blockUserInteractions(self, YES, 0);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @weakify(self);
            [self.parser attributedParseString:wholeString matchCallback:^(NSString * _Nonnull scope, NSRange range, NSDictionary <NSString *, id> * _Nullable attributes) {
                @strongify(self);
                if (attributes) {
                    [self.rangesArray addObject:[NSValue valueWithRange:range]];
                    [self.attributesArray addObject:attributes];
                }
            }];
            dispatch_async_on_main_queue(^{
                [self renderSyntaxOnScreen];
                blockUserInteractions(self, NO, 0);
            });
        });
    }
}

#pragma mark - NSTextStorageDelegate

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta
{
    if (editedMask & NSTextStorageEditedCharacters) {
        
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
    
    CGRect bounds = textView.bounds;
    UITextPosition *start = [textView characterRangeAtPoint:bounds.origin].start;
    UITextPosition *end = [textView characterRangeAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))].end;
    
    NSInteger beginOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:start];
    beginOffset -= kXXTEEditorCachedRangeLength;
    if (beginOffset < 0) beginOffset = 0;
    NSInteger endLength = [textView offsetFromPosition:start toPosition:end];
    endLength += kXXTEEditorCachedRangeLength * 2;
    
    NSRange range = NSMakeRange((NSUInteger) beginOffset, (NSUInteger) endLength);
    return range;
}

- (void)renderSyntaxOnScreen {
    if (self.parser.aborted) return;
    
    NSArray *rangesArray = self.rangesArray;
    NSArray *attributesArray = self.attributesArray;
    NSMutableIndexSet *renderedSet = self.renderedSet;
    XXTEEditorTextView *textView = self.textView;
    
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
                [textView.vTextStorage beginEditing];
                NSUInteger renderLength = renderIndexes.count;
                for (NSUInteger idx = 0; idx < renderLength; idx++) {
                    NSUInteger index = [renderIndexes[idx] unsignedIntegerValue];
                    NSValue *rangeValue = rangesArray[index];
                    NSRange preparedRange = [rangeValue rangeValue];
                    [textView.vTextStorage addAttributes:attributesArray[index] range:preparedRange];
                }
                [textView.vTextStorage endEditing];
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

- (void)setNeedsFocusTextView {
    self.shouldFocusTextView = YES;
}

- (void)setNeedsRefreshNavigationBar {
    self.shouldRefreshNagivationBar = YES;
}

#pragma mark - Save Document

- (void)saveDocumentIfNecessary {
    if (!self.shouldSaveDocument) return;
    NSString *documentString = self.textView.textStorage.string;
    NSData *documentData = [documentString dataUsingEncoding:NSUTF8StringEncoding];
    [documentData writeToFile:self.entryPath atomically:YES];
    self.shouldSaveDocument = NO;
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
