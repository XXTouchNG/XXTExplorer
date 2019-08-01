//
//  XXTETextViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTETextViewController.h"
#import "XXTETextReader.h"

#import <LGAlertView/LGAlertView.h>

static NSUInteger const kXXTETextViewControllerMaximumBytes = 256 * 1024; // 200k

@interface XXTETextViewController ()

@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;

@end

@implementation XXTETextViewController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Text Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"txt", @"log", @"ini", @"conf" ];
}

+ (Class)relatedReader {
    return [XXTETextReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
    }
    return self;
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
    self.view.backgroundColor = [UIColor whiteColor];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    self.navigationItem.rightBarButtonItem = self.shareButtonItem;
    
    if (@available(iOS 10.0, *)) {
        [self.contentTextView setRefreshControl:self.refreshControl];
    }
    
    [self.view addSubview:self.contentTextView];
    [self loadTextDataFromEntry];
}

- (void)reloadTextDataFromEntry:(UIRefreshControl *)sender {
    [self loadTextDataFromEntry];
    if ([sender isRefreshing]) {
        [sender endRefreshing];
    }
}

- (void)loadTextDataFromEntry {
    NSString *entryPath = self.entryPath;
    if (!entryPath) {
        return;
    }
    if (0 != access(entryPath.fileSystemRepresentation, W_OK)) {
        [[NSData data] writeToFile:entryPath atomically:YES];
    }
    NSURL *fileURL = [NSURL fileURLWithPath:entryPath];
    NSError *readError = nil;
    NSFileHandle *textHandler = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&readError];
    if (readError) {
        toastError(self, readError);
        return;
    }
    if (!textHandler) {
        return;
    }
    NSData *dataPart = [textHandler readDataOfLength:kXXTETextViewControllerMaximumBytes];
    [textHandler closeFile];
    if (!dataPart) {
        return;
    }
    NSString *stringPart = [[NSString alloc] initWithData:dataPart encoding:NSUTF8StringEncoding];
    if (!stringPart) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot parse text with UTF-8 encoding: \"%@\".", nil), entryPath]);
        return;
    }
    if (stringPart.length == 0) {
        [self.contentTextView setText:[NSString stringWithFormat:NSLocalizedString(@"The content of text file \"%@\" is empty.", nil), entryPath]];
    } else {
        [self.contentTextView setText:stringPart];
    }
    
    [self.contentTextView setSelectedRange:NSMakeRange(0, 0)];
}

#pragma mark - UIView Getters

- (UITextView *)contentTextView {
    if (!_contentTextView) {
        UITextView *logTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
        logTextView.selectable = YES;
        logTextView.scrollsToTop = YES;
        logTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        logTextView.editable = NO;
        logTextView.returnKeyType = UIReturnKeyDefault;
        logTextView.dataDetectorTypes = UIDataDetectorTypeNone;
        logTextView.textAlignment = NSTextAlignmentLeft;
        logTextView.allowsEditingTextAttributes = NO;
        logTextView.tintColor = XXTColorDefault();
        logTextView.alwaysBounceVertical = YES;
        logTextView.font = [UIFont fontWithName:@"Courier" size:12.f];
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 11.0, *)) {
            logTextView.smartDashesType = UITextSmartDashesTypeNo;
            logTextView.smartQuotesType = UITextSmartQuotesTypeNo;
            logTextView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
        } else {
            // Fallback on earlier versions
        }
        XXTE_END_IGNORE_PARTIAL
        _contentTextView = logTextView;
    }
    return _contentTextView;
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(reloadTextDataFromEntry:) forControlEvents:UIControlEventValueChanged];
        _refreshControl = refreshControl;
    }
    return _refreshControl;
}

- (UIBarButtonItem *)shareButtonItem {
    if (!_shareButtonItem) {
        UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped:)];
        _shareButtonItem = shareButtonItem;
    }
    return _shareButtonItem;
}

#pragma mark - Actions

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

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@synthesize awakeFromOutside = _awakeFromOutside;

@end
