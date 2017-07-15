//
//  XXTECodeViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTECodeViewerController.h"
#import "NSString+HTMLEscape.h"
#import "XXTExplorerEntryCodeReader.h"

@interface XXTECodeViewerController ()

@end

@implementation XXTECodeViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return @"Code Viewer";
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
              ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryCodeReader class];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        self.showActionButton = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *entryPath = self.entryPath;
    NSString *entryName = [entryPath lastPathComponent];
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
//    NSString *writePath = [self pathForTemporaryFileWithPrefix:NSStringFromClass(self.class)];
//    NSError *writeError = nil;
//    [htmlTemplate writeToFile:writePath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
//    if (writeError) {
//        return;
//    }
//    NSURL *newFileUrl = [NSURL fileURLWithPath:writePath];
    [self.webView loadHTMLString:htmlTemplate baseURL:[self baseUrl]];
}

- (NSURL *)baseUrl {
    return [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"XXTEMoreReferences.bundle"];
}

//- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix
//{
//    NSString *  result;
//    CFUUIDRef   uuid;
//    CFStringRef uuidStr;
//    
//    uuid = CFUUIDCreate(NULL);
//    assert(uuid != NULL);
//    
//    uuidStr = CFUUIDCreateString(NULL, uuid);
//    assert(uuidStr != NULL);
//    
//    result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.html", prefix, uuidStr]];
//    assert(result != nil);
//    
//    CFRelease(uuidStr);
//    CFRelease(uuid);
//    
//    return result;
//}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTECodeViewerController dealloc]");
#endif
}

@end
