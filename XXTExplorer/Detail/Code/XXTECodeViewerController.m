//
//  XXTECodeViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTECodeViewerController.h"
#import "XXTExplorerEntryCodeReader.h"

#import "NSString+HTMLEscape.h"

@interface XXTECodeViewerController ()

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
        if (path) {
            self.url = [NSURL fileURLWithPath:path];
        }
        self.showActionButton = YES;
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
    NSMutableString *htmlTemplate = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"XXTEMoreReferences.bundle/code" ofType:@"html"] encoding:NSUTF8StringEncoding error:&templateError];
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
    [htmlTemplate replaceOccurrencesOfString:@"{{ title }}" withString:entryName options:0 range:NSMakeRange(0, htmlTemplate.length)];
    [htmlTemplate replaceOccurrencesOfString:@"{{ code }}" withString:escapedString options:0 range:NSMakeRange(0, htmlTemplate.length)];
    if (self.webView) {
        [self.webView loadHTMLString:htmlTemplate baseURL:[self baseUrl]];
    } else {
        [self.wkWebView loadHTMLString:htmlTemplate baseURL:[self baseUrl]];
    }

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (NSURL *)baseUrl {
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"XXTEMoreReferences.bundle"];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTECodeViewerController dealloc]");
#endif
}

@synthesize awakeFromOutside;

@end
