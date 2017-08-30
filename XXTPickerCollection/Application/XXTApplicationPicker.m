//
// Created by Zheng on 02/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#include <objc/runtime.h>
#import "XXTApplicationPicker.h"
#import "XXTPickerFactory.h"
#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"
#import "XXTApplicationCell.h"
#import "XXTPickerNavigationController.h"
#import "XXTPickerDefine.h"
#import "XXTPickerSnippet.h"

enum {
    kXXTApplicationPickerCellSection = 0,
};

enum {
    kXXTApplicationSearchTypeName = 0,
    kXXTApplicationSearchTypeBundleID
};

#if !(TARGET_OS_SIMULATOR)
CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);
CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier);
CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier);
#else
CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable) {
    return (__bridge CFArrayRef)(@[]);
}
CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier) {
    return (__bridge CFStringRef)@"";
}
CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier) {
    return (__bridge CFDataRef)([NSData data]);
}
#endif

@interface XXTApplicationPicker ()
        <
        UITableViewDelegate,
        UITableViewDataSource,
        UISearchDisplayDelegate
        >
@property(nonatomic, strong, readonly) UIRefreshControl *refreshControl;
@property(nonatomic, strong) NSArray <NSDictionary *> *allApplications;
@property(nonatomic, strong) NSArray <NSDictionary *> *displayApplications;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSDictionary *selectedApplication;
@property(nonatomic, strong, readonly) LSApplicationWorkspace *applicationWorkspace;

@end

@implementation XXTApplicationPicker {
    NSString *_pickerSubtitle;
    UISearchDisplayController *_searchDisplayController;
}

@synthesize pickerTask = _pickerTask;

#pragma mark - XXTBasePicker

+ (NSString *)pickerKeyword {
    return @"@app@";
}

- (NSString *)pickerResult {
    return self.selectedApplication[kXXTApplicationDetailKeyBundleID];
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.searchDisplayController.active) {
        return UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleLightContent;
}

- (NSString *)title {
    return NSLocalizedStringFromTableInBundle(@"Application", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;

    _applicationWorkspace = ({
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        SEL selector = NSSelectorFromString(@"defaultWorkspace");
        LSApplicationWorkspace *applicationWorkspace = [LSApplicationWorkspace_class performSelector:selector];
        applicationWorkspace;
    });
    
    _allApplications = @[];

    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
    searchBar.placeholder = NSLocalizedStringFromTableInBundle(@"Search Application", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
    searchBar.scopeButtonTitles = @[
            NSLocalizedStringFromTableInBundle(@"Name", @"XXTPickerCollection", [XXTPickerFactory bundle], nil),
            NSLocalizedStringFromTableInBundle(@"Bundle ID", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)
    ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.backgroundColor = [UIColor whiteColor];
    searchBar.barTintColor = [UIColor whiteColor];
    searchBar.tintColor = XXTP_PICKER_FRONT_COLOR;

    UISearchDisplayController *searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.delegate = self;
    _searchDisplayController = searchDisplayController;

    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [tableView registerNib:[UINib nibWithNibName:@"XXTApplicationCell" bundle:[XXTPickerFactory bundle]] forCellReuseIdentifier:kXXTApplicationCellReuseIdentifier];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.tableHeaderView = searchBar;
        XXTP_START_IGNORE_PARTIAL
        if (XXTP_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTP_END_IGNORE_PARTIAL
        [self.view addSubview:tableView];
        tableView;
    });
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    _refreshControl = ({
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(asyncApplicationList:) forControlEvents:UIControlEventValueChanged];
        [tableViewController setRefreshControl:refreshControl];
        refreshControl;
    });
    [self.tableView.backgroundView insertSubview:self.refreshControl atIndex:0];
    
    UIBarButtonItem *rightItem = NULL;
    if ([self.pickerTask taskFinished]) {
        rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(taskFinished:)];
    } else {
        rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Next", @"XXTPickerCollection", [XXTPickerFactory bundle], nil) style:UIBarButtonItemStylePlain target:self action:@selector(taskNextStep:)];
    }
    self.navigationItem.rightBarButtonItem = rightItem;
    
    [self.refreshControl beginRefreshing];
    [self asyncApplicationList:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Select an application.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
}

- (void)asyncApplicationList:(UIRefreshControl *)refreshControl {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _allApplications = ({
            NSArray <NSString *> *applicationIdentifiers = (NSArray *)CFBridgingRelease(SBSCopyApplicationDisplayIdentifiers(false, false));
            NSMutableArray <LSApplicationProxy *> *allApplications = nil;
            if (applicationIdentifiers) {
                allApplications = [NSMutableArray arrayWithCapacity:applicationIdentifiers.count];
                [applicationIdentifiers enumerateObjectsUsingBlock:^(NSString * _Nonnull bid, NSUInteger idx, BOOL * _Nonnull stop) {
                    LSApplicationProxy *proxy = [LSApplicationProxy applicationProxyForIdentifier:bid];
                    [allApplications addObject:proxy];
                }];
            } else {
                SEL selectorAll = NSSelectorFromString(@"allApplications");
                allApplications = [self.applicationWorkspace performSelector:selectorAll];
            }
            NSString *whiteIconListPath = [[NSBundle mainBundle] pathForResource:@"xxte-white-icons" ofType:@"plist"];
            NSArray <NSString *> *blacklistIdentifiers = [NSDictionary dictionaryWithContentsOfFile:whiteIconListPath][@"xxte-white-icons"];
            NSOrderedSet <NSString *> *blacklistApplications = [[NSOrderedSet alloc] initWithArray:blacklistIdentifiers];
            NSMutableArray <NSDictionary *> *filteredApplications = [NSMutableArray arrayWithCapacity:allApplications.count];
            for (LSApplicationProxy *appProxy in allApplications) {
                @autoreleasepool {
                    NSString *applicationBundleID = appProxy.applicationIdentifier;
                    BOOL shouldAdd = ![blacklistApplications containsObject:applicationBundleID];
                    if (shouldAdd) {
                        NSString *applicationBundlePath = [appProxy.resourcesDirectoryURL path];
                        NSString *applicationContainerPath = nil;
                        NSString *applicationName = CFBridgingRelease(SBSCopyLocalizedApplicationNameForDisplayIdentifier((__bridge CFStringRef)(applicationBundleID)));
                        if (!applicationName) {
                            applicationName = appProxy.localizedName;
                        }
                        NSData *applicationIconImageData = CFBridgingRelease(SBSCopyIconImagePNGDataForDisplayIdentifier((__bridge CFStringRef)(applicationBundleID)));
                        UIImage *applicationIconImage = [UIImage imageWithData:applicationIconImageData];
                        if (XXTP_SYSTEM_8) {
                            if ([appProxy respondsToSelector:@selector(dataContainerURL)]) {
                                applicationContainerPath = [[appProxy dataContainerURL] path];
                            }
                        } else {
                            if ([appProxy respondsToSelector:@selector(containerURL)]) {
                                applicationContainerPath = [[appProxy containerURL] path];
                            }
                        }
                        NSMutableDictionary *applicationDetail = [[NSMutableDictionary alloc] init];
                        if (applicationBundleID) {
                            applicationDetail[kXXTApplicationDetailKeyBundleID] = applicationBundleID;
                        }
                        if (applicationName) {
                            applicationDetail[kXXTApplicationDetailKeyName] = applicationName;
                        }
                        if (applicationBundlePath) {
                            applicationDetail[kXXTApplicationDetailKeyBundlePath] = applicationBundlePath;
                        }
                        if (applicationContainerPath) {
                            applicationDetail[kXXTApplicationDetailKeyContainerPath] = applicationContainerPath;
                        }
                        if (applicationIconImage) {
                            applicationDetail[kXXTApplicationDetailKeyIconImage] = applicationIconImage;
                        }
                        [filteredApplications addObject:[applicationDetail copy]];
                    }
                }
            }
            filteredApplications;
        });
        if (self.allApplications.count != 0) {
            self.selectedApplication = self.allApplications[0];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (refreshControl && [refreshControl isRefreshing]) {
                [refreshControl endRefreshing];
            }
        });
    });
}

#pragma mark - Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kXXTApplicationPickerCellSection) {
        return 66.f;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == kXXTApplicationPickerCellSection) {
            return self.allApplications.count;
        }
    } else {
        if (section == kXXTApplicationPickerCellSection) {
            return self.displayApplications.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XXTApplicationCell *cell = [tableView dequeueReusableCellWithIdentifier:kXXTApplicationCellReuseIdentifier];
    if (cell == nil) {
        cell = [[XXTApplicationCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:kXXTApplicationCellReuseIdentifier];
    }
    NSDictionary *appDetail = nil;;
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTApplicationPickerCellSection) {
            appDetail = self.allApplications[(NSUInteger) indexPath.row];
        }
    } else {
        if (indexPath.section == kXXTApplicationPickerCellSection) {
            appDetail = self.displayApplications[(NSUInteger) indexPath.row];
        }
    }
    [cell setApplicationName:appDetail[kXXTApplicationDetailKeyName]];
    [cell setApplicationBundleID:appDetail[kXXTApplicationDetailKeyBundleID]];
    [cell setApplicationIconImage:appDetail[kXXTApplicationDetailKeyIconImage]];
    [cell setTintColor:XXTP_PICKER_FRONT_COLOR];
    if (appDetail == self.selectedApplication) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *appDetail = nil;
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTApplicationPickerCellSection) {
            appDetail = self.allApplications[(NSUInteger) indexPath.row];
        }
    } else {
        if (indexPath.section == kXXTApplicationPickerCellSection) {
            appDetail = self.displayApplications[(NSUInteger) indexPath.row];
        }
    }

    for (NSUInteger i = 0; i < tableView.visibleCells.count; ++i) {
        tableView.visibleCells[i].accessoryType = UITableViewCellAccessoryNone;
    }
    if (tableView != self.tableView) {
        for (NSUInteger i = 0; i < self.tableView.visibleCells.count; ++i) {
            if (self.allApplications[i] == appDetail) {
                self.tableView.visibleCells[i].accessoryType = UITableViewCellAccessoryCheckmark;
                [self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForCell:self.tableView.visibleCells[i]]
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:NO];
            } else {
                self.tableView.visibleCells[i].accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }

    XXTApplicationCell *cell1 = [tableView cellForRowAtIndexPath:indexPath];
    cell1.accessoryType = UITableViewCellAccessoryCheckmark;
    self.selectedApplication = appDetail;

    [self updateSubtitle:[cell1 applicationBundleID]];
}

#pragma mark - Task Operations

- (void)taskFinished:(UIBarButtonItem *)sender {
    [self.pickerFactory performFinished:self];
}

- (void)taskNextStep:(UIBarButtonItem *)sender {
    [self.pickerFactory performNextStep:self];
}

- (void)updateSubtitle:(NSString *)subtitle {
    _pickerSubtitle = subtitle;
    [self.pickerFactory performUpdateStep:self];
}

- (NSString *)pickerSubtitle {
    return _pickerSubtitle;
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    [tableView registerNib:[UINib nibWithNibName:@"XXTApplicationCell" bundle:[XXTPickerFactory bundle]] forCellReuseIdentifier:kXXTApplicationCellReuseIdentifier];
    XXTPickerNavigationController *navController = ((XXTPickerNavigationController *)self.navigationController);
    [navController.popupBar setHidden:YES];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    XXTPickerNavigationController *navController = ((XXTPickerNavigationController *)self.navigationController);
    [navController.popupBar setHidden:NO];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {

}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self reloadSearch];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self reloadSearch];
    return YES;
}

- (void)reloadSearch {
    NSPredicate *predicate = nil;
    if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == kXXTApplicationSearchTypeName) {
        predicate = [NSPredicate predicateWithFormat:@"kXXTApplicationDetailKeyName CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    } else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == kXXTApplicationSearchTypeBundleID) {
        predicate = [NSPredicate predicateWithFormat:@"kXXTApplicationDetailKeyBundleID CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    }
    if (predicate) {
        self.displayApplications = [[NSArray alloc] initWithArray:[self.allApplications filteredArrayUsingPredicate:predicate]];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTApplicationPicker dealloc]");
#endif
}

@end