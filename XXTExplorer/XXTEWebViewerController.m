//
//  XXTEWebViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEWebViewerController.h"

@interface XXTEWebViewerController ()

@end

@implementation XXTEWebViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return @"Web Viewer";
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"html", @"pdf" ];
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

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEWebViewerController dealloc]");
#endif
}

@end
