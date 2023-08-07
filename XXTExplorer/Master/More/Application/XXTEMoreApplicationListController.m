//
// Created by Zheng on 02/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <objc/runtime.h>
#import "XXTEMoreApplicationListController.h"

#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"

#import "XXTESearchController.h"
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

CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);
CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier);
CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier);

@interface XXTEMoreApplicationListController ()
<
UITableViewDelegate,
UITableViewDataSource,
UISearchControllerDelegate,
UISearchResultsUpdating,
UIScrollViewDelegate,
UISearchBarDelegate
>

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
    self.definesPresentationContext = YES;
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

    self.extendedLayoutIncludesOpaqueBars = YES;
    XXTE_START_IGNORE_PARTIAL
    self.automaticallyAdjustsScrollViewInsets = YES;
    XXTE_END_IGNORE_PARTIAL
    
    self.view.backgroundColor = XXTColorPlainBackground();
    
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
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
        XXTE_END_IGNORE_PARTIAL
        [self.view addSubview:tableView];
        tableView;
    });
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    _refreshControl = ({
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        refreshControl.tintColor = [UIColor whiteColor];
        [refreshControl addTarget:self action:@selector(asyncApplicationList:) forControlEvents:UIControlEventValueChanged];
        [tableViewController setRefreshControl:refreshControl];
        refreshControl;
    });
    [self.tableView.backgroundView insertSubview:self.refreshControl atIndex:0];
    
    XXTE_START_IGNORE_PARTIAL
    _searchController = ({
        UISearchController *searchController = [[XXTESearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController;
    });
    XXTE_END_IGNORE_PARTIAL
    
    XXTE_START_IGNORE_PARTIAL
    [self.searchController loadViewIfNeeded];
    XXTE_END_IGNORE_PARTIAL

    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.placeholder = NSLocalizedString(@"Search Application", nil);
    searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Search Application", nil) attributes:@{ NSForegroundColorAttributeName: [XXTColorBarText() colorWithAlphaComponent:0.5] }];
    if ([searchBar.searchTextField.leftView isKindOfClass:[UIImageView class]])
        [(UIImageView *)searchBar.searchTextField.leftView setTintColor:XXTColorTint()];
    {
        UIButton *clearButton = [searchBar.searchTextField valueForKey:@"_clearButton"];
        UIImage *clearImage = [clearButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [clearButton setImage:clearImage forState:UIControlStateNormal];
        [clearButton setTintColor:[XXTColorTint() colorWithAlphaComponent:0.5]];
    }
    searchBar.scopeButtonTitles = @[ NSLocalizedString(@"Name", nil),
                                     NSLocalizedString(@"Bundle ID", nil)
                                     ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.delegate = self;
    
    UITextField *textField = [searchBar performSelector:@selector(searchTextField)];
    textField.textColor = XXTColorPlainTitleText();
    textField.tintColor = XXTColorForeground();
    searchBar.barTintColor = XXTColorPlainBackground();
    searchBar.tintColor = XXTColorPlainBackground();

    self.navigationItem.hidesSearchBarWhenScrolling = YES;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    // Only after the assignment it works
    searchBar.searchTextField.textColor = XXTColorBarText();
    
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
                NSString *applicationBundlePath = [appProxy.bundleContainerURL path];
                NSString *applicationDataContainerPath = nil;
                NSDictionary <NSString *, NSString *> *applicationGroupContainerPaths = nil;
                NSString *applicationName = CFBridgingRelease(SBSCopyLocalizedApplicationNameForDisplayIdentifier((__bridge CFStringRef)(applicationBundleID)));
                if (!applicationName) {
                    applicationName = appProxy.localizedName;
                }
                NSData *applicationIconImageData = CFBridgingRelease(SBSCopyIconImagePNGDataForDisplayIdentifier((__bridge CFStringRef)(applicationBundleID)));
                UIImage *applicationIconImage = [UIImage imageWithData:applicationIconImageData];
                if ([appProxy respondsToSelector:@selector(dataContainerURL)]) {
                    applicationDataContainerPath = [[appProxy dataContainerURL] path];
                }
                if (!applicationDataContainerPath) {
                    applicationDataContainerPath = @"";
                }
                if ([appProxy respondsToSelector:@selector(groupContainerURLs)]) {
                    NSDictionary <NSString *, NSURL *> *containerURLs = [appProxy groupContainerURLs];
                    NSMutableDictionary <NSString *, NSString *> *containerPaths = [NSMutableDictionary dictionaryWithCapacity:containerURLs.count];
                    for (NSString *containerID in containerURLs) {
                        containerPaths[containerID] = [containerURLs[containerID] path];
                    }
                    applicationGroupContainerPaths = containerPaths;
                }
                if (!applicationGroupContainerPaths) {
                    applicationGroupContainerPaths = @{};
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
                if (applicationDataContainerPath)
                {
                    applicationDetail[kXXTEMoreApplicationDetailKeyDataContainerPath] = applicationDataContainerPath;
                }
                if (applicationGroupContainerPaths)
                {
                    applicationDetail[kXXTEMoreApplicationDetailKeyGroupContainerPaths] = applicationGroupContainerPaths;
                }
                if (applicationIconImage)
                {
                    applicationDetail[kXXTEMoreApplicationDetailKeyIconImage] = applicationIconImage;
                }
                BOOL systemApp = applicationBundlePath.length == 0 || [applicationBundlePath hasPrefix:@"/Applications"] || [applicationBundleID hasPrefix:@"com.apple."];
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
    [cell setTintColor:XXTColorForeground()];
    if (self.searchController.isActive) {
        [cell setSearchText:self.searchController.searchBar.text];
    } else {
        [cell setSearchText:nil];
    }
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

XXTE_START_IGNORE_PARTIAL
- (void)didPresentSearchController:(UISearchController *)searchController {
    UIEdgeInsets insets1 = self.tableView.scrollIndicatorInsets;
    _savedInsets = insets1;
    insets1.top += 50.0 + 44.0;
    self.tableView.scrollIndicatorInsets = insets1;
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Memory

- (void)dealloc {
    [self.searchController.view removeFromSuperview];
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
