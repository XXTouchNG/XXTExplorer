//
//  XXTETextEditorController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 10/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTETextEditorController.h"
#import "XXTECodeViewerController.h"

#import "XXTEDispatchDefines.h"
#import "XXTEUserInterfaceDefines.h"

#import "XXTETextEditorTheme.h"

#import "XXTETextEditorView.h"
#import "XXTETextStorage.h"
#import "XXTELayoutManager.h"

#import "XXTEKeyboardRow.h"

#import <Masonry/Masonry.h>

#import "XXTExplorer-Swift.h"

#ifdef DEBUG
static NSUInteger testIdx = 0;
#endif

@interface XXTETextEditorController () <UITextViewDelegate>

@property (nonatomic, strong) XXTETextEditorTheme *theme;
@property (nonatomic, strong, readonly) XXTETextEditorView *textView;
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;

@end

@implementation XXTETextEditorController

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
    
    [self reloadTheme];
    [self registerForKeyboardNotifications];
}

- (void)reloadAll {
    [self reloadTheme];
    [self reloadView];
    [self reloadViewStyle];
    [self reloadContent];
}

- (void)reloadStyleAndContent {
    [self reloadViewStyle];
    [self reloadContent];
}

#pragma mark - BEFORE -viewDidLoad

- (void)reloadDefaults {
    
}

#ifdef DEBUG
- (void)reloadTheme {
    NSArray <NSDictionary *> *testPair = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SKTheme" ofType:@"plist"]];
    NSString *themeIdentifier = testPair[testIdx][@"name"];
    if (++testIdx >= testPair.count) testIdx = 0;
    
    XXTETextEditorTheme *theme = [[XXTETextEditorTheme alloc] initWithIdentifier:themeIdentifier];
    _theme = theme;
}
#endif

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
        SKHelperConfig *helperConfig = [[SKHelperConfig alloc] init];
        helperConfig.bundle = [NSBundle mainBundle];
        helperConfig.themeIdentifier = self.theme.identifier;
        helperConfig.color = self.theme.foregroundColor;
        helperConfig.languageIdentifier = @"source.lua"; // config
        helperConfig.font = [UIFont fontWithName:@"SourceCodePro-Regular" size:14]; // config
        
        textStorage = [[XXTETextStorage alloc] initWithConfig:helperConfig];
    } else {
        textStorage = [[NSTextStorage alloc] init];
    }
    
    NSLayoutManager *layoutManager = nil;
    if (isLineNumberEnabled) {
        layoutManager = [[XXTELayoutManager alloc] init];
    } else {
        layoutManager = [[NSLayoutManager alloc] init];
    }
    
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    textContainer.widthTracksTextView = YES;
    
    [layoutManager addTextContainer:textContainer];
    [textStorage removeLayoutManager:textStorage.layoutManagers.firstObject];
    [textStorage addLayoutManager:layoutManager];
    
    XXTETextEditorView *textView = [[XXTETextEditorView alloc] initWithFrame:self.view.bounds textContainer:textContainer];
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
        textView.vTextStorage = (XXTETextStorage *)textStorage;
    }
    if (isLineNumberEnabled) {
        textView.vLayoutManager = (XXTELayoutManager *)layoutManager;
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
    XXTETextEditorView *textView = self.textView;
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
    XXTETextEditorView *textView = self.textView;
    textView.editable = NO;
    [textView setText:string];
    BOOL isReadOnlyMode = NO;
    if (isReadOnlyMode) {
        textView.editable = NO;
    } else {
        textView.editable = YES;
    }
}

#pragma mark - SKHelperDelegate

- (void)helperDidFinishInitialLoadWithSender:(SKHelper *)sender result:(NSAttributedString *)result {
    
}

- (void)helperDidFailInitialLoadWithSender:(SKHelper *)sender error:(NSError *)error {
    showUserMessage(self, error.localizedDescription);
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
    NSLog(@"- [XXTETextEditorController dealloc]");
#endif
}

@end
