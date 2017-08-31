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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithPath:(NSString *)path {
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    if (self = [super initWithURL:fileURL]) {
        _entryPath = path;
        self.showActionButton = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEWebViewerController dealloc]");
#endif
}

@end
