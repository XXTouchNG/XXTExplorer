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
#import <Masonry/Masonry.h>

#import "XXTExplorer-Swift.h"

@interface XXTETextEditorController () <UITextViewDelegate, SKHelperDelegate>

@property (nonatomic, strong) XXTETextEditorView *textView;

@property (nonatomic, strong) SKHelperConfig *helperConfig;
@property (nonatomic, strong) SKHelper *helper;

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
    if ([self isDarkNavigationBar]) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (BOOL) isDarkNavigationBar
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

#pragma mark - Config Before Load

- (void)reloadTheme {
    NSString *themeIdentifier = @"Monokai";
    
    XXTETextEditorTheme *theme = [[XXTETextEditorTheme alloc] initWithIdentifier:themeIdentifier];
    _theme = theme;
}

- (void)reloadHelper {
    SKHelperConfig *helperConfig = [[SKHelperConfig alloc] init];
    helperConfig.bundle = [NSBundle mainBundle];
    helperConfig.font = [UIFont fontWithName:@"SourceCodePro-Regular" size:14];
    helperConfig.color = self.theme.foregroundColor;
    helperConfig.path = self.entryPath;
    helperConfig.languageIdentifier = @"source.json";
    helperConfig.themeIdentifier = self.theme.identifier;
    _helperConfig = helperConfig;
    
    SKHelper *helper = [[SKHelper alloc] initWithConfig:helperConfig];
    helper.delegate = self;
    _helper = helper;
}

#pragma mark - Config After Load

- (void)reloadViewStyle {
    self.textView.backgroundColor = self.theme.backgroundColor;
    [self.textView setTintColor:self.theme.caretColor];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configure];
    [self configureSubviews];
    [self configureConstraints];
    
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
    [self.view addSubview:self.textView];
}

- (void)configureConstraints {
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - Content

- (void)asyncLoadContent {
    blockUserInteractions(self, YES);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSAttributedString *result = [self.helper initialLoad];
        dispatch_async_on_main_queue(^{
            if (result) {
                self.textView.attributedText = result;
            }
            blockUserInteractions(self, NO);
        });
    });
}

#pragma mark - UIView Getters

- (XXTETextEditorView *)textView {
    if (!_textView) {
        XXTETextEditorView *textView = [[XXTETextEditorView alloc] init];
        textView.delegate = self;
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        textView.selectable = YES;
        textView.editable = NO; // default is NO
        textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        _textView = textView;
    }
    return _textView;
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
