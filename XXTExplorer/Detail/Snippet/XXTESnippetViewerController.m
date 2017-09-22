//
//  XXTESnippetViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESnippetViewerController.h"
#import "XXTExplorerEntrySnippetReader.h"

@interface XXTESnippetViewerController ()

@end

@implementation XXTESnippetViewerController

+ (NSString *)viewerName {
    return NSLocalizedString(@"Snippet Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"snippet" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntrySnippetReader class];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTESnippetViewerController dealloc]");
#endif
}

@end
