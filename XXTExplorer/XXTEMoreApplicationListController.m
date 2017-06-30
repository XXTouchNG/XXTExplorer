//
// Created by Zheng on 02/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#include <objc/runtime.h>
#import "XXTEMoreApplicationListController.h"
#import "LSApplicationProxy.h"
#import "XXTEMoreApplicationCell.h"
#import "XXTEMoreApplicationDetailController.h"
#import "UINavigationController+XXTEFullscreenPopGesture.h"

enum {
    kXXTEMoreApplicationListControllerCellSection = 0,
};

enum {
    kXXTEMoreApplicationSearchTypeName = 0,
    kXXTEMoreApplicationSearchTypeBundleID
};

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
@property(nonatomic, strong) NSArray <NSDictionary *> *allApplications;
@property(nonatomic, strong) NSArray <NSDictionary *> *displayApplications;
@property(nonatomic, strong) UISearchController *searchController;

@end

@implementation XXTEMoreApplicationListController

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.hidesBottomBarWhenPushed = YES;
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.searchController.active) {
        return UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleLightContent;
}

- (NSString *)title {
    return NSLocalizedString(@"Application List", nil);
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.definesPresentationContext = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;

    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    SEL selector = NSSelectorFromString(@"defaultWorkspace");
    NSObject *workspace = [LSApplicationWorkspace_class performSelector:selector];
    SEL selectorAll = NSSelectorFromString(@"allApplications");
    NSArray <LSApplicationProxy *> *allApplications = [workspace performSelector:selectorAll];
    
    NSString *whiteIconListPath = [[NSBundle mainBundle] pathForResource:@"xxte-white-icons" ofType:@"plist"];
    NSSet <NSString *> *blacklistApplications = [NSDictionary dictionaryWithContentsOfFile:whiteIconListPath][@"xxte-white-icons"];
    NSMutableArray <NSDictionary *> *filteredApplications = [NSMutableArray arrayWithCapacity:allApplications.count];
    for (LSApplicationProxy *appProxy in allApplications) {
        BOOL shouldAdd = YES;
        for (NSString *appId in blacklistApplications) {
            if ([appId isEqualToString:[appProxy applicationIdentifier]]) {
                shouldAdd = NO;
            }
        }
        if (shouldAdd) {
            NSString *applicationIdentifier = appProxy.applicationIdentifier;
            NSString *applicationBundle = [appProxy.resourcesDirectoryURL path];
            NSString *applicationContainer = nil;
            NSString *applicationLocalizedName = CFBridgingRelease(SBSCopyLocalizedApplicationNameForDisplayIdentifier((__bridge CFStringRef)(applicationIdentifier)));
            UIImage *applicationIconImage = [UIImage imageWithData:CFBridgingRelease(SBSCopyIconImagePNGDataForDisplayIdentifier((__bridge CFStringRef)(applicationIdentifier)))];
            if (XXTE_SYSTEM_8) {
                applicationContainer = [[appProxy dataContainerURL] path];
            } else {
                applicationContainer = [[appProxy containerURL] path];
            }
            if (applicationIdentifier && applicationBundle && applicationContainer && applicationLocalizedName && applicationIconImage) {
                [filteredApplications addObject:@{@"applicationIdentifier": applicationIdentifier, @"applicationBundle": applicationBundle, @"applicationContainer": applicationContainer, @"applicationLocalizedName": applicationLocalizedName, @"applicationIconImage": applicationIconImage}];
            }
        }
    }
    self.allApplications = filteredApplications;

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [tableView registerNib:[UINib nibWithNibName:@"XXTEMoreApplicationCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kXXTEMoreApplicationCellReuseIdentifier];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.delegate = self;
//    searchController.hidesNavigationBarDuringPresentation = NO;
    searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController = searchController;

    UISearchBar *searchBar = searchController.searchBar;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    searchBar.placeholder = NSLocalizedString(@"Search Application", nil);
    searchBar.scopeButtonTitles = @[
            NSLocalizedString(@"Name", nil),
            NSLocalizedString(@"Bundle ID", nil)
    ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.backgroundColor = [UIColor whiteColor];
    searchBar.barTintColor = [UIColor whiteColor];
    searchBar.tintColor = XXTE_COLOR;
    searchBar.delegate = self;
    tableView.tableHeaderView = searchBar;
}

#pragma mark - Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kXXTEMoreApplicationListControllerCellSection) {
        return 66.f;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active == NO) {
        if (section == kXXTEMoreApplicationListControllerCellSection) {
            return self.allApplications.count;
        }
    } else {
        if (section == kXXTEMoreApplicationListControllerCellSection) {
            return self.displayApplications.count;
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
    if (self.searchController.active == NO) {
        if (indexPath.section == kXXTEMoreApplicationListControllerCellSection) {
            applicationDetail = self.allApplications[(NSUInteger) indexPath.row];
        }
    } else {
        if (indexPath.section == kXXTEMoreApplicationListControllerCellSection) {
            applicationDetail = self.displayApplications[(NSUInteger) indexPath.row];
        }
    }
    [cell setApplicationName:applicationDetail[@"applicationLocalizedName"]];
    [cell setApplicationBundleID:applicationDetail[@"applicationIdentifier"]];
    [cell setApplicationIconImage:applicationDetail[@"applicationIconImage"]];
    [cell setTintColor:XXTE_COLOR];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *applicationDetail = nil;
    if (self.searchController.active == NO) {
        if (indexPath.section == kXXTEMoreApplicationListControllerCellSection) {
            applicationDetail = self.allApplications[(NSUInteger) indexPath.row];
        }
    } else {
        if (indexPath.section == kXXTEMoreApplicationListControllerCellSection) {
            applicationDetail = self.displayApplications[(NSUInteger) indexPath.row];
        }
    }

    XXTEMoreApplicationDetailController *applicationDetailController = [[XXTEMoreApplicationDetailController alloc] initWithStyle:UITableViewStyleGrouped];
    applicationDetailController.applicationDetail = applicationDetail;
    [self.navigationController pushViewController:applicationDetailController animated:YES];
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.xxte_fullscreenPopGestureRecognizer.enabled = NO;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.xxte_fullscreenPopGestureRecognizer.enabled = YES;
}

#pragma mark - UISearchResultsUpdating

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearchByContent:searchText andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self reloadSearchByContent:searchBar.text andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadSearchByContent:searchController.searchBar.text andCategory:searchController.searchBar.selectedScopeButtonIndex];
}

- (void)reloadSearchByContent:(NSString *)searchText andCategory:(NSUInteger)category {
    NSPredicate *predicate = nil;
    if (category == kXXTEMoreApplicationSearchTypeName) {
        predicate = [NSPredicate predicateWithFormat:@"applicationLocalizedName CONTAINS[cd] %@", searchText];
    } else if (category == kXXTEMoreApplicationSearchTypeBundleID) {
        predicate = [NSPredicate predicateWithFormat:@"applicationIdentifier CONTAINS[cd] %@", searchText];
    }
    if (predicate) {
        self.displayApplications = [[NSArray alloc] initWithArray:[self.allApplications filteredArrayUsingPredicate:predicate]];
    }
    [self.tableView reloadData];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchController.searchBar resignFirstResponder];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreApplicationListController dealloc]");
#endif
}

@end
