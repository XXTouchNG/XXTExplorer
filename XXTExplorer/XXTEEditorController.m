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

#import "XXTETextEditorTheme.h"

#import "XXTEEditorTextView.h"
#import "XXTEEditorTextStorage.h"
#import "XXTEEditorLayoutManager.h"

#import "XXTEKeyboardRow.h"

#import <Masonry/Masonry.h>
#import "UINavigationController+XXTEFullscreenPopGesture.h"

#import "XXTEEditorController+Keyboard.h"
#import "XXTEEditorController+Settings.h"

#import "SKHelper.h"
#import "SKHelperConfig.h"
#import "SKAttributedParser.h"
#import "SKRange.h"

static NSUInteger const kXXTEEditorCachedRangeLength = 10000;

@interface XXTEEditorController () <UITextViewDelegate, UIScrollViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) UIView *fakeStatusBar;

@property (nonatomic, strong) XXTETextEditorTheme *theme;
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;

@property (nonatomic, strong) SKHelper *helper;
@property (nonatomic, strong) SKAttributedParser *parser;
@property (nonatomic, assign) BOOL isRendering;
@property (atomic, strong) NSMutableIndexSet *renderedSet;
@property (atomic, strong) NSMutableArray <NSValue *> *rangesArray;
@property (atomic, strong) NSMutableArray <NSDictionary *> *attributesArray;

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
    if (XXTE_PAD) {
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
    
    [self reloadTheme];
    [self reloadParser];
    [self registerKeyboardNotifications];
}

- (void)reloadAll {
    [self reloadTheme];
    [self reloadParser];
    [self reloadView];
    [self reloadViewConstraints];
    [self reloadViewStyle];
    [self reloadContent];
    [self reloadAttributes];
}

- (void)reloadStyle {
    [self reloadViewStyle];
    [self reloadContent];
    [self reloadAttributes];
}

#pragma mark - BEFORE -viewDidLoad

- (void)reloadDefaults {
    
}

- (void)reloadTheme {
    NSString *themeIdentifier = @"Monokai";
    
    UIFont *font = [UIFont fontWithName:@"SourceCodePro-Regular" size:14]; // config
    XXTETextEditorTheme *theme = [[XXTETextEditorTheme alloc] initWithIdentifier:themeIdentifier font:font];
    _theme = theme;
}

#pragma mark - BEFORE -viewDidLoad

- (void)reloadParser {
    SKHelperConfig *helperConfig = [[SKHelperConfig alloc] init];
    helperConfig.bundle = [NSBundle mainBundle];
    helperConfig.themeIdentifier = self.theme.identifier;
    helperConfig.color = self.theme.foregroundColor;
    helperConfig.languageIdentifier = @"source.lua"; // config
    helperConfig.font = self.theme.font;
    
    SKHelper *helper = [[SKHelper alloc] initWithConfig:helperConfig];
    SKAttributedParser *parser = [helper attributedParser];
    
    _helper = helper;
    _parser = parser;
}

#pragma mark - AFTER -viewDidLoad

- (void)reloadView {
    if (![self isViewLoaded]) return;
    [_textView removeFromSuperview];
    
    BOOL isReadOnlyMode = NO;
    BOOL isLineNumberEnabled = YES; // config
    BOOL isHighlightEnabled = YES; // config
    BOOL isKeyboardRowEnabled = YES; // config
    
    NSTextStorage *textStorage = nil;
    if (isHighlightEnabled) {
        textStorage = [[XXTEEditorTextStorage alloc] init];
        textStorage.delegate = self;
    } else {
        textStorage = [[NSTextStorage alloc] init];
    }
    
    NSLayoutManager *layoutManager = nil;
    if (isLineNumberEnabled) {
        layoutManager = [[XXTEEditorLayoutManager alloc] init];
    } else {
        layoutManager = [[NSLayoutManager alloc] init];
    }
    
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    textContainer.widthTracksTextView = YES;
    
    [layoutManager addTextContainer:textContainer];
    [textStorage removeLayoutManager:textStorage.layoutManagers.firstObject];
    [textStorage addLayoutManager:layoutManager];
    
    XXTEEditorTextView *textView = [[XXTEEditorTextView alloc] initWithFrame:self.view.bounds textContainer:textContainer];
    textView.delegate = self;
    textView.selectable = YES;
    if (isReadOnlyMode) {
        textView.editable = NO;
    } else {
        textView.editable = YES;
    }
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.returnKeyType = UIReturnKeyDefault;
    textView.dataDetectorTypes = UIDataDetectorTypeNone;
    
    textView.indicatorStyle = [self isDarkMode] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
    
    if (isHighlightEnabled) {
        textView.vTextStorage = (XXTEEditorTextStorage *)textStorage;
    }
    if (isLineNumberEnabled) {
        textView.vLayoutManager = (XXTEEditorLayoutManager *)layoutManager;
    }
    
    if (isKeyboardRowEnabled && NO == isReadOnlyMode) {
        XXTEKeyboardRow *keyboardRow = [[XXTEKeyboardRow alloc] initWithTextView:textView];
        textView.inputAccessoryView = keyboardRow;
    }
    
    [self.view addSubview:textView];
    
    _textView = textView;
}

- (void)reloadViewConstraints {
    [self updateViewConstraints];
}

- (void)updateViewConstraints {
    CGRect frame = CGRectNull;
    if (NO == [self prefersNavigationBarHidden]) frame = CGRectZero;
    else frame = [[UIApplication sharedApplication] statusBarFrame];
    [self.fakeStatusBar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.equalTo(@(frame.size.height));
    }];
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
    [super updateViewConstraints];
}

- (void)reloadViewStyle {
    if (![self isViewLoaded]) return;
    XXTETextEditorTheme *theme = self.theme;
    self.view.backgroundColor = theme.backgroundColor;
    self.view.tintColor = theme.foregroundColor;
    XXTEEditorTextView *textView = self.textView;
    textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive; // config
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone; // config
    textView.autocorrectionType = UITextAutocorrectionTypeNo; // config
    textView.spellCheckingType = UITextSpellCheckingTypeNo; // config
    textView.backgroundColor = theme.backgroundColor; // config
    [textView setTintColor:theme.caretColor]; // config
    [textView setFont:theme.font]; // config
    [textView setTextColor:theme.foregroundColor]; // config
    [textView setLineNumberEnabled:YES]; // config
    if (textView.vLayoutManager) {
        [textView setGutterLineColor:theme.foregroundColor]; // config
        [textView setGutterBackgroundColor:theme.backgroundColor]; // config
        [textView.vLayoutManager setLineNumberFont:[UIFont fontWithName:@"CourierNewPSMT" size:10.f]]; // config
        [textView.vLayoutManager setLineNumberColor:theme.foregroundColor]; // config
    }
    [UIView animateWithDuration:.2f animations:^{
        [self renderNavigationBarTheme:NO];
    }];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configure];
    [self configureSubviews];
    
    [self reloadView];
    [self reloadViewConstraints];
    [self reloadViewStyle];
    
    [self reloadContent];
    [self reloadAttributes];
}

- (void)viewWillAppear:(BOOL)animated {
    [self renderNavigationBarTheme:NO];
    [super viewWillAppear:animated];
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

#pragma mark - Getters

- (BOOL)isEditing {
    return self.textView.isFirstResponder;
}

#pragma mark - Content

- (void)reloadContent {
    NSError *readError = nil;
    NSString *string = [NSString stringWithContentsOfFile:self.entryPath encoding:NSUTF8StringEncoding error:&readError];
    if (readError) {
        showUserMessage(self, [readError localizedDescription]);
        return;
    }
    XXTEEditorTextView *textView = self.textView;
    textView.editable = NO;
    [textView setText:string];
    textView.editable = YES;
}

#pragma mark - Attributes

- (void)reloadAttributes {
    BOOL isHighlightEnabled = YES; // config
    if (isHighlightEnabled) {
        [self invalidateSyntaxCaches];
        NSString *wholeString = self.textView.text;
        blockUserInteractions(self, YES, 0.2);
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
                blockUserInteractions(self, NO, 0.2);
            });
        });
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
}

#pragma mark - NSTextStorageDelegate

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta
{
//    if (editedMask & NSTextStorageEditedCharacters) {
//        NSRange extendedRange = NSUnionRange(editedRange, [[textStorage string] lineRangeForRange:NSMakeRange(NSMaxRange(editedRange), 0)]);
//        [textStorage setAttributes:self.theme.defaultAttributes range:extendedRange];
//        [self.parser attributedParseString:textStorage.string inRange:extendedRange matchCallback:^(NSString *scopeName, NSRange range, SKAttributes attributes) {
//            if (attributes && NSRangeEntirelyContains(extendedRange, range)) {
//                [textStorage addAttributes:attributes range:range];
//            }
//        }];
//    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self renderSyntaxOnScreen];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self renderSyntaxOnScreen];
}

#pragma mark - Render

- (NSRange)rangeShouldRenderOnScreen {
    XXTEEditorTextView *textView = self.textView;
//    NSUInteger textLength = textView.text.length;
    
    CGRect bounds = textView.bounds;
    
    UITextPosition *start = [textView characterRangeAtPoint:bounds.origin].start;
    UITextPosition *end = [textView characterRangeAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))].end;
    
    NSInteger beginOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:start];
    beginOffset -= kXXTEEditorCachedRangeLength;
    if (beginOffset < 0) beginOffset = 0;
    NSInteger endLength = [textView offsetFromPosition:start toPosition:end];
    endLength += kXXTEEditorCachedRangeLength * 2;
//    if (beginOffset + endLength > textLength) {
//        endLength = textLength - beginOffset;
//    }
    
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
        
        // Begin
        dispatch_async_on_main_queue(^{
            [textView.vTextStorage beginEditing];
        });
        
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
                NSUInteger renderLength = renderIndexes.count;
                for (NSUInteger idx = 0; idx < renderLength; idx++) {
                    NSUInteger index = [renderIndexes[idx] unsignedIntegerValue];
                    NSValue *rangeValue = rangesArray[index];
                    NSRange preparedRange = [rangeValue rangeValue];
                    [textView.vTextStorage addAttributes:attributesArray[index] range:preparedRange];
                }
            });
        }
        
        // End
        dispatch_async_on_main_queue(^{
            [textView.vTextStorage endEditing];
        });
        
        self.isRendering = NO;
    });
}

- (void)invalidateSyntaxCaches {
    [self.rangesArray removeAllObjects];
    [self.attributesArray removeAllObjects];
    [self.renderedSet removeAllIndexes];
//    NSRange wholeRange = NSMakeRange(0, self.textView.text.length);
//    [self.rangesArray addObject:[NSValue valueWithRange:wholeRange]];
//    [self.attributesArray addObject:self.theme.defaultAttributes];
}

#pragma mark - Memory

- (void)dealloc {
    [self dismissKeyboardNotifications];
#ifdef DEBUG
    NSLog(@"- [XXTEEditorController dealloc]");
#endif
}

@end
