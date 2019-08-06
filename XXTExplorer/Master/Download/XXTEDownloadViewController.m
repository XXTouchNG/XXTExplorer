//
// Created by Zheng on 11/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import "XXTEDownloadViewController.h"
#import "XXTEMoreAddressCell.h"
#import "XXTEMoreLinkCell.h"
#import "XXTEMoreSwitchCell.h"
#import <LGAlertView/LGAlertView.h>
#import <PromiseKit/PromiseKit.h>
#import "UIControl+BlockTarget.h"
#import "NSString+XQueryComponents.h"
#import "XXTExplorerViewController+SharedInstance.h"


typedef enum : NSUInteger {
    kXXTExplorerDownloadViewSectionIndexSource = 0,
    kXXTExplorerDownloadViewSectionIndexTarget,
    kXXTExplorerDownloadViewSectionIndexMax
} kXXTExplorerCreateItemViewSectionIndex;

@interface XXTEDownloadViewController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate, LGAlertViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *downloadButtonItem;

@property (nonatomic, strong, readonly) NSURL *sourceURL;
@property (nonatomic, copy, readonly) NSString *targetPath;

@property (nonatomic, copy, readonly) NSString *temporarilyPath;
@property (nonatomic, assign) BOOL overwrite;

@property (nonatomic, strong, readonly) NSFileManager *downloadFileManager;
//@property (nonatomic, strong, readonly) NSMutableData *downloadData;
@property (nonatomic, strong) NSFileHandle *downloadFileHandle;
@property (nonatomic, strong) NSURLConnection *downloadURLConnection;
@property (nonatomic, weak) LGAlertView *currentAlertView;
@property (nonatomic, weak) UIViewController *blockController;

@property (nonatomic, strong) NSURLConnection *pretestConnection;

/*
@property (nonatomic, assign) BOOL viewImmediately;
 */

@end

@implementation XXTEDownloadViewController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
    BOOL busyOperationProgressFlag;
    long long expectedFileSize;
    long long receivedFileSize;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype) initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithSourceURL:(NSURL *)url targetPath:(NSString *)path {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _sourceURL = url;
        NSString *newPath = path;
        NSString *initialPath = [XXTExplorerViewController initialPath];
        if (path.length == 0)
        {
            NSString *initialName = [url lastPathComponent];
            newPath = [initialPath stringByAppendingPathComponent:initialName];
        }
        else if (NO == [path isAbsolutePath])
        {
            NSString *initialName = [path mutableCopy];
            newPath = [initialPath stringByAppendingPathComponent:[initialName copy]];
        }
        _targetPath = newPath;
        _temporarilyPath = [newPath stringByAppendingPathExtension:@"xxtdownload"];
        [self setup];
    }
    return self;
}

- (void)setup {
//    _viewImmediately = YES;
    busyOperationProgressFlag = NO;
    _downloadFileManager = [[NSFileManager alloc] init];
//    _downloadData = [[NSMutableData alloc] initWithLength:0];
    _downloadFileHandle = nil;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"Download", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if ([self.navigationController.viewControllers firstObject] == self) {
        self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    }
    self.navigationItem.rightBarButtonItem = self.downloadButtonItem;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self reloadStaticTableViewData];
    if (self.allowsAutoDetection) {
        [self performPretest];
    } else {
        [self skipPretest];
    }
}

- (void)fixTargetPathWithFileName:(NSString *)filename {
    NSString *targetParentPath = [self.targetPath stringByDeletingLastPathComponent];
    NSString *fixedTargetPath = [targetParentPath stringByAppendingPathComponent:filename];
    _targetPath = fixedTargetPath;
    [self reloadStaticTableViewData];
    [self.tableView reloadData];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ NSLocalizedString(@"Source URL", nil),
                             NSLocalizedString(@"Target Path", nil)
                             ];
    staticSectionFooters = @[ @"", NSLocalizedString(@"Please confirm these information.\n\nThe data source is provided by third party author. If you encounter a problem, please contact its author by the contact details under the previous page. Tap \"Save\" if you can make sure that the source is trusted.", nil) ];
    
    XXTEMoreAddressCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell1.addressLabel.text = [self.sourceURL absoluteString];
    
    XXTEMoreAddressCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell2.addressLabel.text = self.targetPath;
    
    /*
    XXTEMoreSwitchCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Instant View / Run", nil);
    cell3.optionSwitch.on = self.viewImmediately;
    {
        @weakify(self);
        [cell3.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
            @strongify(self);
            self.viewImmediately = ((UISwitch *)sender).on;
        }];
    }
    */
    
    staticCells = @[
                    @[ cell1 ],
                    @[ cell2, /* cell3 */ ]
                    ];
}

- (void)performPretest {
    self.downloadButtonItem.enabled = NO;
    self.blockController = blockInteractions(self, YES);
    NSURL *sourceURL = self.sourceURL;
    NSMutableURLRequest *headReq = [[NSMutableURLRequest alloc] initWithURL:sourceURL];
    [headReq setHTTPMethod:@"HEAD"];
    NSURLConnection *headConnection = [[NSURLConnection alloc] initWithRequest:headReq delegate:self startImmediately:NO];
    self.pretestConnection = headConnection;
    [headConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [headConnection start];
}

- (void)skipPretest {
    self.downloadButtonItem.enabled = YES;
    self.pretestConnection = nil;
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeButtonItem {
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissViewController:)];
        closeButtonItem.tintColor = [UIColor whiteColor];
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

- (UIBarButtonItem *)downloadButtonItem {
    if (!_downloadButtonItem) {
        UIBarButtonItem *downloadButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(confirmDownload:)];
        downloadButtonItem.tintColor = [UIColor whiteColor];
        downloadButtonItem.enabled = NO;
        _downloadButtonItem = downloadButtonItem;
    }
    return _downloadButtonItem;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTExplorerDownloadViewSectionIndexMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticCells[(NSUInteger) section].count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (@available(iOS 8.0, *)) {
            return UITableViewAutomaticDimension;
        } else {
            UITableViewCell *cell = staticCells[indexPath.section][indexPath.row];
            [cell setNeedsUpdateConstraints];
            [cell updateConstraintsIfNeeded];
            
            cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
            [cell setNeedsLayout];
            [cell layoutIfNeeded];
            
            CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            return (height > 0) ? (height + 1.0) : 44.f;
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerDownloadViewSectionIndexSource) {
            if (indexPath.row == 0) {
                NSString *detailText = ((XXTEMoreAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
                if (detailText && detailText.length > 0) {
                    UIViewController *blockVC = blockInteractions(self, YES);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:detailText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        toastMessage(self, NSLocalizedString(@"Source URL has been copied to the pasteboard.", nil));
                        blockInteractions(blockVC, NO);
                    });
                }
            }
        }
        else if (indexPath.section == kXXTExplorerDownloadViewSectionIndexTarget) {
            if (indexPath.row == 0) {
                NSString *detailText = ((XXTEMoreAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
                if (detailText && detailText.length > 0) {
                    UIViewController *blockVC = blockInteractions(self, YES);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:detailText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        toastMessage(self, NSLocalizedString(@"Target Path has been copied to the pasteboard.", nil));
                        blockInteractions(blockVC, NO);
                    });
                }
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionTitles[(NSUInteger) section];
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionFooters[(NSUInteger) section];
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        UITableViewCell *cell = staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UIControl Actions

- (void)dismissViewController:(id)sender {
    if (!XXTE_IS_FULLSCREEN(self)) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)confirmDownload:(id)sender {
    NSString *targetPath = self.targetPath;
    NSString *targetName = [targetPath lastPathComponent];
    struct stat targetStat;
    if (0 == lstat([targetPath fileSystemRepresentation], &targetStat)) {
        @weakify(self);
        LGAlertView *existsAlertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Overwrite Confirm", nil)
                                                                  message:[NSString stringWithFormat:NSLocalizedString(@"File \"%@\" exists, overwrite or rename it?", nil), targetName]
                                                                    style:LGAlertViewStyleActionSheet
                                                             buttonTitles:@[ NSLocalizedString(@"Rename", nil) ]
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                   destructiveButtonTitle:NSLocalizedString(@"Overwrite", nil)
                                                            actionHandler:^(LGAlertView * _Nonnull alertView1, NSUInteger index, NSString * _Nullable title) {
                                                                @strongify(self);
                                                                [alertView1 dismissAnimated];
                                                                if (index == 0)
                                                                {
                                                                    self.overwrite = NO;
                                                                    [self alertViewLaunch:alertView1];
                                                                }
                                                            } cancelHandler:^(LGAlertView * _Nonnull alertView1) {
                                                                [alertView1 dismissAnimated];
                                                            } destructiveHandler:^(LGAlertView * _Nonnull alertView1) {
                                                                @strongify(self);
                                                                self.overwrite = YES;
                                                                [self alertViewLaunch:alertView1];
                                                            }];
        [existsAlertView showAnimated];
    } else {
        [self alertViewLaunch:nil];
    }
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    if (busyOperationProgressFlag) {
        NSURLConnection *currentConnection = self.downloadURLConnection;
        if (currentConnection) {
            [currentConnection cancel];
            [self connection:currentConnection didFailWithError:[NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Download terminated: user interrupt occurred.", nil)}]];
            self.downloadURLConnection = nil;
        }
        busyOperationProgressFlag = NO;
    } else {
        [alertView dismissAnimated];
    }
}

- (void)alertView:(LGAlertView *)alertView clickedButtonAtIndex:(NSUInteger)index title:(NSString *)title
{
    if (index == 0 || index == 1) {
        [alertView dismissAnimated];
        if (!XXTE_IS_FULLSCREEN(self)) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
        }
        BOOL instantRun = (index == 0);
        @weakify(self);
        [self dismissViewControllerAnimated:YES completion:^{
            @strongify(self);
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self.targetPath userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeInboxMoved, XXTENotificationViewImmediately: @(instantRun)}]];
        }];
    }
}

- (void)alertViewLaunch:(nullable LGAlertView *)alertView {
    NSURL *sourceURL = self.sourceURL;
    NSString *temporarilyPath = self.temporarilyPath;
    NSString *temporarilyName = [temporarilyPath lastPathComponent];
    NSString *targetPath = self.targetPath;
    NSString *targetName = [targetPath lastPathComponent];
    { // Remove old temporarily file
        NSError *removeError = nil;
        BOOL removeResult = [self.downloadFileManager removeItemAtPath:temporarilyPath error:&removeError];
        struct stat targetStat;
        if (0 == lstat([temporarilyPath fileSystemRepresentation], &targetStat) && !removeResult) {
            LGAlertView *removeAlertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Create Failed", nil)
                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"Cannot create temporarily file \"%@\".\n%@", nil), temporarilyName, [removeError localizedDescription]]
                                                                        style:LGAlertViewStyleActionSheet
                                                                 buttonTitles:nil
                                                            cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                                       destructiveButtonTitle:nil
                                                                actionHandler:nil
                                                                cancelHandler:^(LGAlertView * _Nonnull alertView1) {
                                                                    [alertView1 dismissAnimated];
                                                                }
                                                           destructiveHandler:nil];
            if (alertView && alertView.isShowing) {
                [alertView transitionToAlertView:removeAlertView completionHandler:nil];
            } else {
                [removeAlertView showAnimated];
            }
            return;
        }
    }
    { // Create and Open temporarily file for writing
        // Create new temporarily file
        BOOL createResult = [self.downloadFileManager createFileAtPath:temporarilyPath contents:[NSData data] attributes:nil];
        NSFileHandle *downloadFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:temporarilyPath];
        if (!createResult || !downloadFileHandle) {
            LGAlertView *handleAlertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Creation Failed", nil)
                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"Cannot open file \"%@\" for writing.", nil), temporarilyName]
                                                                        style:LGAlertViewStyleActionSheet
                                                                 buttonTitles:nil
                                                            cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                                       destructiveButtonTitle:nil
                                                                actionHandler:nil
                                                                cancelHandler:^(LGAlertView * _Nonnull alertView1) {
                                                                    [alertView1 dismissAnimated];
                                                                }
                                                           destructiveHandler:nil];
            if (alertView && alertView.isShowing) {
                [alertView transitionToAlertView:handleAlertView completionHandler:nil];
            } else {
                [handleAlertView showAnimated];
            }
            return;
        }
        self.downloadFileHandle = downloadFileHandle;
    }
    { // Start Download Single File
        LGAlertView *downloadAlertView =
        [[LGAlertView alloc] initWithProgressViewAndTitle:NSLocalizedString(@"Download", nil)
                                                  message:[NSString stringWithFormat:NSLocalizedString(@"Download \"%@\" from \"%@\".", nil), targetName, [sourceURL host]]
                                                    style:LGAlertViewStyleActionSheet
                                                 progress:0.0
                                        progressLabelText:NSLocalizedString(@"Connecting...", nil)
                                             buttonTitles:nil
                                        cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                   destructiveButtonTitle:nil
                                                 delegate:self];
        if (alertView && alertView.isShowing) {
            [alertView transitionToAlertView:downloadAlertView completionHandler:nil];
        } else {
            [downloadAlertView showAnimated];
        }
        self.currentAlertView = downloadAlertView;
        if (busyOperationProgressFlag) {
            return;
        }
        busyOperationProgressFlag = YES;
        NSMutableURLRequest *downloadURLRequest = [NSMutableURLRequest requestWithURL:sourceURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:CGFLOAT_MAX];
        NSURLConnection *downloadURLConnection = [[NSURLConnection alloc] initWithRequest:downloadURLRequest delegate:self startImmediately:NO];
        [self performSelector:@selector(startDownloadImmediately:) withObject:downloadURLConnection afterDelay:1.f];
    }
}

- (void)startDownloadImmediately:(NSURLConnection *)connection {
    self.downloadURLConnection = connection;
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [connection start];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (connection == self.downloadURLConnection) {
        busyOperationProgressFlag = NO;
        self.downloadURLConnection = nil;
        if (self.downloadFileHandle)
        {
            [self.downloadFileHandle closeFile];
            self.downloadFileHandle = nil;
            // clean temporarily file
            NSString *temporarilyPath = self.temporarilyPath;
            if (temporarilyPath)
            {
                NSError *cleanError = nil;
                [self.downloadFileManager removeItemAtPath:temporarilyPath error:&cleanError];
            }
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSURL *sourceURL = self.sourceURL;
        NSString *sourceURLString = [sourceURL absoluteString];
        if (error) { // fail with error
            LGAlertView *downloadFailedAlertView =
            [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Download Failed", nil)
                                       message:[NSString stringWithFormat:NSLocalizedString(@"Cannot download from url \"%@\".\n%@", nil), sourceURLString, [error localizedDescription]]
                                         style:LGAlertViewStyleActionSheet
                                  buttonTitles:nil
                             cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                        destructiveButtonTitle:nil
                                 actionHandler:nil
                                 cancelHandler:^(LGAlertView * _Nonnull alertView1) {
                                     [alertView1 dismissAnimated];
                                 }
                            destructiveHandler:nil];
            if (self.currentAlertView && self.currentAlertView.isShowing) {
                [self.currentAlertView transitionToAlertView:downloadFailedAlertView completionHandler:nil];
            } else {
                [downloadFailedAlertView showAnimated];
            }
            self.currentAlertView = nil;
        }
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    } else if (connection == self.pretestConnection) {
        self.pretestConnection = nil;
        self.downloadButtonItem.enabled = YES;
        blockInteractions(self.blockController, NO);
        self.blockController = nil;
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse
{
    if (connection == self.pretestConnection) {
        if ([[request HTTPMethod] isEqualToString:@"HEAD"])
            return request;
        
        NSMutableURLRequest *newRequest = [request mutableCopy];
        [newRequest setHTTPMethod:@"HEAD"];
        
        return newRequest;
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if (connection == self.downloadURLConnection) {
        if (!busyOperationProgressFlag) {
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            // TODO: not supported http response
            [self connection:connection didFailWithError:[NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Download terminated, unsupported server response: %@ (%ld).", nil), [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode], httpResponse.statusCode]}]];
            return;
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        {
            [self.downloadFileHandle seekToFileOffset:0];
            expectedFileSize = [response expectedContentLength];
            receivedFileSize = 0.0;
        }
        {
            if (self.currentAlertView && self.currentAlertView.isShowing) {
                [self.currentAlertView setProgress:0.0];
                [self.currentAlertView setProgressLabelText:@"0 %"];
            }
        }
    } else if (connection == self.pretestConnection) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary *headers = httpResponse.allHeaderFields;
        if (headers && headers[@"Content-Disposition"]) {
            NSString *contentDispositionString = headers[@"Content-Disposition"];
            NSArray <NSString *> *contentDisposition = [contentDispositionString componentsSeparatedByString:@";"];
            if (contentDisposition.count > 1) {
                NSString *contentDispositionMethod = [contentDisposition[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ([contentDispositionMethod isEqualToString:@"attachment"]) {
                    NSRegularExpression *nameRegexp = [NSRegularExpression regularExpressionWithPattern:@"name=\"((\\\\.|[^\\\"])*?)\"" options:0 error:nil];
                    NSRegularExpression *fileNameRegexp = [NSRegularExpression regularExpressionWithPattern:@"filename=\"([^\"\\\\]*(\\\\.[^\"\\\\]*)*)\"" options:0 error:nil];
                    if (nameRegexp && fileNameRegexp) {
                        NSTextCheckingResult *nameCheck = [nameRegexp firstMatchInString:contentDispositionString options:0 range:NSMakeRange(0, contentDispositionString.length)];
                        NSTextCheckingResult *fileNameCheck = [fileNameRegexp firstMatchInString:contentDispositionString options:0 range:NSMakeRange(0, contentDispositionString.length)];
                        NSString *attachmentName = nil;
                        NSString *attachmentFileName = nil;
                        if (nameCheck.numberOfRanges > 1) {
                            NSRange nameSubRange = [nameCheck rangeAtIndex:1];
                            attachmentName = [[contentDispositionString substringWithRange:nameSubRange] stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                        }
                        if (fileNameCheck.numberOfRanges > 1) {
                            NSRange fileNameSubRange = [fileNameCheck rangeAtIndex:1];
                            attachmentFileName = [[contentDispositionString substringWithRange:fileNameSubRange] stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                        }
                        if (attachmentFileName.length > 0) {
                            [self fixTargetPathWithFileName:attachmentFileName];
                        } else if (attachmentName.length > 0) {
                            [self fixTargetPathWithFileName:attachmentName];
                        }
                    }
                }
            }
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)receivedData {
    if (connection == self.downloadURLConnection) {
        if (!busyOperationProgressFlag) {
            return;
        }
        {
            if (self.downloadFileHandle) {
                [self.downloadFileHandle writeData:receivedData];
            }
            receivedFileSize += receivedData.length;
        }
        if (expectedFileSize <= 0) {
            {
                if (self.currentAlertView && self.currentAlertView.isShowing) {
                    [self.currentAlertView setProgressLabelText:[NSString stringWithFormat:@"%lld bytes received.", receivedFileSize]];
                }
            }
        } else {
            float progressive = (float)receivedFileSize / (float)expectedFileSize;
            {
                if (self.currentAlertView && self.currentAlertView.isShowing) {
                    [self.currentAlertView setProgress:progressive];
                    [self.currentAlertView setProgressLabelText:[NSString stringWithFormat:@"%.2f %%", (float)progressive * 100]];
                }
            }
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (connection == self.downloadURLConnection) {
        busyOperationProgressFlag = NO;
        self.downloadURLConnection = nil;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        {
            if (self.downloadFileHandle) {
                [self.downloadFileHandle closeFile];
                self.downloadFileHandle = nil;
            }
        }
        {
            [self downloadFinished:self.currentAlertView];
        }
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    } else if (connection == self.pretestConnection) {
        self.pretestConnection = nil;
        self.downloadButtonItem.enabled = YES;
        blockInteractions(self.blockController, NO);
        self.blockController = nil;
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)downloadFinished:(LGAlertView *)alertView {
    self.currentAlertView = nil;
    NSString *temporarilyPath = self.temporarilyPath;
    NSString *temporarilyName = [temporarilyPath lastPathComponent];
    NSString *targetPath = self.targetPath;
    NSString *targetName = [targetPath lastPathComponent];
    if (self.overwrite) {
        { // Remove old file
            promiseFixPermission(targetPath, NO); // fix permission
            NSError *removeError = nil;
            BOOL removeResult = [self.downloadFileManager removeItemAtPath:targetPath error:&removeError];
            struct stat targetStat;
            if (0 == lstat([targetPath fileSystemRepresentation], &targetStat) && !removeResult) {
                LGAlertView *removeAlertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Overwrite Failed", nil)
                                                                          message:[NSString stringWithFormat:NSLocalizedString(@"Cannot overwrite file \"%@\".\n%@", nil), targetName, [removeError localizedDescription]]
                                                                            style:LGAlertViewStyleActionSheet
                                                                     buttonTitles:nil
                                                                cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                                           destructiveButtonTitle:nil
                                                                    actionHandler:nil
                                                                    cancelHandler:^(LGAlertView * _Nonnull alertView1) {
                                                                        [alertView1 dismissAnimated];
                                                                    }
                                                               destructiveHandler:nil];
                if (alertView && alertView.isShowing) {
                    [alertView transitionToAlertView:removeAlertView completionHandler:nil];
                } else {
                    [removeAlertView showAnimated];
                }
                return;
            }
        }
    } else {
        // Rename: modify target path
        NSString *currentPath = [targetPath stringByDeletingLastPathComponent];
        NSString *lastComponent = [targetPath lastPathComponent];
        NSString *lastComponentName = [lastComponent stringByDeletingPathExtension];
        NSString *lastComponentExt = [lastComponent pathExtension];
        NSString *testedPath = [currentPath stringByAppendingPathComponent:lastComponent];
        NSUInteger testedIndex = 2;
        struct stat inboxTestStat;
        while (0 == lstat(testedPath.UTF8String, &inboxTestStat)) {
            lastComponent = [[NSString stringWithFormat:@"%@-%lu", lastComponentName, (unsigned long)testedIndex] stringByAppendingPathExtension:lastComponentExt];
            testedPath = [currentPath stringByAppendingPathComponent:lastComponent];
            testedIndex++;
        }
        {
            _targetPath = testedPath;
            targetPath = testedPath;
            targetName = [targetPath lastPathComponent];
        }
    }
    {
        NSError *moveError = nil;
        BOOL moveResult = [self.downloadFileManager moveItemAtPath:temporarilyPath toPath:targetPath error:&moveError];
        if (!moveResult) {
            LGAlertView *moveAlertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Move Failed", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Cannot move temporarily file \"%@\" to \"%@\".\n%@", nil), temporarilyName, targetName, [moveError localizedDescription]]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:nil
                                                          cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                                     destructiveButtonTitle:nil
                                                              actionHandler:nil
                                                              cancelHandler:^(LGAlertView * _Nonnull alertView1) {
                                                                  [alertView1 dismissAnimated];
                                                              }
                                                         destructiveHandler:nil];
            if (alertView && alertView.isShowing) {
                [alertView transitionToAlertView:moveAlertView completionHandler:nil];
            } else {
                [moveAlertView showAnimated];
            }
            return;
        }
    }
    NSString *instantTitle = NSLocalizedString(@"Instant View / Run", nil);
    LGAlertView *finishAlertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Download Finished", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"Successfully saved to \"%@\".", nil), targetName]
                                                                style:LGAlertViewStyleActionSheet
                                                         buttonTitles:@[ instantTitle, NSLocalizedString(@"Done", nil) ]
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                             delegate:self];
    if (self.autoInstantView) {
        if (alertView && alertView.isShowing) {
            [alertView dismissAnimated:YES completionHandler:nil];
            [self alertView:finishAlertView clickedButtonAtIndex:0 title:instantTitle];
        }
    } else {
        if (alertView && alertView.isShowing) {
            [alertView transitionToAlertView:finishAlertView];
        } else {
            [finishAlertView showAnimated];
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
