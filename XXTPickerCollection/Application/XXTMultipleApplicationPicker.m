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

@interface XXTMultipleApplicationPicker ()
<
UITableViewDelegate,
UITableViewDataSource,
UISearchDisplayDelegate
>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong, readonly) UIRefreshControl *refreshControl;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *selectedApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *unselectedApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *displaySelectedApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *displayUnselectedApplications;
@property(nonatomic, strong, readonly) LSApplicationWorkspace *applicationWorkspace;

@end

@implementation XXTMultipleApplicationPicker {
    XXTPickerTask *_pickerTask;
    NSString *_pickerSubtitle;
    UISearchDisplayController *_searchDisplayController;
}

@synthesize pickerTask = _pickerTask;

#pragma mark - XXTBasePicker

+ (NSString *)pickerKeyword {
    return @"@apps@";
}

- (NSString *)pickerResult {
    NSMutableString *selectedReplacement = [[NSMutableString alloc] initWithString:@"{\n"];
    for (NSDictionary *appDetail in self.selectedApplications) {
        [selectedReplacement appendFormat:@"\"%@\",\n", appDetail[kXXTApplicationDetailKeyBundleID]];
    }
    [selectedReplacement appendString:@"}"];
    return selectedReplacement;
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.searchDisplayController.active) {
        return UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleLightContent;
}

- (NSString *)title {
    return NSLocalizedStringFromTableInBundle(@"Applications", @"XXTPickerCollection", [XXTPickerFactory bundle], nil);
}

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        _selectedApplications = [[NSMutableArray alloc] init];
        _unselectedApplications = [[NSMutableArray alloc] init];
        _displaySelectedApplications = [[NSMutableArray alloc] init];
        _displayUnselectedApplications = [[NSMutableArray alloc] init];
    }
    return self;
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
    
    [self.pickerTask nextStep];
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
    [self updateSubtitle:NSLocalizedStringFromTableInBundle(@"Select some applications.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil)];
}

- (void)asyncApplicationList:(UIRefreshControl *)refreshControl {
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
        [self.unselectedApplications removeAllObjects];
        [self.selectedApplications removeAllObjects];
        [self.unselectedApplications addObjectsFromArray:filteredApplications];
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
    return 66.f;
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
        NSMutableArray <NSDictionary *> *selectedApplications = nil;
        NSMutableArray <NSDictionary *> *unselectedApplications = nil;
        if (tableView == self.tableView) {
            selectedApplications = self.selectedApplications;
            unselectedApplications = self.unselectedApplications;
        } else {
            selectedApplications = self.displaySelectedApplications;
            unselectedApplications = self.displayUnselectedApplications;
        }
        
        NSString *text = nil;
        if (section == kXXTApplicationPickerCellSectionSelected) {
            text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Selected Applications (%lu)", @"XXTPickerCollection", [XXTPickerFactory bundle], nil), (unsigned long)selectedApplications.count];
        } else if (section == kXXTApplicationPickerCellSectionUnselected) {
            text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Unselected Applications (%lu)", @"XXTPickerCollection", [XXTPickerFactory bundle], nil), (unsigned long)unselectedApplications.count];
        }
        if (text) {
            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:14.0] }];
            label.attributedText = attributedText;
        }
        
//        CGSize newSize = [label sizeThatFits:CGSizeMake(0, 24)];
//        label.bounds = CGRectMake(0, 0, newSize.width, newSize.height);
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
            return self.selectedApplications.count;
        } else if (section == kXXTApplicationPickerCellSectionUnselected) {
            return self.unselectedApplications.count;
        }
    } else {
        if (section == kXXTApplicationPickerCellSectionSelected) {
            return self.displaySelectedApplications.count;
        } else if (section == kXXTApplicationPickerCellSectionUnselected) {
            return self.displayUnselectedApplications.count;
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
    NSDictionary *appDetail = nil;
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTApplicationPickerCellSectionSelected) {
            appDetail = self.selectedApplications[(NSUInteger) indexPath.row];
        } else if (indexPath.section == kXXTApplicationPickerCellSectionUnselected) {
            appDetail = self.unselectedApplications[(NSUInteger) indexPath.row];
        }
    } else {
        if (indexPath.section == kXXTApplicationPickerCellSectionSelected) {
            appDetail = self.displaySelectedApplications[(NSUInteger) indexPath.row];
        } else if (indexPath.section == kXXTApplicationPickerCellSectionUnselected) {
            appDetail = self.displayUnselectedApplications[(NSUInteger) indexPath.row];
        }
    }
    [cell setApplicationName:appDetail[kXXTApplicationDetailKeyName]];
    [cell setApplicationBundleID:appDetail[kXXTApplicationDetailKeyBundleID]];
    [cell setApplicationIconImage:appDetail[kXXTApplicationDetailKeyIconImage]];
    [cell setTintColor:XXTP_PICKER_FRONT_COLOR];
    [cell setShowsReorderControl:YES];
    return cell;
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
            NSDictionary *appDetail = self.selectedApplications[fromIndexPath.row];
            if (fromIndexPath.row > toIndexPath.row) {
                [self.selectedApplications insertObject:appDetail atIndex:toIndexPath.row];
                [self.selectedApplications removeObjectAtIndex:(fromIndexPath.row + 1)];
            }
            else if (fromIndexPath.row < toIndexPath.row) {
                [self.selectedApplications insertObject:appDetail atIndex:(toIndexPath.row + 1)];
                [self.selectedApplications removeObjectAtIndex:(fromIndexPath.row)];
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
    
    NSDictionary *appDetail = nil;
    
    NSMutableArray <NSDictionary *> *selectedApplications = nil;
    NSMutableArray <NSDictionary *> *unselectedApplications = nil;
    if (tableView == self.tableView) {
        selectedApplications = self.selectedApplications;
        unselectedApplications = self.unselectedApplications;
    } else {
        selectedApplications = self.displaySelectedApplications;
        unselectedApplications = self.displayUnselectedApplications;
    }
    
    if (indexPath.section == kXXTApplicationPickerCellSectionSelected) {
        appDetail = selectedApplications[(NSUInteger) indexPath.row];
    } else if (indexPath.section == kXXTApplicationPickerCellSectionUnselected) {
        appDetail = unselectedApplications[(NSUInteger) indexPath.row];
    }
    
    NSIndexPath *toIndexPath = nil;
    
    BOOL alreadyExists = [selectedApplications containsObject:appDetail];
    
    if (alreadyExists && editingStyle == UITableViewCellEditingStyleDelete) {
        toIndexPath = [NSIndexPath indexPathForRow:0 inSection:kXXTApplicationPickerCellSectionUnselected];
        [selectedApplications removeObject:appDetail];
        [unselectedApplications insertObject:appDetail atIndex:0];
        if (tableView != self.tableView) {
            [self.selectedApplications removeObject:appDetail];
            [self.unselectedApplications insertObject:appDetail atIndex:0];
        }
    } else if (!alreadyExists && editingStyle == UITableViewCellEditingStyleInsert) {
        toIndexPath = [NSIndexPath indexPathForRow:selectedApplications.count inSection:kXXTApplicationPickerCellSectionSelected];
        [unselectedApplications removeObject:appDetail];
        [selectedApplications addObject:appDetail];
        if (tableView != self.tableView) {
            [self.unselectedApplications removeObject:appDetail];
            [self.selectedApplications addObject:appDetail];
        }
    }
    
    if (toIndexPath) {
        [tableView moveRowAtIndexPath:indexPath toIndexPath:toIndexPath];
        [tableView reloadRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self tableView:tableView reloadHeaderView:[tableView headerViewForSection:indexPath.section] forSection:indexPath.section];
    [self tableView:tableView reloadHeaderView:[tableView headerViewForSection:toIndexPath.section] forSection:toIndexPath.section];
    
    [self updateSubtitle:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%lu Application(s) selected.", @"XXTPickerCollection", [XXTPickerFactory bundle], nil), (unsigned long)self.selectedApplications.count]];
    
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
    [tableView registerNib:[UINib nibWithNibName:@"XXTApplicationCell" bundle:[XXTPickerFactory bundle]] forCellReuseIdentifier:kXXTApplicationCellReuseIdentifier];
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
        [self.displaySelectedApplications removeAllObjects];
        [self.displayUnselectedApplications removeAllObjects];
        [self.displaySelectedApplications addObjectsFromArray:[self.selectedApplications filteredArrayUsingPredicate:predicate]];
        [self.displayUnselectedApplications addObjectsFromArray:[self.unselectedApplications filteredArrayUsingPredicate:predicate]];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTMultipleApplicationPicker dealloc]");
#endif
}

@end
