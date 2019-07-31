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

#import "NSString+HTMLEscape.h"
#import "NSString+Template.h"

@interface XXTECodeViewerController () <XXTECodeViewerSettingsControllerDelegate>
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;
@property (nonatomic, assign) BOOL needsReload;

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
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (self = [super initWithURL:fileURL]) {
        _entryPath = path;
        self.navigationButtonsHidden = YES;
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
    
    self.applicationBarButtonItems = @[ self.settingsButtonItem ];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self loadContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.needsReload) {
        [self loadContent];
        [self setNeedsReload:NO];
    }
}

- (void)loadContent {
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
        return;
    }
    
    NSError *codecError = nil;
    NSString *codeString = [[NSString alloc] initWithContentsOfFile:self.entryPath encoding:NSUTF8StringEncoding error:&codecError];
    if (codecError) {
        return;
    }
    
    NSString *escapedString = [codeString stringByEscapingHTML];
    if (!escapedString)
    {
        return;
    }
    
    // theme
    NSString *themeName = XXTEDefaultsObject(XXTECodeViewerThemeName, @"xcode");
    NSString *cssPath =
    [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"References.bundle/hljs/styles/%@", themeName] ofType:@"css"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cssPath]) {
        themeName = @"xcode";
    }
    BOOL highlight = XXTEDefaultsBool(XXTECodeViewerHighlightEnabled, YES);
    
    // font
    NSString *fontName = XXTEDefaultsObject(XXTECodeViewerFontName, @"CourierNewPSMT");
    NSNumber *fontSize = XXTEDefaultsObject(XXTECodeViewerFontSize, @(12.0));
    
    NSDictionary *settingsDict =
    @{
      @"title": entryName,
      @"code": escapedString,
      @"type": highlight ? [NSString stringWithFormat:@"lang-%@", [self.entryPath pathExtension]] : @"nohighlight",
      @"themeLocation": [NSString stringWithFormat:@"hljs/styles/%@.css", themeName],
      @"fontName": [NSString stringWithFormat:@"\"%@\", monospace", fontName],
      @"fontSize": [NSString stringWithFormat:@"%@px", fontSize],
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

#pragma mark - Actions

- (void)settingsButtonItemTapped:(UIBarButtonItem *)sender {
    XXTECodeViewerSettingsController *settingsController = [[XXTECodeViewerSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    settingsController.delegate = self;
    [self.navigationController pushViewController:settingsController animated:YES];
}

#pragma mark - XXTECodeViewerSettingsControllerDelegate

- (void)codeViewerSettingsControllerDidChange:(XXTECodeViewerSettingsController *)controller
{
    [self setNeedsReload:YES];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@synthesize awakeFromOutside = _awakeFromOutside;

@end
