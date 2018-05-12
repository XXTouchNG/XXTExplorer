//
// Created by Zheng on 02/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#include <objc/runtime.h>
#import "XXTEMoreApplicationListController.h"
#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"
#import "XXTEMoreApplicationCell.h"
#import "XXTEMoreApplicationDetailController.h"
#import "UINavigationController+XXTEFullscreenPopGesture.h"

typedef enum : NSUInteger {
    ApplicationSectionUser = 0,
    ApplicationSectionSystem,
    ApplicationSectionMax
} ApplicationSection;

enum {
    kXXTEMoreApplicationSearchTypeName = 0,
    kXXTEMoreApplicationSearchTypeBundleID
};

#if !(TARGET_OS_SIMULATOR)
CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);
CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier);
CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier);
#else
CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);
CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier);
CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier);
#endif

@interface XXTEMoreApplicationListController ()
        <
        UITableViewDelegate,
        UITableViewDataSource,
        UISearchControllerDelegate,
        UISearchResultsUpdating,
        UIScrollViewDelegate,
        UISearchBarDelegate
        >
@property(nonatomic, strong, readonly) UITableView *tableView;
@property(nonatomic, strong, readonly) UIRefreshControl *refreshControl;
//@property(nonatomic, strong, readonly) NSArray <NSDictionary *> *allApplications;
//@property(nonatomic, strong, readonly) NSArray <NSDictionary *> *displayApplications;

@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *allUserApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *allSystemApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *displayUserApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *displaySystemApplications;

XXTE_START_IGNORE_PARTIAL
@property(nonatomic, strong, readonly) UISearchController *searchController;
XXTE_END_IGNORE_PARTIAL

@property(nonatomic, strong, readonly) LSApplicationWorkspace *applicationWorkspace;

@end

@implementation XXTEMoreApplicationListController {
    UIEdgeInsets _savedInsets;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _allUserApplications = [[NSMutableArray alloc] init];
    _allSystemApplications = [[NSMutableArray alloc] init];
    _displayUserApplications = [[NSMutableArray alloc] init];
    _displaySystemApplications = [[NSMutableArray alloc] init];
}

#pragma mark - Default Style

- (NSString *)title {
    return NSLocalizedString(@"Applications", nil);
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.definesPresentationContext = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    _applicationWorkspace = ({
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        SEL selector = NSSelectorFromString(@"defaultWorkspace");
        LSApplicationWorkspace *applicationWorkspace = [LSApplicationWorkspace_class performSelector:selector];
        applicationWorkspace;
    });
#pragma clang diagnostic pop
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [tableView registerNib:[UINib nibWithNibName:@"XXTEMoreApplicationCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kXXTEMoreApplicationCellReuseIdentifier];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        [self.view addSubview:tableView];
        tableView;
    });
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    _refreshControl = ({
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        if (@available(iOS 11.0, *)) {
            refreshControl.tintColor = [UIColor whiteColor];
        }
        [refreshControl addTarget:self action:@selector(asyncApplicationList:) forControlEvents:UIControlEventValueChanged];
        [tableViewController setRefreshControl:refreshControl];
        refreshControl;
    });
    [self.tableView.backgroundView insertSubview:self.refreshControl atIndex:0];
    
    XXTE_START_IGNORE_PARTIAL
    _searchController = ({
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController;
    });
    XXTE_END_IGNORE_PARTIAL
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        [self.searchController loadViewIfNeeded];
    }
    XXTE_END_IGNORE_PARTIAL

    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.placeholder = NSLocalizedString(@"Search Application", nil);
    searchBar.scopeButtonTitles = @[
                                    NSLocalizedString(@"Name", nil),
                                    NSLocalizedString(@"Bundle ID", nil)
                                    ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.delegate = self;
    
    if (@available(iOS 11.0, *)) {
        UITextField *textField = [searchBar valueForKey:@"searchField"];
        textField.textColor = [UIColor blackColor];
        textField.tintColor = XXTColorDefault();
        UIView *backgroundView = [textField.subviews firstObject];
        backgroundView.backgroundColor = [UIColor whiteColor];
        backgroundView.layer.cornerRadius = 10.0;
        backgroundView.clipsToBounds = YES;
        searchBar.barTintColor = [UIColor whiteColor];
        searchBar.tintColor = [UIColor whiteColor];
        self.navigationItem.searchController = self.searchController;
    } else {
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        searchBar.backgroundColor = [UIColor whiteColor];
        searchBar.barTintColor = [UIColor whiteColor];
        searchBar.tintColor = XXTColorDefault();
        self.tableView.tableHeaderView = searchBar;
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self asyncApplicationList:self.refreshControl];
}

- (void)removeAllApplications {
    [self.allUserApplications removeAllObjects];
    [self.allSystemApplications removeAllObjects];
    [self.displayUserApplications removeAllObjects];
    [self.displaySystemApplications removeAllObjects];
}

- (void)asyncApplicationList:(UIRefreshControl *)refreshControl {
    if (self.searchController.active) {
        if ([refreshControl isRefreshing]) {
            [refreshControl endRefreshing];
        }
        return;
    }
    UIViewController *blockVC = blockInteractions(self, YES);
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @strongify(self);
        [self removeAllApplications];
        NSArray <NSString *> *applicationIdentifiers = (NSArray *)CFBridgingRelease(SBSCopyApplicationDisplayIdentifiers(false, false));
        NSMutableArray <LSApplicationProxy *> *allApplications = nil;
        if (applicationIdentifiers) {
            allApplications = [NSMutableArray arrayWithCapacity:applicationIdentifiers.count];
            [applicationIdentifiers enumerateObjectsUsingBlock:^(NSString * _Nonnull bid, NSUInteger idx, BOOL * _Nonnull stop) {
                LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:bid];
                [allApplications addObject:proxy];
            }];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            SEL selectorAll = NSSelectorFromString(@"allApplications");
            allApplications = [self.applicationWorkspace performSelector:selectorAll];
#pragma clang diagnostic pop
        }
        NSString *whiteIconListPath = [[NSBundle mainBundle] pathForResource:@"xxte-white-icons" ofType:@"plist"];
        NSArray <NSString *> *blacklistIdentifiers = [NSDictionary dictionaryWithContentsOfFile:whiteIconListPath][@"xxte-white-icons"];
        NSOrderedSet <NSString *> *blacklistApplications = [[NSOrderedSet alloc] initWithArray:blacklistIdentifiers];
        for (LSApplicationProxy *appProxy in allApplications) {
            @autoreleasepool {
                NSString *applicationBundleID = appProxy.applicationIdentifier;
                BOOL shouldAdd = ![blacklistApplications containsObject:applicationBundleID];
                if (!shouldAdd) {
                    continue;
                }
                NSString *applicationBundlePath = [appProxy.resourcesDirectoryURL path];
                NSString *applicationContainerPath = nil;
                NSString *applicationName = CFBridgingRelease(SBSCopyLocalizedApplicationNameForDisplayIdentifier((__bridge CFStringRef)(applicationBundleID)));
                if (!applicationName) {
                    applicationName = appProxy.localizedName;
                }
                NSData *applicationIconImageData = CFBridgingRelease(SBSCopyIconImagePNGDataForDisplayIdentifier((__bridge CFStringRef)(applicationBundleID)));
                UIImage *applicationIconImage = [UIImage imageWithData:applicationIconImageData];
                if (@available(iOS 8.0, *)) {
                    if ([appProxy respondsToSelector:@selector(dataContainerURL)]) {
                        applicationContainerPath = [[appProxy dataContainerURL] path];
                    }
                } else {
                    if ([appProxy respondsToSelector:@selector(containerURL)]) {
                        applicationContainerPath = [[appProxy containerURL] path];
                    }
                }
                if (applicationContainerPath.length == 0) {
                    applicationContainerPath = @"";
                }
                NSMutableDictionary *applicationDetail = [[NSMutableDictionary alloc] init];
                if (applicationBundleID)
                {
                    applicationDetail[kXXTEMoreApplicationDetailKeyBundleID] = applicationBundleID;
                }
                if (applicationName)
                {
                    applicationDetail[kXXTEMoreApplicationDetailKeyName] = applicationName;
                }
                if (applicationBundlePath)
                {
                    applicationDetail[kXXTEMoreApplicationDetailKeyBundlePath] = applicationBundlePath;
                }
                if (applicationContainerPath)
                {
                    applicationDetail[kXXTEMoreApplicationDetailKeyContainerPath] = applicationContainerPath;
                }
                if (applicationIconImage)
                {
                    applicationDetail[kXXTEMoreApplicationDetailKeyIconImage] = applicationIconImage;
                }
                BOOL systemApp = [applicationBundlePath hasPrefix:@"/Applications"];
                if (systemApp) {
                    [self.allSystemApplications addObject:[applicationDetail copy]];
                } else {
                    [self.allUserApplications addObject:[applicationDetail copy]];
                }
            }
        }
        dispatch_async_on_main_queue(^{
            [self.tableView reloadData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            if ([refreshControl isRefreshing]) {
                [refreshControl endRefreshing];
            }
            blockInteractions(blockVC, NO);
        });
    });
}

#pragma mark - Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ApplicationSectionMax;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == ApplicationSectionSystem) {
        return NSLocalizedString(@"System Applications", nil);
    } else if (section == ApplicationSectionUser) {
        return NSLocalizedString(@"User Applications", nil);
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return XXTEMoreApplicationCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active == NO) {
        if (section == ApplicationSectionSystem) {
            return self.allSystemApplications.count;
        } else if (section == ApplicationSectionUser) {
            return self.allUserApplications.count;
        }
    } else {
        if (section == ApplicationSectionSystem) {
            return self.displaySystemApplications.count;
        } else if (section == ApplicationSectionUser) {
            return self.displayUserApplications.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXTEMoreApplicationCell *cell = [tableView dequeueReusableCellWithIdentifier:kXXTEMoreApplicationCellReuseIdentifier];
    if (cell == nil) {
        cell = [[XXTEMoreApplicationCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:kXXTEMoreApplicationCellReuseIdentifier];
    }
    NSDictionary *applicationDetail = nil;
    NSUInteger indexRow = (NSUInteger) indexPath.row;
    if (self.searchController.active == NO) {
        if (indexPath.section == ApplicationSectionSystem) {
            if (indexRow < self.allSystemApplications.count) {
                applicationDetail = self.allSystemApplications[indexRow];
            }
        } else if (indexPath.section == ApplicationSectionUser) {
            if (indexRow < self.allUserApplications.count) {
                applicationDetail = self.allUserApplications[indexRow];
            }
        }
    } else {
        if (indexPath.section == ApplicationSectionSystem) {
            if (indexRow < self.displaySystemApplications.count) {
                applicationDetail = self.displaySystemApplications[indexRow];
            }
        } else if (indexPath.section == ApplicationSectionUser) {
            if (indexRow < self.displayUserApplications.count) {
                applicationDetail = self.displayUserApplications[indexRow];
            }
        }
    }
    [cell setApplicationName:applicationDetail[kXXTEMoreApplicationDetailKeyName]];
    [cell setApplicationBundleID:applicationDetail[kXXTEMoreApplicationDetailKeyBundleID]];
    [cell setApplicationIconImage:applicationDetail[kXXTEMoreApplicationDetailKeyIconImage]];
    [cell setTintColor:XXTColorDefault()];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *applicationDetail = nil;
    NSUInteger indexRow = (NSUInteger) indexPath.row;
    if (self.searchController.active == NO) {
        if (indexPath.section == ApplicationSectionSystem) {
            applicationDetail = self.allSystemApplications[indexRow];
        } else if (indexPath.section == ApplicationSectionUser) {
            applicationDetail = self.allUserApplications[indexRow];
        }
    } else {
        if (indexPath.section == ApplicationSectionSystem) {
            applicationDetail = self.displaySystemApplications[indexRow];
        } else if (indexPath.section == ApplicationSectionUser) {
            applicationDetail = self.displayUserApplications[indexRow];
        }
    }

    XXTEMoreApplicationDetailController *applicationDetailController = [[XXTEMoreApplicationDetailController alloc] initWithStyle:UITableViewStyleGrouped];
    applicationDetailController.applicationDetail = applicationDetail;
    [self.navigationController pushViewController:applicationDetailController animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont systemFontOfSize:14.0];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(nonnull UIView *)view forSection:(NSInteger)section {
    if (tableView.style == UITableViewStylePlain) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.font = [UIFont systemFontOfSize:12.0];
    }
}

#pragma mark - UISearchResultsUpdating

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearchByContent:searchText andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self reloadSearchByContent:searchBar.text andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:NO];
}

XXTE_START_IGNORE_PARTIAL
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadSearchByContent:searchController.searchBar.text andCategory:searchController.searchBar.selectedScopeButtonIndex];
}
XXTE_END_IGNORE_PARTIAL

- (void)reloadSearchByContent:(NSString *)searchText andCategory:(NSUInteger)category {
    NSPredicate *predicate = nil;
    if (category == kXXTEMoreApplicationSearchTypeName) {
        predicate = [NSPredicate predicateWithFormat:@"kXXTEMoreApplicationDetailKeyName CONTAINS[cd] %@", searchText];
    } else if (category == kXXTEMoreApplicationSearchTypeBundleID) {
        predicate = [NSPredicate predicateWithFormat:@"kXXTEMoreApplicationDetailKeyBundleID CONTAINS[cd] %@", searchText];
    }
    if (predicate) {
        [self.displayUserApplications removeAllObjects];
        [self.displaySystemApplications removeAllObjects];
        [self.displayUserApplications addObjectsFromArray:[self.allUserApplications filteredArrayUsingPredicate:predicate]];
        [self.displaySystemApplications addObjectsFromArray:[self.allSystemApplications filteredArrayUsingPredicate:predicate]];
    }
    [self.tableView reloadData];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.searchBar.text.length == 0) {
        [self.searchController setActive:NO];
    } else {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    UIEdgeInsets insets1 = self.tableView.scrollIndicatorInsets;
    _savedInsets = insets1;
    insets1.top += 50.0 + 44.0;
    self.tableView.scrollIndicatorInsets = insets1;
}

#pragma mark - Memory

- (void)dealloc {
    [self.searchController.view removeFromSuperview];
#ifdef DEBUG
    NSLog(@"- [XXTEMoreApplicationListController dealloc]");
#endif
}

@end
