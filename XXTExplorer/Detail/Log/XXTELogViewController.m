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

#import <LGAlertView/LGAlertView.h>
#import "XXTEBaseObjectViewController.h"

static NSUInteger const kXXTELogViewControllerMaximumBytes = 256 * 1024; // 200k

@interface XXTELogViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate>

@property (nonatomic, strong) UITableView *logTableView;
@property (nonatomic, strong) UIBarButtonItem *clearItem;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, copy) NSArray <NSString *> *logContents;
@property (nonatomic, copy) NSArray <NSString *> *displayLogContents;

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;
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
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
    searchBar.placeholder = NSLocalizedString(@"Search Log", nil);
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.backgroundColor = [UIColor whiteColor];
    searchBar.barTintColor = [UIColor whiteColor];
    searchBar.tintColor = XXTColorDefault();
    
    XXTE_START_IGNORE_PARTIAL
    UISearchDisplayController *searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.delegate = self;
    _searchDisplayController = searchDisplayController;
    XXTE_END_IGNORE_PARTIAL
    
    _logTableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTELogCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTELogCellReuseIdentifier];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.tableHeaderView = searchBar;
        XXTE_START_IGNORE_PARTIAL
        if (XXTE_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        [self.view addSubview:tableView];
        tableView;
    });
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.logTableView;
    _refreshControl = ({
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(reloadTextDataFromEntry:) forControlEvents:UIControlEventValueChanged];
        [tableViewController setRefreshControl:refreshControl];
        refreshControl;
    });
    [self.logTableView.backgroundView insertSubview:self.refreshControl atIndex:0];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
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
        self.logContents = @[ ];
    } else {
        [self.clearItem setEnabled:YES];
        NSMutableArray *logArr = [[stringPart componentsSeparatedByString:@"\n"] mutableCopy];
        [logArr removeObject:@""];
        self.logContents = [[logArr reverseObjectEnumerator] allObjects];
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
    LGAlertView *clearAlert = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clear Confirm", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Remove all logs in \"%@\"?", nil), entryPath] style:LGAlertViewStyleActionSheet buttonTitles:@[ ] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Clear Now", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
        [[NSData data] writeToFile:entryPath atomically:YES];
        [self loadTextDataFromEntry];
    }];
    [clearAlert showAnimated];
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.logTableView) {
        return self.logContents.count;
    } else {
        return self.displayLogContents.count;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.logTableView) {
        if (indexPath.row < self.logContents.count) {
            XXTEBaseObjectViewController *objectController = [[XXTEBaseObjectViewController alloc] initWithRootObject:self.logContents[indexPath.row]];
            objectController.title = NSLocalizedString(@"Value", nil);
            [self.navigationController pushViewController:objectController animated:YES];
        }
    } else {
        if (indexPath.row < self.logContents.count) {
            XXTEBaseObjectViewController *objectController = [[XXTEBaseObjectViewController alloc] initWithRootObject:self.displayLogContents[indexPath.row]];
            objectController.title = NSLocalizedString(@"Value", nil);
            [self.navigationController pushViewController:objectController animated:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 24.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (@available(iOS 8.0, *)) {
        return UITableViewAutomaticDimension;
    } else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        
        cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        return (height > 0) ? (height + 1.0) : 24.f;
    }
    return 24.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXTELogCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTELogCellReuseIdentifier forIndexPath:indexPath];
    if (tableView == self.logTableView) {
        if (indexPath.row < self.logContents.count) {
            [cell setLogText:self.logContents[indexPath.row]];
        }
    } else {
        if (indexPath.row < self.displayLogContents.count) {
            [cell setLogText:self.displayLogContents[indexPath.row]];
        }
    }
    if (indexPath.row % 2 == 0) {
        [cell setBackgroundColor:[UIColor whiteColor]];
    } else {
        [cell setBackgroundColor:[UIColor colorWithWhite:0.97 alpha:1.0]];
    }
    return cell;
}

#pragma mark - UISearchDisplayDelegate

XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTELogCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTELogCellReuseIdentifier];
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    if (predicate) {
        self.displayLogContents = [[NSArray alloc] initWithArray:[self.logContents filteredArrayUsingPredicate:predicate]];
    }
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTELogViewController dealloc]");
#endif
}

@synthesize awakeFromOutside;

@end
