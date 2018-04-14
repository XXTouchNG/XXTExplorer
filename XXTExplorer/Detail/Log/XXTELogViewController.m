//
//  XXTELogViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTELogViewController.h"
#import "XXTELogReader.h"

#import <LGAlertView/LGAlertView.h>

static NSUInteger const kXXTELogViewControllerMaximumBytes = 256 * 1024; // 200k

@interface XXTELogViewController ()

@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) UIBarButtonItem *clearItem;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation XXTELogViewController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Log Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"log" ];
}

+ (Class)relatedReader {
    return [XXTELogReader class];
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
    self.navigationItem.rightBarButtonItem = self.clearItem;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    if (@available(iOS 10.0, *)) {
        [self.logTextView setRefreshControl:self.refreshControl];
    }
    
    [self.view addSubview:self.logTextView];
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
    NSData *dataPart = [textHandler readDataOfLength:kXXTELogViewControllerMaximumBytes];
    [textHandler closeFile];
    if (!dataPart) {
        return;
    }
    NSString *stringPart = [[NSString alloc] initWithData:dataPart encoding:NSUTF8StringEncoding];
    if (!stringPart) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot parse log with UTF-8 encoding: \"%@\".", nil), entryPath]);
        return;
    }
    if (stringPart.length == 0) {
        [self.clearItem setEnabled:NO];
        [self.logTextView setText:[NSString stringWithFormat:NSLocalizedString(@"The content of log file \"%@\" is empty.", nil), entryPath]];
    } else {
        [self.clearItem setEnabled:YES];
        [self.logTextView setText:stringPart];
    }
    
    [self.logTextView setSelectedRange:NSMakeRange(0, 0)];
}

#pragma mark - UIView Getters

- (UITextView *)logTextView {
    if (!_logTextView) {
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
        logTextView.font = [UIFont fontWithName:@"CourierNewPSMT" size:12.f];
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 11.0, *)) {
            logTextView.smartDashesType = UITextSmartDashesTypeNo;
            logTextView.smartQuotesType = UITextSmartQuotesTypeNo;
            logTextView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
        } else {
            // Fallback on earlier versions
        }
        XXTE_END_IGNORE_PARTIAL
        _logTextView = logTextView;
    }
    return _logTextView;
}

- (UIBarButtonItem *)clearItem {
    if (!_clearItem) {
        UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear", nil) style:UIBarButtonItemStylePlain target:self action:@selector(clearItemTapped:)];
        _clearItem = clearItem;
    }
    return _clearItem;
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(reloadTextDataFromEntry:) forControlEvents:UIControlEventValueChanged];
        _refreshControl = refreshControl;
    }
    return _refreshControl;
}

#pragma mark - Actions

- (void)clearItemTapped:(UIBarButtonItem *)sender {
    NSString *entryPath = self.entryPath;
    if (!entryPath) {
        return;
    }
    LGAlertView *clearAlert = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clear Confirm", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Remove all logs in \"%@\"?", nil), entryPath] style:LGAlertViewStyleActionSheet buttonTitles:@[ ] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Clear Now", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
        [[NSData data] writeToFile:entryPath atomically:YES];
        [self loadTextDataFromEntry];
    }];
    [clearAlert showAnimated];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTELogViewController dealloc]");
#endif
}

@synthesize awakeFromOutside;

@end
