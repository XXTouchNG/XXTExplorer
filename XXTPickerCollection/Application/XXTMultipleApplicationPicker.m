//
// Created by Zheng on 02/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <objc/runtime.h>
#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"
#import "XXTMultipleApplicationPicker.h"
#import "XXTApplicationCell.h"
#import "XXTPickerInsetsLabel.h"
#import "XXTPickerFactory.h"
#import "XXTPickerDefine.h"
#import "XXTPickerSnippet.h"

#import "XXTExplorerFooterView.h"

enum {
    kXXTApplicationPickerCellSectionSelected = 0,
    kXXTApplicationPickerCellSectionUnselected
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
CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);
CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier);
CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier);
#endif

@interface XXTMultipleApplicationPicker ()
<
UITableViewDelegate,
UITableViewDataSource,
UISearchDisplayDelegate
>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong, readonly) UIRefreshControl *refreshControl;

@property(nonatomic, strong, readonly) NSMutableDictionary <NSString *, NSDictionary *> *applications;

@property(nonatomic, strong, readonly) NSMutableArray <NSString *> *selectedIdentifiers;
@property(nonatomic, strong, readonly) NSMutableArray <NSString *> *unselectedIdentifiers;
@property(nonatomic, strong, readonly) NSMutableArray <NSString *> *displaySelectedIdentifiers;
@property(nonatomic, strong, readonly) NSMutableArray <NSString *> *displayUnselectedIdentifiers;

@property(nonatomic, strong, readonly) LSApplicationWorkspace *applicationWorkspace;

@end

// type
// title
// subtitle

@implementation XXTMultipleApplicationPicker {
    NSString *_pickerSubtitle;
    UISearchDisplayController *_searchDisplayController;
}

@synthesize pickerTask = _pickerTask;
@synthesize pickerMeta = _pickerMeta;

#pragma mark - XXTBasePicker

+ (NSString *)pickerKeyword {
    return @"apps";
}

- (NSArray <NSString *> *)pickerResult {
    return [self.selectedIdentifiers copy];
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.searchDisplayController.active) {
        return UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleLightContent;
}

- (NSString *)title {
    if (self.pickerMeta[@"title"]) {
        return self.pickerMeta[@"title"];
    } else {
        return NSLocalizedStringFromTable(@"Applications", @"XXTPickerCollection", nil);
    }
}

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        _applications = [[NSMutableDictionary alloc] init];
        _selectedIdentifiers = [[NSMutableArray alloc] init];
        _unselectedIdentifiers = [[NSMutableArray alloc] init];
        _displaySelectedIdentifiers = [[NSMutableArray alloc] init];
        _displayUnselectedIdentifiers = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    _applicationWorkspace = ({
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        SEL selector = NSSelectorFromString(@"defaultWorkspace");
        LSApplicationWorkspace *applicationWorkspace = [LSApplicationWorkspace_class performSelector:selector];
        applicationWorkspace;
    });
#pragma clang diagnostic pop
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
    searchBar.placeholder = NSLocalizedStringFromTable(@"Search Application", @"XXTPickerCollection", nil);
    searchBar.scopeButtonTitles = @[
                                    NSLocalizedStringFromTable(@"Name", @"XXTPickerCollection", nil),
                                    NSLocalizedStringFromTable(@"Bundle ID", @"XXTPickerCollection", nil)
                                    ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.backgroundColor = [UIColor whiteColor];
    searchBar.barTintColor = [UIColor whiteColor];
    
    UISearchDisplayController *searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.delegate = self;
    _searchDisplayController = searchDisplayController;
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [tableView registerNib:[UINib nibWithNibName:@"XXTApplicationCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kXXTApplicationCellReuseIdentifier];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.tableHeaderView = searchBar;
        XXTP_START_IGNORE_PARTIAL
        if (XXTP_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTP_END_IGNORE_PARTIAL
        [tableView setEditing:YES animated:NO];
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
        rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Next", @"XXTPickerCollection", nil) style:UIBarButtonItemStylePlain target:self action:@selector(taskNextStep:)];
    }
    self.navigationItem.rightBarButtonItem = rightItem;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self.refreshControl beginRefreshing];
    [self asyncApplicationList:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *subtitle = nil;
    if (self.pickerMeta[@"subtitle"]) {
        subtitle = self.pickerMeta[@"subtitle"];
    } else {
        subtitle = NSLocalizedStringFromTable(@"Select some applications.", @"XXTPickerCollection", nil);
    }
    [self updateSubtitle:subtitle];
}

- (void)asyncApplicationList:(UIRefreshControl *)refreshControl {
    
    NSArray <NSString *> *defaultIdentifiers = self.pickerMeta[@"default"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
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
        [self.unselectedIdentifiers removeAllObjects];
        [self.selectedIdentifiers removeAllObjects];
        
        NSString *whiteIconListPath = [[NSBundle mainBundle] pathForResource:@"xxte-white-icons" ofType:@"plist"];
        NSArray <NSString *> *blacklistIdentifiers = [NSDictionary dictionaryWithContentsOfFile:whiteIconListPath][@"xxte-white-icons"];
        NSOrderedSet <NSString *> *blacklistApplications = [[NSOrderedSet alloc] initWithArray:blacklistIdentifiers];
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
                    } else {
                        continue;
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
                    [self.unselectedIdentifiers addObject:applicationBundleID];
                    [self.applications setObject:[applicationDetail copy]
                                          forKey:applicationBundleID];
                }
            }
        }
        for (NSString *defaultIdentifier in defaultIdentifiers) {
            if ([self.unselectedIdentifiers containsObject:defaultIdentifier]) {
                [self.selectedIdentifiers addObject:defaultIdentifier];
                [self.unselectedIdentifiers removeObject:defaultIdentifier];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (refreshControl && [refreshControl isRefreshing]) {
                [refreshControl endRefreshing];
            }
        });
    });
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24.0;
}

- (void)tableView:(UITableView *)tableView reloadHeaderView:(UITableViewHeaderFooterView *)view forSection:(NSInteger)section {
    [self tableView:tableView willDisplayHeaderView:view forSection:section];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UILabel *label = ((UITableViewHeaderFooterView *)view).textLabel;
    if (label) {
        NSMutableArray <NSString *> *selectedIdentifiers = nil;
        NSMutableArray <NSString *> *unselectedIdentifiers = nil;
        if (tableView == self.tableView) {
            selectedIdentifiers = self.selectedIdentifiers;
            unselectedIdentifiers = self.unselectedIdentifiers;
        } else {
            selectedIdentifiers = self.displaySelectedIdentifiers;
            unselectedIdentifiers = self.displayUnselectedIdentifiers;
        }
        
        NSString *text = nil;
        if (section == kXXTApplicationPickerCellSectionSelected) {
            text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Selected Applications (%lu)", @"XXTPickerCollection", nil), (unsigned long)selectedIdentifiers.count];
        } else if (section == kXXTApplicationPickerCellSectionUnselected) {
            text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Unselected Applications (%lu)", @"XXTPickerCollection", nil), (unsigned long)unselectedIdentifiers.count];
        }
        if (text) {
            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:14.0] }];
            label.attributedText = attributedText;
        }
        
        [label sizeToFit];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *kMEWApplicationHeaderViewReuseIdentifier = @"kMEWApplicationHeaderViewReuseIdentifier";
    
    UITableViewHeaderFooterView *applicationHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kMEWApplicationHeaderViewReuseIdentifier];
    if (!applicationHeaderView) {
        applicationHeaderView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:kMEWApplicationHeaderViewReuseIdentifier];
    }
    
    return applicationHeaderView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == kXXTApplicationPickerCellSectionSelected) {
            return self.selectedIdentifiers.count;
        } else if (section == kXXTApplicationPickerCellSectionUnselected) {
            return self.unselectedIdentifiers.count;
        }
    } else {
        if (section == kXXTApplicationPickerCellSectionSelected) {
            return self.displaySelectedIdentifiers.count;
        } else if (section == kXXTApplicationPickerCellSectionUnselected) {
            return self.displayUnselectedIdentifiers.count;
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
    NSString *identifier = nil;
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTApplicationPickerCellSectionSelected) {
            identifier = self.selectedIdentifiers[(NSUInteger) indexPath.row];
        } else if (indexPath.section == kXXTApplicationPickerCellSectionUnselected) {
            identifier = self.unselectedIdentifiers[(NSUInteger) indexPath.row];
        }
    } else {
        if (indexPath.section == kXXTApplicationPickerCellSectionSelected) {
            identifier = self.displaySelectedIdentifiers[(NSUInteger) indexPath.row];
        } else if (indexPath.section == kXXTApplicationPickerCellSectionUnselected) {
            identifier = self.displayUnselectedIdentifiers[(NSUInteger) indexPath.row];
        }
    }
    if (identifier) {
        NSDictionary *appDetail = self.applications[identifier];
        [cell setApplicationName:appDetail[kXXTApplicationDetailKeyName]];
        [cell setApplicationBundleID:appDetail[kXXTApplicationDetailKeyBundleID]];
        [cell setApplicationIconImage:appDetail[kXXTApplicationDetailKeyIconImage]];
        [cell setTintColor:XXTE_COLOR];
        [cell setShowsReorderControl:YES];
        return cell;
    }
    return [UITableViewCell new];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTApplicationPickerCellSectionSelected) {
            return YES; // There is no need to change its order.
        }
    }
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (tableView == self.tableView) {
        if (sourceIndexPath.section == kXXTApplicationPickerCellSectionSelected && proposedDestinationIndexPath.section == kXXTApplicationPickerCellSectionSelected) {
            return proposedDestinationIndexPath;
        }
    }
    return sourceIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    if (tableView == self.tableView) {
        if (fromIndexPath.section == kXXTApplicationPickerCellSectionSelected && toIndexPath.section == kXXTApplicationPickerCellSectionSelected) {
            NSString *identifier = self.selectedIdentifiers[fromIndexPath.row];
            if (fromIndexPath.row > toIndexPath.row) {
                [self.selectedIdentifiers insertObject:identifier atIndex:toIndexPath.row];
                [self.selectedIdentifiers removeObjectAtIndex:(fromIndexPath.row + 1)];
            }
            else if (fromIndexPath.row < toIndexPath.row) {
                [self.selectedIdentifiers insertObject:identifier atIndex:(toIndexPath.row + 1)];
                [self.selectedIdentifiers removeObjectAtIndex:(fromIndexPath.row)];
            }
        }
        [tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kXXTApplicationPickerCellSectionSelected) {
        return UITableViewCellEditingStyleDelete;
    } else if (indexPath.section == kXXTApplicationPickerCellSectionUnselected) {
        return UITableViewCellEditingStyleInsert;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = nil;
    
    NSMutableArray <NSString *> *selectedIdentifiers = nil;
    NSMutableArray <NSString *> *unselectedIdentifiers = nil;
    if (tableView == self.tableView) {
        selectedIdentifiers = self.selectedIdentifiers;
        unselectedIdentifiers = self.unselectedIdentifiers;
    } else {
        selectedIdentifiers = self.displaySelectedIdentifiers;
        unselectedIdentifiers = self.displayUnselectedIdentifiers;
    }
    
    if (indexPath.section == kXXTApplicationPickerCellSectionSelected) {
        identifier = selectedIdentifiers[(NSUInteger) indexPath.row];
    } else if (indexPath.section == kXXTApplicationPickerCellSectionUnselected) {
        identifier = unselectedIdentifiers[(NSUInteger) indexPath.row];
    }
    
    NSIndexPath *toIndexPath = nil;
    BOOL alreadyExists = identifier ? [selectedIdentifiers containsObject:identifier] : NO;
    
    if (alreadyExists && editingStyle == UITableViewCellEditingStyleDelete) {
        toIndexPath = [NSIndexPath indexPathForRow:0 inSection:kXXTApplicationPickerCellSectionUnselected];
        if (identifier) {
            [selectedIdentifiers removeObject:identifier];
            [unselectedIdentifiers insertObject:identifier atIndex:0];
            if (tableView != self.tableView) {
                [self.selectedIdentifiers removeObject:identifier];
                [self.unselectedIdentifiers insertObject:identifier atIndex:0];
            }
        }
    } else if (!alreadyExists && editingStyle == UITableViewCellEditingStyleInsert) {
        toIndexPath = [NSIndexPath indexPathForRow:selectedIdentifiers.count inSection:kXXTApplicationPickerCellSectionSelected];
        if (identifier) {
            [unselectedIdentifiers removeObject:identifier];
            [selectedIdentifiers addObject:identifier];
            if (tableView != self.tableView) {
                [self.unselectedIdentifiers removeObject:identifier];
                [self.selectedIdentifiers addObject:identifier];
            }
        }
    }
    
    if (toIndexPath) {
        [tableView moveRowAtIndexPath:indexPath toIndexPath:toIndexPath];
        [tableView reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self tableView:tableView reloadHeaderView:[tableView headerViewForSection:indexPath.section] forSection:indexPath.section];
    [self tableView:tableView reloadHeaderView:[tableView headerViewForSection:toIndexPath.section] forSection:toIndexPath.section];
    
    [self updateSubtitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%lu Application(s) selected.", @"XXTPickerCollection", nil), (unsigned long)self.selectedIdentifiers.count]];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    [tableView setEditing:YES animated:NO];
    [tableView registerNib:[UINib nibWithNibName:@"XXTApplicationCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kXXTApplicationCellReuseIdentifier];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    [self.tableView reloadData];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self tableViewReloadSearch:controller.searchResultsTableView];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self tableViewReloadSearch:controller.searchResultsTableView];
    return YES;
}

- (void)tableViewReloadSearch:(UITableView *)tableView {
    NSPredicate *predicate = nil;
    if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == kXXTApplicationSearchTypeName) {
        predicate = [NSPredicate predicateWithFormat:@"kXXTApplicationDetailKeyName CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    } else if (self.searchDisplayController.searchBar.selectedScopeButtonIndex == kXXTApplicationSearchTypeBundleID) {
        predicate = [NSPredicate predicateWithFormat:@"kXXTApplicationDetailKeyBundleID CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    }
    if (predicate) {
        [self.displaySelectedIdentifiers removeAllObjects];
        [self.displayUnselectedIdentifiers removeAllObjects];
        [self.displaySelectedIdentifiers addObjectsFromArray:[self.selectedIdentifiers filteredArrayUsingPredicate:predicate]];
        [self.displayUnselectedIdentifiers addObjectsFromArray:[self.unselectedIdentifiers filteredArrayUsingPredicate:predicate]];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTMultipleApplicationPicker dealloc]");
#endif
}

@end
