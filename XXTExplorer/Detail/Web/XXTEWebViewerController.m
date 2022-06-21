//
//  XXTEWebViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEWebViewerController.h"
#import "XXTExplorerEntryWebReader.h"
#import "XXTExplorerDefaults.h"

@interface XXTEWebViewerController ()

@end

@implementation XXTEWebViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Web Browser", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"html", @"pdf", @"doc", @"docx", @"xls", @"xlsx", @"ppt", @"pptx", @"rtf" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryWebReader class];
}

+ (NSString *)cachesPath {
    static NSString *cachesPath = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!cachesPath) {
            cachesPath = ({
                NSString *relativePath = uAppDefine(XXTExplorerViewBuiltCachesPath);
                [XXTERootPath() stringByAppendingPathComponent:relativePath];
            });
        }
    });
    return cachesPath;
}

- (instancetype)initWithPath:(NSString *)path {
    NSURL *fileURL = [self preprocessLocalFileForWKWebView:[NSURL fileURLWithPath:path]];
    if (!fileURL)
        return nil;
    if (self = [super initWithURL:fileURL]) {
        _entryPath = path;
    }
    return self;
}

- (NSURL *)preprocessLocalFileForWKWebView:(NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *reachableError = nil;
    NSURL *tmpDirURL = [[NSURL fileURLWithPath:[[self class] cachesPath]] URLByAppendingPathComponent:@"www"];
    BOOL reachable = [fileURL checkResourceIsReachableAndReturnError:&reachableError];
    if (!reachable) {
        return nil;
    }
    NSError *createTmpError = nil;
    [fileManager createDirectoryAtURL:tmpDirURL withIntermediateDirectories:YES attributes:nil error:&createTmpError];
    if (createTmpError) {
        return nil;
    }
    NSString *randomStr = [[NSUUID UUID] UUIDString];
    NSURL *dstURL = [tmpDirURL URLByAppendingPathComponent:randomStr];
    [fileManager createDirectoryAtURL:dstURL withIntermediateDirectories:YES attributes:nil error:&createTmpError];
    if (createTmpError) {
        return nil;
    }
    NSURL *newFileURL = [dstURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    NSError *moveError = nil;
    BOOL fileMoved = [fileManager copyItemAtURL:fileURL toURL:newFileURL error:&moveError];
    if (!fileMoved) {
        return nil;
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@caches/www/%@/%@", uAppDefine(@"LOCAL_API"), randomStr, [fileURL.lastPathComponent stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]]];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.title.length == 0) {
        NSString *entryPath = self.entryPath;
        if (entryPath) {
            NSString *entryName = [entryPath lastPathComponent];
            self.title = entryName;
        }
    }
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
