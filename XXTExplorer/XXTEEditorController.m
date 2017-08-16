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

#import "XXTExplorer-Swift.h"

static NSUInteger testIdx = 0;

static NSUInteger const kXXTEEditorCachedRangeLength = 5000;

@interface XXTEEditorController () <UITextViewDelegate, UIScrollViewDelegate, NSTextStorageDelegate>

@property (nonatomic, strong) XXTETextEditorTheme *theme;
@property (nonatomic, strong, readonly) XXTEEditorTextView *textView;
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;

@property (nonatomic, strong) SKHelper *helper;
@property (nonatomic, strong) SKAttributedParser *parser;
@property (atomic, strong) NSMutableArray <NSValue *> *rangesArray;
@property (atomic, strong) NSMutableArray <NSDictionary *> *attributesArray;

@end

@implementation XXTEEditorController

@synthesize entryPath = _entryPath;

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

#pragma mark - Navigation Bar Color

- (void)renderTheme {
    if (XXTE_PAD) return;
    UIColor *backgroundColor = XXTE_COLOR;
    UIColor *foregroundColor = [UIColor whiteColor];
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

- (void)restoreTheme {
    if (XXTE_PAD) return;
    UIColor *backgroundColor = XXTE_COLOR;
    UIColor *foregroundColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : foregroundColor}];
    self.navigationController.navigationBar.tintColor = foregroundColor;
    self.navigationController.navigationBar.barTintColor = backgroundColor;
    self.settingsButtonItem.tintColor = foregroundColor;
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
    self.rangesArray = [[NSMutableArray alloc] init];
    self.attributesArray = [[NSMutableArray alloc] init];
    
    [self reloadTheme];
    [self reloadParser];
    [self registerForKeyboardNotifications];
}

- (void)reloadAll {
    [self reloadTheme];
    [self reloadParser];
    [self reloadView];
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
    NSArray <NSDictionary *> *testPair = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SKTheme" ofType:@"plist"]];
    NSString *themeIdentifier = testPair[testIdx][@"name"];
    if (++testIdx >= testPair.count) testIdx = 0;
    
    XXTETextEditorTheme *theme = [[XXTETextEditorTheme alloc] initWithIdentifier:themeIdentifier];
    _theme = theme;
}

#pragma mark - BEFORE -viewDidLoad

- (void)reloadParser {
    SKHelperConfig *helperConfig = [[SKHelperConfig alloc] init];
    helperConfig.bundle = [NSBundle mainBundle];
    helperConfig.themeIdentifier = self.theme.identifier;
    helperConfig.color = self.theme.foregroundColor;
    helperConfig.languageIdentifier = @"source.lua"; // config
    helperConfig.font = [UIFont fontWithName:@"SourceCodePro-Regular" size:14]; // config
    
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
    
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    _textView = textView;
}

- (void)reloadViewStyle {
    if (![self isViewLoaded]) return;
    XXTETextEditorTheme *theme = self.theme;
    XXTEEditorTextView *textView = self.textView;
    textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive; // config
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone; // config
    textView.autocorrectionType = UITextAutocorrectionTypeNo; // config
    textView.spellCheckingType = UITextSpellCheckingTypeNo; // config
    textView.backgroundColor = theme.backgroundColor; // config
    [textView setTintColor:theme.caretColor]; // config
    [textView setFont:[UIFont fontWithName:@"SourceCodePro-Regular" size:14.f]]; // config
    [textView setTextColor:theme.foregroundColor]; // config
    [textView setLineNumberEnabled:YES]; // config
    if (textView.vLayoutManager) {
        [textView setGutterLineColor:theme.foregroundColor]; // config
        [textView setGutterBackgroundColor:theme.backgroundColor]; // config
        [textView.vLayoutManager setLineNumberFont:[UIFont fontWithName:@"CourierNewPSMT" size:10.f]]; // config
        [textView.vLayoutManager setLineNumberColor:theme.foregroundColor]; // config
    }
    [UIView animateWithDuration:.2f animations:^{
        [self renderTheme];
    }];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configure];
    [self configureSubviews];
    [self configureConstraints];
    
    [self reloadView];
    [self reloadViewStyle];
    
    [self reloadContent];
    [self reloadAttributes];
}

- (void)viewWillAppear:(BOOL)animated {
    [self renderTheme];
    [super viewWillAppear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self restoreTheme];
    }
    [super willMoveToParentViewController:parent];
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
    
}

- (void)configureConstraints {
    
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)settingsButtonItem {
    if (!_settingsButtonItem) {
        UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarSettings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonItemTapped:)];
        _settingsButtonItem = settingsButtonItem;
    }
    return _settingsButtonItem;
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            @weakify(self);
            [self.parser parseAttributedString:wholeString match:^(NSString * _Nonnull scope, NSRange range, NSDictionary <NSString *, id> * _Nullable attributes) {
                @strongify(self);
                if (attributes) {
                    [self.rangesArray addObject:[NSValue valueWithRange:range]];
                    [self.attributesArray addObject:attributes];
                }
            }];
            dispatch_async_on_main_queue(^{
                [self renderSyntaxOnScreen];
            });
        });
    }
}

#pragma mark - UITextViewDelegate

#pragma mark - NSTextStorageDelegate

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self renderSyntaxOnScreen];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self renderSyntaxOnScreen];
}

#pragma mark - Render

- (void)renderSyntaxOnScreen {
    NSArray *rangesArray = self.rangesArray;
    NSArray *attributesArray = self.attributesArray;
    XXTEEditorTextView *textView = self.textView;
    CGRect bounds = textView.bounds;
    
    UITextPosition *start = [textView characterRangeAtPoint:bounds.origin].start;
    UITextPosition *end = [textView characterRangeAtPoint:CGPointMake(CGRectGetMaxX(bounds), CGRectGetMaxY(bounds))].end;
    
    NSInteger beginOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:start];
    beginOffset -= kXXTEEditorCachedRangeLength;
    if (beginOffset < 0) beginOffset = 0;
    NSInteger endLength = [textView offsetFromPosition:start toPosition:end];
    endLength += kXXTEEditorCachedRangeLength * 2;
    
    NSRange range = NSMakeRange(beginOffset, endLength);
    
    NSUInteger rangesArrayLength = rangesArray.count;
    NSUInteger attributesArrayLength = attributesArray.count;
    if (rangesArrayLength != attributesArrayLength) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSUInteger idx = 0; idx < rangesArrayLength; idx++) {
            NSValue *rangeValue = rangesArray[idx];
            NSRange preparedRange = [rangeValue rangeValue];
            if (NSIntersectionRange(range, preparedRange).length != 0 && preparedRange.length < kXXTEEditorCachedRangeLength) {
                dispatch_async_on_main_queue(^{
                    [textView.vTextStorage addAttributes:attributesArray[idx] range:preparedRange];
                });
            }
        }
    });
}

- (void)invalidateSyntaxCaches {
    [self.rangesArray removeAllObjects];
    [self.attributesArray removeAllObjects];
}

#pragma mark - Keyboard

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    UITextView *textView = self.textView;
    UITextRange * selectionRange = [textView selectedTextRange];
    CGRect selectionStartRect = [textView caretRectForPosition:selectionRange.start];
    CGRect selectionEndRect = [textView caretRectForPosition:selectionRange.end];
    CGPoint selectionCenterPoint = (CGPoint){(selectionStartRect.origin.x + selectionEndRect.origin.x)/2,(selectionStartRect.origin.y + selectionStartRect.size.height / 2)};
    
    if (!CGRectContainsPoint(aRect, selectionCenterPoint) ) {
        [textView scrollRectToVisible:CGRectMake(selectionStartRect.origin.x, selectionStartRect.origin.y, selectionEndRect.origin.x - selectionStartRect.origin.x, selectionStartRect.size.height) animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UITextView *textView = self.textView;
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    textView.contentInset = contentInsets;
    textView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - Button Actions

- (void)settingsButtonItemTapped:(UIBarButtonItem *)sender {
    
}

#pragma mark - Memory

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
    NSLog(@"- [XXTEEditorController dealloc]");
#endif
}

@end
