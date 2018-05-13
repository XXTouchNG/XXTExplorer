//
//  XXTESnippetViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 26/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESnippetViewerController.h"
#import "XXTExplorerEntrySnippetReader.h"

#import "XXTPickerSnippet.h"
#import "XXTPickerFactory.h"

@interface XXTESnippetViewerController () <XXTPickerFactoryDelegate>

@property (nonatomic, strong) UIBarButtonItem *launchItem;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.applicationBarButtonItems = @[ self.launchItem ];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)launchItem {
    if (!_launchItem) {
        _launchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(launchItemTapped:)];
    }
    return _launchItem;
}

#pragma mark - Actions

- (void)launchItemTapped:(UIBarButtonItem *)sender {
    NSString *path = self.entryPath;
    NSError *initError = nil;
    XXTPickerSnippet *snippet = [[XXTPickerSnippet alloc] initWithContentsOfFile:path Error:&initError];
    if (initError) {
        toastError(self, initError);
        return;
    }
    XXTPickerFactory *pickerFactory = [XXTPickerFactory sharedInstance];
    pickerFactory.delegate = self;
    [pickerFactory executeTask:snippet fromViewController:self];
}

#pragma mark - XXTPickerFactoryDelegate

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldEnterNextStep:(XXTPickerSnippet *)task {
    return YES;
}

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldFinished:(XXTPickerSnippet *)task {
    UIViewController *blockVC = blockInteractions(self, YES);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error = nil;
        NSString *taskResult = nil;
        id result = [task generateWithError:&error];
        if ([result isKindOfClass:[NSString class]]) {
            taskResult = result;
        } else if ([result respondsToSelector:@selector(description)]) {
            taskResult = [result description];
        }
        dispatch_async_on_main_queue(^{
            blockInteractions(blockVC, NO);
            if (taskResult) {
                [self copyResult:taskResult fromTask:task];
            } else if (error) {
                toastError(self, error);
            } else {
                toastMessage(self, NSLocalizedString(@"Cannot generate code snippet: unknown error.", nil));
            }
        });
    });
    return YES;
}

- (void)copyResult:(NSString *)result fromTask:(XXTPickerSnippet *)task
{
    if (task.output.length == 0)
    {
        toastMessage(self, NSLocalizedString(@"Cannot generate code snippet because template table field \"output\" is undefined or empty.", nil));
        return;
    }
    
    NSError *writeError = nil;
    NSString *parentPath = [self.entryPath stringByDeletingLastPathComponent];
    NSString *writeToPath = [parentPath stringByAppendingPathComponent:task.output];
    BOOL writeResult = [result writeToFile:writeToPath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    if (!writeResult) {
        if (writeError) {
            toastError(self, writeError);
        }
        return;
    }
    
    toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Generated code snippet has been saved to \"%@\".", nil), task.output]);
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTESnippetViewerController dealloc]");
#endif
}

@end
