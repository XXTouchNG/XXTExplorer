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
    return UIStatusBarStyleLightContent;
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
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configure];
    [self configureSubviews];
    [self configureConstraints];
    
    [self reloadTheme];
    [self reloadHelper];
    
    [self asyncLoadContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __block BOOL rendered = NO;
    if (self.transitionCoordinator) {
        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self renderTheme];
            rendered = YES;
        } completion:nil];
    }
    if (!rendered) [self renderTheme];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    __block BOOL rendered = NO;
    if (self.transitionCoordinator) {
        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self restoreTheme];
            rendered = YES;
        } completion:nil];
    }
    if (!rendered) [self restoreTheme];
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

#pragma mark - Config

- (void)reloadTheme {
    NSString *themeIdentifier = @"Solarized (Dark)";
    
    XXTETextEditorTheme *theme = [[XXTETextEditorTheme alloc] initWithIdentifier:themeIdentifier];
    _theme = theme;
    
    self.textView.backgroundColor = self.theme.backgroundColor;
}

- (void)reloadHelper {
    NSString *themeIdentifier = @"Solarized (Dark)";
    
    SKHelperConfig *helperConfig = [[SKHelperConfig alloc] init];
    helperConfig.bundle = [NSBundle mainBundle];
    helperConfig.font = [UIFont fontWithName:@"SourceCodePro-Regular" size:14];
    helperConfig.color = self.theme.foregroundColor;
    helperConfig.path = self.entryPath;
    helperConfig.languageIdentifier = @"source.lua";
    helperConfig.themeIdentifier = themeIdentifier;
    _helperConfig = helperConfig;
    
    SKHelper *helper = [[SKHelper alloc] initWithConfig:helperConfig];
    helper.delegate = self;
    _helper = helper;
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
