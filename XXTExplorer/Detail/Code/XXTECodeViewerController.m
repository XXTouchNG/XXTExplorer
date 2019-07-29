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

#import "NSString+HTMLEscape.h"
#import "NSString+Template.h"

@interface XXTECodeViewerController ()

@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;

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
    
    NSString *entryPath = self.entryPath;
    NSString *entryName = [entryPath lastPathComponent];
    if (self.title.length == 0) {
        if (entryName) {
            self.title = entryName;
        }
    }
    
    NSError *templateError = nil;
    NSString *htmlTemplate = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"XXTEMoreReferences.bundle/code" ofType:@"html"] encoding:NSUTF8StringEncoding error:&templateError];
    if (templateError) {
        return;
    }
    NSError *codecError = nil;
    NSString *codeString = [[NSString alloc] initWithContentsOfFile:self.entryPath encoding:NSUTF8StringEncoding error:&codecError];
    if (codecError) {
        return;
    }
    NSString *escapedString = [codeString stringByEscapingHTML];
    if (!escapedString) {
        return;
    }
    if (entryName && escapedString)
    {
        htmlTemplate =
        [htmlTemplate stringByReplacingTagsInDictionary:@{ @"title": entryName, @"code": escapedString, @"type": [self.entryPath pathExtension] }];
    }
    if (self.webView) {
        [self.webView loadHTMLString:htmlTemplate baseURL:[self baseUrl]];
    } else {
        [self.wkWebView loadHTMLString:htmlTemplate baseURL:[self baseUrl]];
    }
    
    self.navigationItem.rightBarButtonItems = @[ self.settingsButtonItem ];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (NSURL *)baseUrl {
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"XXTEMoreReferences.bundle"];
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
    [self.navigationController pushViewController:settingsController animated:YES];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@synthesize awakeFromOutside = _awakeFromOutside;

@end
