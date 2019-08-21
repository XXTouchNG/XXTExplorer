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
#import "XXTPickerSnippetTask.h"
#import "XXTPickerFactory.h"

#import "XXTExplorerEntry.h"
#import "XXTExplorerEntryParser.h"
#import "XXTESingleActionView.h"

@interface XXTESnippetViewerController () <XXTPickerFactoryDelegate>

@property (nonatomic, strong) XXTESingleActionView *actionView;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;
@property (nonatomic, strong) id taskResult;

@end

@implementation XXTESnippetViewerController

@synthesize entryPath = _entryPath;
@synthesize awakeFromOutside = _awakeFromOutside;

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
    }
    return self;
}

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
    if (self.title.length == 0) {
        if (self.entryPath) {
            NSString *entryName = [self.entryPath lastPathComponent];
            self.title = entryName;
        } else {
            self.title = [[self class] viewerName];
        }
    }
    
    self.view.backgroundColor = XXTColorPlainBackground();
    
    {
        XXTESingleActionView *actionView = self.actionView;
        NSError *parseError = nil;
        XXTExplorerEntryParser *parser = [[XXTExplorerEntryParser alloc] init];
        XXTExplorerEntry *entry = [parser entryOfPath:self.entryPath withError:&parseError];
        actionView.titleLabel.text = [entry localizedDisplayName];
        actionView.descriptionLabel.text = [entry localizedDescription];
        [self.view addSubview:actionView];
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    self.navigationItem.rightBarButtonItem = self.shareButtonItem;
}

#pragma mark - UIView Getters

- (XXTESingleActionView *)actionView {
    if (!_actionView) {
        XXTESingleActionView *actionView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTESingleActionView class]) owner:nil options:nil] lastObject];
        actionView.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0);
        actionView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        actionView.iconImageView.image = [XXTExplorerEntrySnippetReader defaultImage];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchItemTapped:)];
        [actionView addGestureRecognizer:tapGesture];
        _actionView = actionView;
    }
    return _actionView;
}

- (UIBarButtonItem *)shareButtonItem {
    if (!_shareButtonItem) {
        UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped:)];
        _shareButtonItem = shareButtonItem;
    }
    return _shareButtonItem;
}

#pragma mark - Actions

- (void)launchItemTapped:(UIGestureRecognizer *)sender {
    NSString *path = self.entryPath;
    NSError *initError = nil;
    XXTPickerSnippet *snippet = [[XXTPickerSnippet alloc] initWithContentsOfFile:path Error:&initError];
    if (initError) {
        toastError(self, initError);
        return;
    }
    if (snippet.output.length == 0)
    {
        toastMessage(self, NSLocalizedString(@"Cannot generate code snippet because template table field \"output\" is undefined or empty.", nil));
        return;
    }
    XXTPickerSnippetTask *task = [[XXTPickerSnippetTask alloc] initWithSnippet:snippet];
    XXTPickerFactory *pickerFactory = [XXTPickerFactory sharedInstance];
    pickerFactory.delegate = self;
    [pickerFactory beginTask:task fromViewController:self];
}

- (void)shareButtonItemTapped:(UIBarButtonItem *)sender {
    if (!self.entryPath) return;
    NSURL *shareUrl = [NSURL fileURLWithPath:self.entryPath];
    if (!shareUrl) return;
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ shareUrl ] applicationActivities:nil];
        if (XXTE_IS_IPAD) {
            activityViewController.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
            popoverPresentationController.barButtonItem = sender;
        }
        [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
    } else {
        toastMessage(self, NSLocalizedString(@"This feature requires iOS 9.0 or later.", nil));
    }
    XXTE_END_IGNORE_PARTIAL
}

#pragma mark - XXTPickerFactoryDelegate

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldEnterNextStep:(XXTPickerSnippetTask *)task {
    return YES;
}

- (void)pickerFactory:(XXTPickerFactory *)factory taskShouldFinished:(XXTPickerSnippetTask *)task responseBlock:(void (^)(BOOL, NSError *))responseCallback {
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
                self.taskResult = taskResult;
                responseCallback(YES, nil);
            } else {
                // toastError(self, error);
                responseCallback(NO, error);
            }
        });
    });
}

- (void)pickerFactory:(XXTPickerFactory *)factory taskDidFinished:(XXTPickerSnippetTask *)task
{
    [self copyResult:self.taskResult fromTask:task];
}

- (void)copyResult:(NSString *)result fromTask:(XXTPickerSnippetTask *)task
{
    if (task.snippet.output.length == 0)
    {
        return;
    }
    
    NSError *writeError = nil;
    NSString *parentPath = [self.entryPath stringByDeletingLastPathComponent];
    NSString *writeToPath = [parentPath stringByAppendingPathComponent:task.snippet.output];
    BOOL writeResult = [result writeToFile:writeToPath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    if (!writeResult) {
        if (writeError) {
            toastError(self, writeError);
        }
        return;
    }
    
    toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Generated code snippet has been saved to \"%@\".", nil), task.snippet.output]);
    self.taskResult = nil;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
