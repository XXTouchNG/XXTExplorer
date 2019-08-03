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
#import "XXTExplorerItemPicker.h"
#import "XXTECodeViewerDefaults.h"
#import "XXTEEditorTextProperties.h"

// Helpers
#import "XXTEEditorEncodingHelper.h"
#import "NSString+HTMLEscape.h"
#import "NSString+Template.h"
#import "UIColor+SKColor.h"
#import "UIColor+hexValue.h"
#import "UIColor+CssColor.h"
#import "XXTECodeViewerController+NavigationBar.h"

@interface XXTECodeViewerController () <XXTECodeViewerSettingsControllerDelegate>

@property (nonatomic, strong) NSRegularExpression *hljsCssRegex;
@property (nonatomic, strong) NSRegularExpression *hljsLineCssRegex;
@property (nonatomic, assign) BOOL shouldRefreshNagivationBar;

@property (nonatomic, strong) UIBarButtonItem *myBackButtonItem;
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;

@property (nonatomic, assign) BOOL needsReloadContent;
@property (nonatomic, assign) BOOL needsReloadUI;

@end

@implementation XXTECodeViewerController

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
        _entryPath = path;
        _hljsCssRegex = [NSRegularExpression regularExpressionWithPattern:@"\\.hljs( +|,+.*?)\\{(.*?)\\}" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
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
        if (foregroundColorString) {
            UIColor *foregroundColor = [UIColor colorWithHex:foregroundColorString];
            if (!foregroundColor) {
                foregroundColor = [UIColor colorWithCssName:foregroundColorString];
            }
            self.view.tintColor = foregroundColor ?: XXTColorDefault();
            self.barTextColor = foregroundColor;
        }
        if (backgroundColorString) {
            UIColor *backgroundColor = [UIColor colorWithHex:backgroundColorString];
            if (!backgroundColor) {
                backgroundColor = [UIColor colorWithCssName:backgroundColorString];
            }
            self.view.backgroundColor = backgroundColor ?: [UIColor whiteColor];
            self.backgroundColor = backgroundColor;
            self.barTintColor = backgroundColor;
        }
    }
    
    // navigation bar
    [self setNeedsRefreshNavigationBar];
}

- (void)reloadContent {
    NSString *entryPath = self.entryPath;
    NSString *entryName = [entryPath lastPathComponent];
    if (self.title.length == 0) {
        if (entryName) {
            self.title = entryName;
        }
    }
    if (!entryName)
    {
        return;
    }
    
    NSError *templateError = nil;
    NSString *htmlTemplate = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"References.bundle/code" ofType:@"html"] encoding:NSUTF8StringEncoding error:&templateError];
    if (templateError) {
        // impossible
        return;
    }
    
    NSError *codecError = nil;
    NSData *codeData = [NSData dataWithContentsOfFile:self.entryPath options:kNilOptions error:&codecError];
    if (!codeData) {
        toastError(self, codecError);
        return;
    }
    NSInteger encodingIndex = XXTEDefaultsInt(XXTExplorerDefaultEncodingKey, 0);
    CFStringEncoding encoding = [XXTEEditorEncodingHelper encodingAtIndex:encodingIndex];
    NSString *encodingName = [XXTEEditorEncodingHelper encodingNameForEncoding:encoding];
    NSString *codeString = CFBridgingRelease(CFStringCreateWithBytes(kCFAllocatorMalloc, codeData.bytes, codeData.length, encoding, NO));
    if (!codeString) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot parse text with \"%@\" encoding: \"%@\".", nil), encodingName, entryPath]);
        return;
    }
    
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
      @"title": entryName,
      @"code": escapedString,
      @"type": highlight ? [NSString stringWithFormat:@"lang-%@", [self.entryPath pathExtension]] : @"nohighlight",
      @"themeLocation": themePath,
      @"gutterColor": [[self.barTextColor colorWithAlphaComponent:.45] cssRGBAString] ?: @"#ddd",
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

#pragma mark - Actions

- (void)settingsButtonItemTapped:(UIBarButtonItem *)sender {
    XXTECodeViewerSettingsController *settingsController = [[XXTECodeViewerSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    settingsController.delegate = self;
    [self.navigationController pushViewController:settingsController animated:YES];
}

- (void)backButtonItemTapped:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - XXTECodeViewerSettingsControllerDelegate

- (void)codeViewerSettingsControllerDidChange:(XXTECodeViewerSettingsController *)controller {
    [self setNeedsReloadContent:YES];
    [self setNeedsReloadUI:YES];
}

- (void)codeViewerNeedsRestoreNavigationBar:(BOOL)restore {
    [self renderNavigationBarTheme:restore];
}

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
