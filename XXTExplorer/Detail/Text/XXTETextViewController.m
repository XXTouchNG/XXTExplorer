//
//  XXTETextViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTETextViewController.h"
#import "XXTETextReader.h"

// Helpers
#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEEncodingHelper.h"
#import "XXTETextPreprocessor.h"

// Views
#import "XXTESingleActionView.h"
#import "ICTextView.h"
#import <LGAlertView/LGAlertView.h>

// Children
#import "XXTEEncodingController.h"
#import "XXTENavigationController.h"


static NSUInteger const kXXTETextViewControllerMaximumBytes = 256 * 1024; // 200k

@interface XXTETextViewController ()

@property (nonatomic, strong) XXTESingleActionView *actionView;
@property (nonatomic, strong) ICTextView *contentTextView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;

@property (nonatomic, assign) BOOL needsReload;

@end

@implementation XXTETextViewController {
    BOOL _lockedState;
}

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Text Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"txt", @"conf" ];
}

+ (Class)relatedReader {
    return [XXTETextReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        _lockedState = NO;
        _needsReload = NO;
        _currentEncoding = kCFStringEncodingInvalidId;
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
    self.view.backgroundColor = XXTColorPlainBackground();
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.rightBarButtonItem = self.shareButtonItem;
    
    [self.contentTextView setRefreshControl:self.refreshControl];
    [self.view addSubview:self.contentTextView];
    self.actionView.iconImageView.image = [UIImage imageNamed:@"XXTEBugIcon"];
    
    [self reloadTextDataFromEntry];
    [self reloadLockedState];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadIfNeeded];
    [self reloadLockedState];
}

#pragma mark - Loaders

- (void)reloadLockedState {
    BOOL isLockedState = self.isLockedState;
    if (isLockedState)
    {
        if (![self.view.subviews containsObject:self.actionView])
        {
            [self.view addSubview:self.actionView];
        }
        [self.contentTextView setHidden:YES];
    }
    else
    {
        [self.contentTextView setHidden:NO];
        [self.actionView removeFromSuperview];
    }
}

- (void)reloadIfNeeded {
    if (self.needsReload) {
        self.needsReload = NO;
        [self reloadTextDataFromEntry];
    }
}

- (void)reloadTextDataFromEntry:(UIRefreshControl *)sender {
    [self reloadTextDataFromEntry];
    if ([sender isRefreshing]) {
        [sender endRefreshing];
    }
}

- (void)reloadTextDataFromEntry {
    NSString *entryPath = self.entryPath;
    if (!entryPath) {
        return;
    }
    
    NSUInteger maximumLength = kXXTETextViewControllerMaximumBytes;
    CFStringEncoding tryEncoding = [self currentEncoding];
    NSError *readError = nil;
    NSString *stringPart = [XXTETextPreprocessor preprocessedStringWithContentsOfFile:entryPath NumberOfLines:NULL Encoding:&tryEncoding LineBreak:NULL MaximumLength:&maximumLength Error:&readError];
    
    if (!stringPart) {
        [self setLockedState:YES];
        if ([readError.domain isEqualToString:kXXTErrorInvalidStringEncodingDomain]) {
            self.actionView.titleLabel.text = NSLocalizedString(@"Bad Encoding", nil);
            self.actionView.descriptionLabel.text = readError.localizedDescription ?: NSLocalizedString(@"Unknown reason.", nil);
        } else {
            self.actionView.titleLabel.text = NSLocalizedString(@"Error", nil);
            self.actionView.descriptionLabel.text = readError.localizedDescription ?: NSLocalizedString(@"Unknown reason.", nil);
        }
        return;
    } else {
        [self setLockedState:NO];
    }
    [self setCurrentEncoding:tryEncoding];

    if (stringPart.length == 0) {
        [self.contentTextView setText:[NSString stringWithFormat:NSLocalizedString(@"The content of text file \"%@\" is empty.", nil), entryPath.lastPathComponent]];
    } else {
        [self.contentTextView setText:stringPart];
    }
    
    [self.contentTextView setSelectedRange:NSMakeRange(0, 0)];
}

#pragma mark - Getters

- (BOOL)isLockedState {
    return _lockedState;
}

#pragma mark - UIView Getters

- (ICTextView *)contentTextView {
    if (!_contentTextView) {
        ICTextView *logTextView = [[ICTextView alloc] initWithFrame:self.view.bounds];
        logTextView.selectable = YES;
        logTextView.scrollsToTop = YES;
        logTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        logTextView.editable = NO;
        logTextView.returnKeyType = UIReturnKeyDefault;
        logTextView.dataDetectorTypes = UIDataDetectorTypeNone;
        logTextView.textAlignment = NSTextAlignmentLeft;
        logTextView.allowsEditingTextAttributes = NO;
        logTextView.tintColor = XXTColorForeground();
        logTextView.textColor = XXTColorPlainTitleText();
        logTextView.alwaysBounceVertical = YES;
        logTextView.font = [UIFont fontWithName:@"Courier" size:12.f];
        XXTE_START_IGNORE_PARTIAL
        logTextView.smartDashesType = UITextSmartDashesTypeNo;
        logTextView.smartQuotesType = UITextSmartQuotesTypeNo;
        logTextView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
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

- (XXTESingleActionView *)actionView {
    if (!_actionView) {
        XXTESingleActionView *actionView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTESingleActionView class]) owner:nil options:nil] lastObject];
        actionView.frame = self.view.bounds;
        actionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionViewTapped:)];
        [actionView addGestureRecognizer:tapGesture];
        _actionView = actionView;
    }
    return _actionView;
}

#pragma mark - Actions

- (void)shareButtonItemTapped:(UIBarButtonItem *)sender {
    if (!self.entryPath) return;
    NSURL *shareUrl = [NSURL fileURLWithPath:self.entryPath];
    if (!shareUrl) return;
    XXTE_START_IGNORE_PARTIAL
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ shareUrl ] applicationActivities:nil];
    if (XXTE_IS_IPAD) {
        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        popoverPresentationController.barButtonItem = sender;
    }
    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
    XXTE_END_IGNORE_PARTIAL
}

- (void)actionViewTapped:(XXTESingleActionView *)actionView {
    
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
