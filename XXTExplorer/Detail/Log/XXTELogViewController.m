//
//  XXTELogViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTELogViewController.h"
#import "XXTELogReader.h"
#import "XXTELogCell.h"
#import "XXTEEncodingHelper.h"

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEEditorTextProperties.h"

#import <LGAlertView/LGAlertView.h>
#import <PromiseKit/PromiseKit.h>
#import <spawn.h>

static NSUInteger const kXXTELogViewControllerMaximumBytes = 200 * 1024; // 200k

@interface XXTELogViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
UISearchDisplayDelegate,
UISearchResultsUpdating
>

@property (nonatomic, strong) UITableView *logTableView;
@property (nonatomic, strong) UIBarButtonItem *clearItem;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, copy) NSArray <NSString *> *logContents;
@property (nonatomic, copy) NSArray <NSString *> *displayLogContents;
@property (nonatomic, strong) XXTELogCell *sizingCell;

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong) UISearchController *searchController;
XXTE_END_IGNORE_PARTIAL

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

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    XXTE_START_IGNORE_PARTIAL
    if (self.searchDisplayController.active) {
        return UIStatusBarStyleDefault;
    }
    XXTE_END_IGNORE_PARTIAL
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        _sizingCell = (XXTELogCell *)[[[UINib nibWithNibName:NSStringFromClass([XXTELogCell class]) bundle:nil] instantiateWithOwner:nil options:nil] lastObject];
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
    self.navigationItem.rightBarButtonItem = self.clearItem;
    
    UISearchBar *searchBar = nil;
    XXTE_START_IGNORE_PARTIAL
    _searchController = ({
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController.hidesNavigationBarDuringPresentation = YES;
        searchController;
    });
    searchBar = self.searchController.searchBar;
    XXTE_END_IGNORE_PARTIAL
    
    {
        UITextField *textField = [searchBar performSelector:@selector(searchTextField)];
        textField.textColor = XXTColorPlainTitleText();
        textField.tintColor = XXTColorForeground();
        searchBar.placeholder = NSLocalizedString(@"Search Log", nil);
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    }
    
    _logTableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTELogCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTELogCellReuseIdentifier];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.tableFooterView = [UIView new];
        XXTE_START_IGNORE_PARTIAL
        if (XXTE_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        [self.view addSubview:tableView];
        tableView;
    });
    self.navigationItem.hidesSearchBarWhenScrolling = YES;
    self.navigationItem.searchController = self.searchController;
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.logTableView;
    _refreshControl = ({
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(reloadTextDataFromEntry:) forControlEvents:UIControlEventValueChanged];
        [tableViewController setRefreshControl:refreshControl];
        refreshControl;
    });
    [self.logTableView.backgroundView insertSubview:self.refreshControl atIndex:0];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
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
    unsigned long long endOffset = [textHandler seekToEndOfFile];
    if (endOffset > kXXTELogViewControllerMaximumBytes) {
        [textHandler seekToFileOffset:endOffset - kXXTELogViewControllerMaximumBytes];
    } else {
        [textHandler seekToFileOffset:0];
    }
    NSData *dataPart = [textHandler readDataOfLength:kXXTELogViewControllerMaximumBytes];
    [textHandler closeFile];
    if (!dataPart) {
        return;
    }
    NSInteger encodingIndex = XXTEDefaultsInt(XXTExplorerDefaultEncodingKey, 0);
    CFStringEncoding encoding = [XXTEEncodingHelper encodingAtIndex:encodingIndex];
    NSString *encodingName = [XXTEEncodingHelper encodingNameForEncoding:encoding];
    NSString *stringPart = CFBridgingRelease(CFStringCreateWithBytes(kCFAllocatorDefault, dataPart.bytes, dataPart.length, encoding, NO));
    if (!stringPart) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot parse log with \"%@\" encoding: \"%@\".", nil), encodingName, entryPath.lastPathComponent]);
        return;
    }
    if (stringPart.length == 0) {
        [self.clearItem setEnabled:NO];
        self.logContents = @[ ];
    } else {
        [self.clearItem setEnabled:YES];
        NSMutableArray *logArr = nil;
        if ([stringPart containsString:@NSStringLineBreakCRLF]) {
            logArr = [[stringPart componentsSeparatedByString:@NSStringLineBreakCRLF] mutableCopy];
        } else if ([stringPart containsString:@NSStringLineBreakCR]) {
            logArr = [[stringPart componentsSeparatedByString:@NSStringLineBreakCR] mutableCopy];
        } else {
            logArr = [[stringPart componentsSeparatedByString:@NSStringLineBreakLF] mutableCopy];
        }
        [logArr removeObject:@""];
        NSArray <NSString *> *reversedLogArr = [[logArr reverseObjectEnumerator] allObjects];
        NSMutableArray <NSString *> *logContents = [NSMutableArray arrayWithCapacity:reversedLogArr.count];
        for (NSString *logPart in reversedLogArr) {
            [logContents addObject:[logPart stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        self.logContents = [logContents copy];
    }
    [self.logTableView reloadData];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)clearItem {
    if (!_clearItem) {
        UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear", nil) style:UIBarButtonItemStylePlain target:self action:@selector(clearItemTapped:)];
        _clearItem = clearItem;
    }
    return _clearItem;
}

#pragma mark - Actions

- (void)clearItemTapped:(UIBarButtonItem *)sender {
    NSString *entryPath = self.entryPath;
    if (!entryPath) {
        return;
    }
    LGAlertView *clearAlert = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clear Confirm", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Remove all logs in \"%@\"?", nil), entryPath.lastPathComponent] style:LGAlertViewStyleActionSheet buttonTitles:@[ ] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Clear Now", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
        
        pid_t pid = 0;
        const char *binary = add1s_binary();
        const char *args[] = {binary, "/usr/bin/truncate", "-s", "0", [entryPath UTF8String], NULL};
        posix_spawn(&pid, binary, NULL, NULL, (char* const*)args, (char* const*)XXTESharedEnvp());
        
        int status;
        waitpid(pid, &status, 0);
        if (WIFEXITED(status)) {
            [self loadTextDataFromEntry];
        }
    }];
    [clearAlert showAnimated];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.searchController.active) {
        return self.logContents.count;
    } else {
        return self.displayLogContents.count;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *detailText = nil;
    if (!self.searchController.active) {
        if (indexPath.row < self.logContents.count) {
            detailText = self.logContents[indexPath.row];
        }
    } else {
        if (indexPath.row < self.displayLogContents.count) {
            detailText = self.displayLogContents[indexPath.row];
        }
    }
    if (detailText && detailText.length > 0) {
        UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 1.0);
        [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [[UIPasteboard generalPasteboard] setString:detailText];
                fulfill(nil);
            });
        }].finally(^() {
            toastMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
            blockInteractions(blockVC, NO);
        });
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 24.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXTELogCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTELogCellReuseIdentifier forIndexPath:indexPath];
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    if (indexPath.row % 2 == 0) {
        [cell setBackgroundColor:XXTColorPlainBackground()];
    } else {
        [cell setBackgroundColor:XXTColorPlainSectionHeader()];
    }
    return cell;
}

- (void)configureCell:(XXTELogCell *)cell forTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    BOOL isSearch = NO;
    UISearchBar *searchBar = nil;
    if (self.searchController.active) {
        isSearch = YES;
        searchBar = self.searchController.searchBar;
    }
    if (!isSearch) {
        if (indexPath.row < self.logContents.count) {
            [cell setLogText:self.logContents[indexPath.row]];
        }
    } else {
        if (indexPath.row < self.displayLogContents.count) {
            NSString *searchContent = searchBar.text;
            NSString *logContent = self.displayLogContents[indexPath.row];
            NSDictionary *logContentAttrs = @{ NSFontAttributeName: [UIFont fontWithName:@"Courier" size:14.0], NSForegroundColorAttributeName: XXTColorPlainTitleText() };
            
            NSMutableAttributedString *mLogContent = [[NSMutableAttributedString alloc] initWithString:logContent attributes:logContentAttrs];
            NSRange searchRange = [logContent rangeOfString:searchContent options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch range:NSMakeRange(0, logContent.length)];
            if (searchRange.location != NSNotFound) {
                [mLogContent addAttributes:@{ NSBackgroundColorAttributeName: XXTColorSearchHighlight() } range:searchRange];
            }
            [cell setAttributedLogText:[mLogContent copy]];
        }
    }
}

#pragma mark - UISearchResultsUpdating (13.0+)

XXTE_START_IGNORE_PARTIAL
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadSearch];
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - UISearchDisplayDelegate

XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTELogCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTELogCellReuseIdentifier];
    tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    [self _findAndHideSearchBarShadowInView:tableView];
}
- (void)_findAndHideSearchBarShadowInView:(UIView *)view {
    NSString *usc = @"_";
    NSString *sb = @"UISearchBar";
    NSString *sv = @"ShadowView";
    NSString *s = [[usc stringByAppendingString:sb] stringByAppendingString:sv];
    
    for (UIView *v in view.subviews)
    {
        if ([v isKindOfClass:NSClassFromString(s)]) {
            v.hidden = YES;
        }
        [self _findAndHideSearchBarShadowInView:v];
    }
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self reloadSearch];
    return YES;
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self reloadSearch];
    return YES;
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (void)reloadSearch {
    NSString *text = self.searchController.searchBar.text;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", text];
    if (predicate) {
        self.displayLogContents = [[NSArray alloc] initWithArray:[self.logContents filteredArrayUsingPredicate:predicate]];
    }
    [self.logTableView reloadData];
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
