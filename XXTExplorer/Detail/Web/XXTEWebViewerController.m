//
//  XXTEWebViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEWebViewerController.h"
#import "XXTExplorerEntryWebReader.h"

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

- (instancetype)initWithPath:(NSString *)path {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (self = [super initWithURL:fileURL]) {
        _entryPath = path;
        if (@available(iOS 9.0, *)) {
            self.showActionButton = YES;
        } else {
            self.showActionButton = NO;
        }
    }
    return self;
}

- (NSURL *)preprocessLocalFileForWKWebView:(NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *reachableError = nil;
    NSURL *tmpDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
    BOOL reachable = [fileURL checkResourceIsReachableAndReturnError:&reachableError];
    if (reachable) {
        NSError *createTmpError = nil;
        [fileManager createDirectoryAtURL:tmpDirURL withIntermediateDirectories:YES attributes:nil error:&createTmpError];
        if (createTmpError) { return fileURL; }
        NSString *randomStr = [[NSUUID UUID] UUIDString];
        NSURL *dstURL = [tmpDirURL URLByAppendingPathComponent:randomStr];
        [fileManager createDirectoryAtURL:dstURL withIntermediateDirectories:YES attributes:nil error:&createTmpError];
        if (createTmpError) { return fileURL; }
        NSURL *newFileURL = [dstURL URLByAppendingPathComponent:fileURL.lastPathComponent];
        NSError *moveError = nil;
        BOOL fileMoved = [fileManager copyItemAtURL:fileURL toURL:newFileURL error:&moveError];
        if (fileMoved) {
            return dstURL;
        }
    }
    return fileURL;
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
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEWebViewerController dealloc]");
#endif
}

@synthesize awakeFromOutside = _awakeFromOutside;

@end
