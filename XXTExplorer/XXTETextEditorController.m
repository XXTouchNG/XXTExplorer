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

#import <Masonry/Masonry.h>

#import "XXTExplorer-Swift.h"

@interface XXTETextEditorController () <UITextViewDelegate, NSTextStorageDelegate, SKHelperDelegate>

@property (nonatomic, strong, readonly) XXTETextEditorView *textView;

//@property (nonatomic, strong) SKHelperConfig *helperConfig;
//@property (nonatomic, strong) SKHelper *helper;

@property (nonatomic, strong) XXTETextEditorTheme *theme;

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
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - Navigation Bar Color

- (void)renderTheme {
    UIColor *backgroundColor = XXTE_COLOR;
    UIColor *foregroundColor = [UIColor whiteColor];
    if (self.theme) {
        if (self.theme.foregroundColor) {
            foregroundColor = self.theme.foregroundColor;
        }
        if (self.theme.backgroundColor) {
            backgroundColor = self.theme.backgroundColor;
        }
    }
    
    // text color
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : foregroundColor}];
    
    // navigation items and bar button items color
    self.navigationController.navigationBar.tintColor = foregroundColor;
    
    // background color
    self.navigationController.navigationBar.barTintColor = backgroundColor;
}

- (void)restoreTheme {
    UIColor *backgroundColor = XXTE_COLOR;
    UIColor *foregroundColor = [UIColor whiteColor];
    
    // text color
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : foregroundColor}];
    
    // navigation items and bar button items color
    self.navigationController.navigationBar.tintColor = foregroundColor;
    
    // background color
    self.navigationController.navigationBar.barTintColor = backgroundColor;
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
    [self reloadHelper];
}

- (void)reloadAll {
    [self reloadTheme];
    [self reloadHelper];
    [self reloadView];
    [self reloadViewStyle];
    [self asyncLoadContent];
}

#pragma mark - BEFORE -viewDidLoad

- (void)reloadTheme {
    NSString *themeIdentifier = @"Monokai"; // TODO: theme configuration
    
    XXTETextEditorTheme *theme = [[XXTETextEditorTheme alloc] initWithIdentifier:themeIdentifier];
    _theme = theme;
}

- (void)reloadHelper {
//    SKHelperConfig *helperConfig = [[SKHelperConfig alloc] init];
//    helperConfig.bundle = [NSBundle mainBundle];
//    helperConfig.font = [UIFont fontWithName:@"SourceCodePro-Regular" size:14]; // TODO: font configuration
//    helperConfig.color = self.theme.foregroundColor;
//    helperConfig.path = self.entryPath;
//    helperConfig.languageIdentifier = @"source.lua"; // TODO: highlight bindings
//    helperConfig.themeIdentifier = self.theme.identifier;
//    _helperConfig = helperConfig;
//    
//    SKHelper *helper = [[SKHelper alloc] initWithConfig:helperConfig];
//    helper.delegate = self;
//    _helper = helper;
}

#pragma mark - AFTER -viewDidLoad

- (void)reloadView {
    if (![self isViewLoaded]) return;
    [_textView removeFromSuperview];
    
    BOOL isLineNumberEnabled = YES; // config
    
    XXTETextStorage *textStorage = [[XXTETextStorage alloc] init];
    textStorage.delegate = self;
    
    NSLayoutManager *layoutManager = nil;
    if (isLineNumberEnabled) {
        layoutManager = [[XXTELayoutManager alloc] init];
    } else {
        layoutManager = [[NSLayoutManager alloc] init];
    }
    layoutManager.showsInvisibleCharacters = NO; // config
    layoutManager.showsControlCharacters = NO; // config
    
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    textContainer.widthTracksTextView = YES;
    
    [layoutManager addTextContainer:textContainer];
    [textStorage removeLayoutManager:textStorage.layoutManagers.firstObject];
    [textStorage addLayoutManager:layoutManager];
    
    XXTETextEditorView *textView = [[XXTETextEditorView alloc] initWithFrame:self.view.bounds textContainer:textContainer];
    textView.delegate = self;
    textView.selectable = YES;
    textView.editable = NO; // default is NO, config (readonly?)
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive; // config
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone; // config
    textView.autocorrectionType = UITextAutocorrectionTypeNo; // config
    textView.spellCheckingType = UITextSpellCheckingTypeNo; // config
    textView.returnKeyType = UIReturnKeyDefault; // config
    textView.dataDetectorTypes = UIDataDetectorTypeNone; // config
    
    textView.indicatorStyle = [self isDarkMode] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
    
    textView.vTextStorage = textStorage;
    if (isLineNumberEnabled) {
        textView.vLayoutManager = (XXTELayoutManager *)layoutManager;
    }
    
    [self.view addSubview:textView];
    
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    _textView = textView;
}

- (void)reloadViewStyle {
    if (![self isViewLoaded]) return;
    self.textView.backgroundColor = self.theme.backgroundColor; // config
    [self.textView setTintColor:self.theme.caretColor]; // config
    [self.textView setFont:[UIFont fontWithName:@"SourceCodePro-Regular" size:14.f]]; // config
    [self.textView setTextColor:self.theme.foregroundColor]; // config
    [self.textView setLineNumberEnabled:YES]; // config
    if (self.textView.vLayoutManager) {
        [self.textView setGutterLineColor:self.theme.foregroundColor]; // config
        [self.textView setGutterBackgroundColor:self.theme.backgroundColor]; // config
        [self.textView.vLayoutManager setLineNumberFont:[UIFont fontWithName:@"CourierNewPSMT" size:10.f]]; // config
        [self.textView.vLayoutManager setLineNumberColor:self.theme.foregroundColor]; // config
    }
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configure];
    [self configureSubviews];
    [self configureConstraints];
    
    [self reloadView];
    [self reloadViewStyle];
    
    [self asyncLoadContent];
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
}

- (void)configureSubviews {
    
}

- (void)configureConstraints {
    
}

#pragma mark - Content

- (void)asyncLoadContent {
    self.textView.editable = NO;
    blockUserInteractions(self, YES);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *stringData = [[NSData alloc] initWithContentsOfFile:self.entryPath];
        NSString *string = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
        dispatch_async_on_main_queue(^{
            if (string) {
                [self.textView setText:string];
            } else {
                
            }
            blockUserInteractions(self, NO);
            self.textView.editable = YES;
        });
    });
}

#pragma mark - SKHelperDelegate

- (void)helperDidFinishInitialLoadWithSender:(SKHelper *)sender result:(NSAttributedString *)result {
    
}

- (void)helperDidFailInitialLoadWithSender:(SKHelper *)sender error:(NSError *)error {
    showUserMessage(self, error.localizedDescription);
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTETextEditorController dealloc]");
#endif
}

@end
