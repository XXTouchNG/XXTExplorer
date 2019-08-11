//
//  XXTECodeViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTECodeViewerController.h"
#import "XXTExplorerEntryCodeReader.h"
#import "XXTECodeViewerSettingsController.h"
#import "XXTECodeViewerDefaults.h"

// Helpers
#import "XXTETextPreprocessor.h"
#import "NSString+HTMLEscape.h"
#import "NSString+Template.h"
#import "UIColor+SKColor.h"
#import "UIColor+hexValue.h"
#import "UIColor+CssColor.h"
#import "XXTECodeViewerController+NavigationBar.h"

// Views
#import "XXTESingleActionView.h"

// Children
#import "XXTEEncodingController.h"
#import "XXTENavigationController.h"

#ifdef APPSTORE
@interface XXTECodeViewerController () <XXTECodeViewerSettingsControllerDelegate, XXTEEncodingControllerDelegate>
#else
@interface XXTECodeViewerController () <XXTECodeViewerSettingsControllerDelegate>
#endif

@property (nonatomic, strong) NSRegularExpression *hljsCssRegex;
@property (nonatomic, strong) NSRegularExpression *hljsLineCssRegex;
@property (nonatomic, assign) BOOL shouldRefreshNagivationBar;

@property (nonatomic, strong) XXTESingleActionView *actionView;
@property (nonatomic, strong) UIBarButtonItem *myBackButtonItem;
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;

@property (nonatomic, assign) BOOL needsReloadContent;
@property (nonatomic, assign) BOOL needsReloadUI;

@end

@implementation XXTECodeViewerController {
    BOOL _lockedState;
}

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Code Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"html", @"xml", @"svg", // HTML or XML
              @"css", // Stylesheet
              @"js", // Javascript
              @"h", @"m", @"mm", // Objective-C
              @"rb", // Ruby
              @"coffee", // Coffee
              @"ini", // Windows ini
              @"php", // PHP
              @"sql", // SQL
              @"cs", // C#
              @"diff", // Diff
              @"json", // JSON
              @"md", // Markdown
              @"pl", // Perl
              @"sh", // Shell
              @"c", @"cpp", @"hpp", // C++
              @"java", // Java
              @"conf", // Nginx
              @"py", // Python
              @"lua", // Lua
              @"txt", // Plain Text
              @"strings", // Strings
    ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryCodeReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _lockedState = NO;
        _currentEncoding = kCFStringEncodingInvalidId;
        _entryPath = path;
        _hljsCssRegex = [NSRegularExpression regularExpressionWithPattern:@"\\.hljs(\\s+|,+.*?)\\{(.*?)\\}" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
        _hljsLineCssRegex = [NSRegularExpression regularExpressionWithPattern:@"([A-Za-z0-9|-]+):\\s?(.*)" options:kNilOptions error:nil];
        _shouldRefreshNagivationBar = NO;
        self.navigationButtonsHidden = YES;
        self.hideWebViewBoundaries = NO;
        if (@available(iOS 9.0, *)) {
            self.showActionButton = YES;
        } else {
            self.showActionButton = NO;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *entryPath = self.entryPath;
    NSString *entryName = [entryPath lastPathComponent];
    if (self.title.length == 0) {
        if (entryName) {
            self.title = entryName;
        }
    }
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        // inherit
    }
    else {
        [self.navigationItem setLeftBarButtonItems:@[ self.myBackButtonItem ]];
        [self setApplicationLeftBarButtonItems:@[ self.myBackButtonItem ]];
    }
    XXTE_END_IGNORE_PARTIAL
    self.navigationItem.rightBarButtonItems = @[ self.settingsButtonItem ];
    self.applicationBarButtonItems = @[ self.settingsButtonItem ];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self reloadUI];
    [self reloadContent];
    [self reloadLockedState];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.needsReloadUI) {
        [self reloadUI];
        [self setNeedsReloadUI:NO];
    }
    [self renderNavigationBarTheme:NO];
    [super viewWillAppear:animated];
    if (self.needsReloadContent) {
        [self reloadContent];
        [self setNeedsReloadContent:NO];
    }
    [self reloadLockedState];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.shouldRefreshNagivationBar) {
        self.shouldRefreshNagivationBar = NO;
        [UIView animateWithDuration:.4f delay:.2f options:0 animations:^{
            [self renderNavigationBarTheme:NO];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

#pragma mark - Loaders

- (void)reloadLockedState {
    BOOL isLockedState = self.isLockedState;
    if (isLockedState)
    {
        if (![self.view.subviews containsObject:self.actionView])
        {
            [self.view addSubview:self.actionView];
        }
        if (self.webView) [self.webView setHidden:YES];
        if (self.wkWebView) [self.wkWebView setHidden:YES];
    }
    else
    {
        if (self.webView) [self.webView setHidden:NO];
        if (self.wkWebView) [self.wkWebView setHidden:NO];
        [self.actionView removeFromSuperview];
    }
}

- (void)reloadUI {
    // theme
    NSString *themeLocation = XXTEDefaultsObject(XXTECodeViewerThemeLocation, @"References.bundle/hljs/styles/xcode.css");
    
    // parse css in a very simple way
    NSString *themePath = [[NSBundle mainBundle] pathForResource:themeLocation ofType:@""];
    NSDictionary *themeDict = [self defaultThemeDictionaryForHLJSCssAtPath:themePath];
    if (themeDict) {
        NSString *foregroundColorString = [themeDict[@"color"] lastObject];
        NSString *backgroundColorString = [themeDict[@"background"] lastObject];
        if (!backgroundColorString) {
            backgroundColorString = [themeDict[@"background-color"] lastObject];
        }
        UIColor *foregroundColor = nil;
        if (foregroundColorString) {
            foregroundColor = [UIColor colorWithHex:foregroundColorString];
            if (!foregroundColor) {
                foregroundColor = [UIColor colorWithCssName:foregroundColorString];
            }
            self.view.tintColor = foregroundColor ?: XXTColorForeground();
            self.barTextColor = foregroundColor;
        }
        UIColor *backgroundColor = nil;
        if (backgroundColorString) {
            backgroundColor = [UIColor colorWithHex:backgroundColorString];
            if (!backgroundColor) {
                backgroundColor = [UIColor colorWithCssName:backgroundColorString];
            }
            self.view.backgroundColor = backgroundColor ?: [UIColor whiteColor];
            self.backgroundColor = backgroundColor;
            self.barTintColor = backgroundColor;
        }
        {
            UIColor *newColor = foregroundColor;
            self.actionView.titleLabel.textColor = newColor ?: [UIColor blackColor];
            self.actionView.descriptionLabel.textColor = newColor;
            if (![self isDarkMode]) {
                self.actionView.iconImageView.image = [UIImage imageNamed:@"XXTEBugIcon"];
            } else {
                self.actionView.iconImageView.image = [UIImage imageNamed:@"XXTEBugIconLight"];
            }
        }
    }
    
    // navigation bar
    [self setNeedsRefreshNavigationBar];
}

- (void)reloadContent {
    NSError *templateError = nil;
    NSString *htmlTemplate = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"References.bundle/code" ofType:@"html"] encoding:NSUTF8StringEncoding error:&templateError];
    if (templateError) {
        // impossible
        return;
    }
    
    NSError *readError = nil;
    CFStringEncoding tryEncoding = [self currentEncoding];
    NSString *codeString = [XXTETextPreprocessor preprocessedStringWithContentsOfFile:self.entryPath NumberOfLines:NULL Encoding:&tryEncoding LineBreak:NULL MaximumLength:NULL Error:&readError];
    if (!codeString) {
        [self setLockedState:YES];
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
        return;
    } else {
        [self setLockedState:NO];
    }
    [self setCurrentEncoding:tryEncoding];
    
    NSString *escapedString = [codeString stringByEscapingHTML];
    if (!escapedString) {
        return;
    }
    
    // line number
    BOOL counter = XXTEDefaultsBool(XXTECodeViewerLineNumbersEnabled, (XXTE_IS_IPAD ? YES : NO));
    if (counter) {
        NSArray <NSString *> *escapedLines = @[];
        if ([escapedString containsString:@NSStringLineBreakCRLF]) {
            escapedLines = [escapedString componentsSeparatedByString:@NSStringLineBreakCRLF];
        } else if ([escapedString containsString:@NSStringLineBreakCR]) {
            escapedLines = [escapedString componentsSeparatedByString:@NSStringLineBreakCR];
        } else {
            escapedLines = [escapedString componentsSeparatedByString:@NSStringLineBreakLF];
        }
        
        NSMutableString *mEscapedString = [NSMutableString string];
        for (NSString *escapedLine in escapedLines) {
            [mEscapedString appendString:@"<span class=\"line\">"];
            [mEscapedString appendString:escapedLine];
            [mEscapedString appendString:@"</span>\n"];
        }
        escapedString = [mEscapedString copy];
    }
    
    BOOL highlight = XXTEDefaultsBool(XXTECodeViewerHighlightEnabled, YES);
    
    // theme
    NSString *themeLocation = XXTEDefaultsObject(XXTECodeViewerThemeLocation, @"References.bundle/hljs/styles/xcode.css");
    
    // parse css in a very simple way
    NSString *themePath = [[NSBundle mainBundle] pathForResource:themeLocation ofType:@""];
    
    // font
    NSString *fontName = XXTEDefaultsObject(XXTECodeViewerFontName, @"Courier");
    NSNumber *fontSize = XXTEDefaultsObject(XXTECodeViewerFontSize, @(12.0));
    
    NSDictionary *settingsDict =
    @{
        @"title": self.entryPath.lastPathComponent ?: @"",
        @"code": escapedString ?: @"",
        @"type": highlight ? [NSString stringWithFormat:@"lang-%@", [self.entryPath pathExtension]] : @"nohighlight",
        @"themeLocation": themePath ?: @"",
        @"gutterColor": [[self.barTextColor colorWithAlphaComponent:0.25] cssRGBAString] ?: @"#ddd",
        @"gutterBackgroundColor": [[self.barTextColor colorWithAlphaComponent:0.033] cssRGBAString] ?: @"#fff",
        @"fontName": [NSString stringWithFormat:@"\"%@\", monospace", fontName],
        @"fontSize": [NSString stringWithFormat:@"%@px", fontSize],
        @"extra": @"",
    };
    
    // render
    htmlTemplate =
    [htmlTemplate stringByReplacingTagsInDictionary:settingsDict];
    if (self.webView) {
        [self.webView loadHTMLString:htmlTemplate baseURL:[self baseUrl]];
    } else {
        [self.wkWebView loadHTMLString:htmlTemplate baseURL:[self baseUrl]];
    }
}

#pragma mark - Getters

- (BOOL)isLockedState {
    return _lockedState;
}

- (NSURL *)baseUrl {
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"References.bundle"];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)settingsButtonItem {
    if (!_settingsButtonItem) {
        UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarSettings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonItemTapped:)];
        _settingsButtonItem = settingsButtonItem;
    }
    return _settingsButtonItem;
}

- (UIBarButtonItem *)myBackButtonItem {
    if (!_myBackButtonItem) {
        UIBarButtonItem *myBackButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarBack"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonItemTapped:)];
        _myBackButtonItem = myBackButtonItem;
    }
    return _myBackButtonItem;
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

#pragma mark - Actions

- (void)settingsButtonItemTapped:(UIBarButtonItem *)sender {
    XXTECodeViewerSettingsController *settingsController = [[XXTECodeViewerSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    settingsController.delegate = self;
    [self.navigationController pushViewController:settingsController animated:YES];
}

- (void)backButtonItemTapped:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

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

#pragma mark - XXTECodeViewerSettingsControllerDelegate

- (void)codeViewerSettingsControllerDidChange:(XXTECodeViewerSettingsController *)controller {
    [self setNeedsReloadUI:YES];
    [self setNeedsReloadContent:YES];
}

- (void)codeViewerNeedsRestoreNavigationBar:(BOOL)restore {
    [self renderNavigationBarTheme:restore];
}

#pragma mark - XXTEEncodingControllerDelegate

#ifdef APPSTORE
- (void)encodingControllerDidConfirm:(XXTEEncodingController *)controller
{
    [self setCurrentEncoding:controller.selectedEncoding];
    [self setNeedsReloadUI:YES];
    [self setNeedsReloadContent:YES];
    @weakify(self);
    [controller dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
         if (!XXTE_IS_FULLSCREEN(controller)) {
             [self reloadUI];
             [self reloadContent];
             [self reloadLockedState];
         }
    }];
}
#endif

#ifdef APPSTORE
- (void)encodingControllerDidCancel:(XXTEEncodingController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
#endif

#pragma mark - Setters

- (void)setNeedsRefreshNavigationBar {
    self.shouldRefreshNagivationBar = YES;
}

#pragma mark - Helpers

- (NSDictionary *)defaultThemeDictionaryForHLJSCssAtPath:(NSString *)themePath {
    NSData *themeData = [NSData dataWithContentsOfFile:themePath];
    if (!themeData) {
        return nil;
    }
    NSMutableDictionary <NSString *, NSArray <NSString *> *> *hljsCssDict = [NSMutableDictionary dictionary];
    NSString *cssString = [[NSString alloc] initWithData:themeData encoding:NSUTF8StringEncoding];
    NSArray <NSTextCheckingResult *> *hljsBlockResults = [self.hljsCssRegex matchesInString:cssString options:kNilOptions range:NSMakeRange(0, cssString.length)];
    for (NSTextCheckingResult *hljsBlockResult in hljsBlockResults) {
        if (hljsBlockResult.numberOfRanges == 3) {
            NSRange hljsRange = [hljsBlockResult rangeAtIndex:2];
            NSString *hljsBlockStr = [cssString substringWithRange:hljsRange];
            NSArray <NSString *> *hljsBlockLines = [hljsBlockStr componentsSeparatedByString:@";"];
            for (NSString *hljsBlockLine in hljsBlockLines) {
                NSTextCheckingResult *lineCheck = [self.hljsLineCssRegex firstMatchInString:hljsBlockLine options:kNilOptions range:NSMakeRange(0, hljsBlockLine.length)];
                if (lineCheck.numberOfRanges == 3) {
                    NSString *lineKey = [hljsBlockLine substringWithRange:[lineCheck rangeAtIndex:1]];
                    NSString *lineValStr = [hljsBlockLine substringWithRange:[lineCheck rangeAtIndex:2]];
                    NSArray <NSString *> *lineVals = [lineValStr componentsSeparatedByString:@" "];
                    hljsCssDict[lineKey] = lineVals;
                }
            }
        }
    }
    return hljsCssDict;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@synthesize awakeFromOutside = _awakeFromOutside;

@end
