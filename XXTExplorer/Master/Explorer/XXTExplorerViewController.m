//
//  XXTExplorerViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"

#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"

#import "XXTExplorerHeaderView.h"
#import "XXTExplorerFooterView.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerViewHomeCell.h"

#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import "XXTExplorerEntryReader.h"
#import "XXTExplorerEntryOpenWithViewController.h"
#import "XXTENavigationController.h"

#import "XXTExplorerViewController+Notification.h"
#import "XXTExplorerViewController+XXTESwipeTableCellDelegate.h"
#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"
#import "XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.h"
#import "XXTExplorerViewController+LGAlertViewDelegate.h"
#import "XXTExplorerViewController+UITableViewDropDelegate.h"
#import "XXTExplorerViewController+UITableViewDragDelegate.h"
#import "XXTExplorerViewController+ArchiverOperation.h"
#import "XXTExplorerViewController+FileOperation.h"
#import "XXTExplorerViewController+PasteboardOperations.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerItemPreviewController.h"
#import "XXTExplorerNavigationController.h"
#import "XXTExplorerSearchResultsViewController.h"


@interface XXTExplorerViewController ()
<UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate,
UIViewControllerPreviewingDelegate, XXTExplorerFooterViewDelegate,
XXTExplorerItemPreviewDelegate, XXTExplorerItemPreviewActionDelegate,
XXTExplorerDirectoryPreviewDelegate, XXTExplorerDirectoryPreviewActionDelegate,
UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate
>

@property (nonatomic, strong) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) XXTExplorerSearchResultsViewController *searchResultsController;

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong) UIDropInteraction *dropInteraction;
XXTE_END_IGNORE_PARTIAL

@end

@implementation XXTExplorerViewController {
    BOOL firstTimeLoaded;
}

@synthesize tableView = _tableView;
@synthesize refreshControl = _refreshControl;
@synthesize footerView = _footerView;

- (instancetype)init {
    return [self initWithEntryPath:nil];
}

- (instancetype)initWithEntryPath:(NSString *)path {
    if (self = [super init]) {
        [self setupWithPath:path];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _displayCurrentPath = YES;
    _homeEntryList = [[NSMutableArray alloc] init];
    _entryList = [[NSMutableArray alloc] init];
    {
        if (!path) {
            if (![self.class.explorerFileManager fileExistsAtPath:self.class.initialPath])
            {
                NSError *createDirectoryError = nil;
                BOOL createDirectoryResult = [self.class.explorerFileManager createDirectoryAtPath:self.class.initialPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
                if (!createDirectoryResult) {

                }
            }
            path = self.class.initialPath;
        }
        _entryPath = path;
    }
    {
        XXTExplorerEntry *entry = [[[self class] explorerEntryParser] entryOfPath:path withError:nil];
        _entry = entry;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.definesPresentationContext = YES;
    if (self.title.length == 0) {
        if (self == [self.navigationController.viewControllers firstObject] && !self.isPreviewed) {
            if (isAppStore()) {
                self.title = NSLocalizedString(@"Files", nil);
            } else {
                self.title = NSLocalizedString(@"My Scripts", nil);
            }
        } else {
            if (self.historyMode) {
                self.title = NSLocalizedString(@"View History", nil);
            } else {
                NSString *entryPath = self.entryPath;
                if (entryPath) {
                    NSString *entryName = [entryPath lastPathComponent];
                    self.title = entryName;
                }
            }
        }
    }
    
    {
        XXTE_START_IGNORE_PARTIAL
        if (isOS11Above()) {
            self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        }
        XXTE_END_IGNORE_PARTIAL
        
        if (NO == self.isPreviewed)
        {
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
        }
    }
    
    {
        self.view.backgroundColor = XXTColorPlainBackground();
        [self.view addSubview:self.tableView];
    }
    
    {
        UITableViewController *tableViewController = [[UITableViewController alloc] init];
        tableViewController.tableView = self.tableView;
        [tableViewController setRefreshControl:self.refreshControl];
        [self.tableView.backgroundView insertSubview:self.refreshControl atIndex:0];
    }
    
    _searchResultsController = ({
        XXTExplorerSearchResultsViewController *controller = [[XXTExplorerSearchResultsViewController alloc] initWithStyle:UITableViewStylePlain];
        controller.historyMode = self.historyMode;
        controller.tableView.delegate = self;  // only set delegate, no data source
        controller;
    });
    
    _searchController = ({
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
        searchController.searchResultsUpdater = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController.hidesNavigationBarDuringPresentation = YES;
        searchController.delegate = self;
        searchController;
    });
    
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.placeholder = NSLocalizedString(@"Search Files", nil);
    searchBar.scopeButtonTitles = @[
                                    NSLocalizedString(@"Current", nil),
                                    NSLocalizedString(@"Recursively", nil)
                                    ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.delegate = self;
    
    if (@available(iOS 11.0, *)) {
        UITextField *textField = nil;
        if (@available(iOS 13.0, *)) {
            textField = [searchBar performSelector:@selector(searchTextField)];
        } else {
            textField = [searchBar valueForKey:@"searchField"];
        }
        textField.textColor = XXTColorPlainTitleText();
        textField.tintColor = XXTColorForeground();
        searchBar.barTintColor = XXTColorBarTint();
        searchBar.tintColor = XXTColorTint();
        if (@available(iOS 13.0, *)) {
            
        } else {
#ifndef APPSTORE
            UIView *backgroundView = [textField.subviews firstObject];
            backgroundView.backgroundColor = XXTColorPlainBackground();
            backgroundView.layer.cornerRadius = 10.0;
            backgroundView.clipsToBounds = YES;
#endif
        }
        self.navigationItem.searchController = self.searchController;
    }
    else {
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        searchBar.backgroundColor = XXTColorPlainBackground();
        searchBar.barTintColor = XXTColorPlainBackground();
        searchBar.tintColor = XXTColorForeground();
        self.tableView.tableHeaderView = searchBar;
    }
    
    {
        [self configureToolbarAndCover];
        if (@available(iOS 11.0, *))
        {
            UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
            [self.toolbar addInteraction:dropInteraction];
            _dropInteraction = dropInteraction;
        }
    }
    
    {
        [self.tableView setTableFooterView:self.footerView];
    }
    
    [self setupConstraints];
    [self loadEntryListData];
}

- (void)viewWillAppear:(BOOL)animated {
    [self restoreTheme];
    [super viewWillAppear:animated];
    [self registerNotifications];
    [self updateToolbarStatus];
    [self updateToolbarButton];
    if (firstTimeLoaded) {
        [self reloadEntryListView];
    } else if (!self.isPreviewed) {
        [self refreshControlTriggered:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!firstTimeLoaded && !self.isPreviewed) {
        firstTimeLoaded = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeNotifications];
    if ([self isEditing]) {
        [self setEditing:NO animated:YES];
    }
}

- (void)setupConstraints {
    if (self.isPreviewed) {
        self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
          ];
        [self.view addConstraints:constraints];
    } else {
        self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
#ifndef APPSTORE
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.toolbar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
          ];
#else
        NSArray <NSLayoutConstraint *> *constraints =
        @[
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.toolbar attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
          ];
#endif
        [self.view addConstraints:constraints];
    }
}

XXTE_START_IGNORE_PARTIAL
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.allowsPreviewing) {
        if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
            if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                // retain the context to avoid registering more than once
                if (!self.previewingContext)
                {
                    self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
                }
            } else {
                [self unregisterForPreviewingWithContext:self.previewingContext];
                self.previewingContext = nil;
            }
        }
    }
}
XXTE_END_IGNORE_PARTIAL

- (void)restoreTheme {
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    [navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: XXTColorBarText()}];
    navigationBar.tintColor = XXTColorTint();
    navigationBar.barTintColor = XXTColorBarTint();
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Item Picker Inherit

- (BOOL)showsHomeSeries {
    return YES;
}

- (BOOL)allowsPreviewing {
    return YES;
}

- (BOOL)allowDragAndDrop {
    return YES;
}

- (BOOL)shouldDisplayEntry:(NSDictionary *)entryDetail {
    return YES;
}

- (XXTExplorerViewEntryListSortField)explorerSortField {
    if (_historyMode) {
        return _internalSortField;
    }
    return XXTEDefaultsEnum(XXTExplorerViewEntryListSortFieldKey, XXTExplorerViewEntryListSortFieldModificationDate);
}

- (XXTExplorerViewEntryListSortOrder)explorerSortOrder {
    if (_historyMode) {
        return _internalSortOrder;
    }
    return XXTEDefaultsEnum(XXTExplorerViewEntryListSortOrderKey, XXTExplorerViewEntryListSortOrderDesc);
}

- (void)setExplorerSortField:(XXTExplorerViewEntryListSortField)explorerSortField {
    if (self.historyMode) {
        _internalSortField = explorerSortField;
        return;
    }
    XXTEDefaultsSetBasic(XXTExplorerViewEntryListSortFieldKey, explorerSortField);
}

- (void)setExplorerSortOrder:(XXTExplorerViewEntryListSortOrder)explorerSortOrder {
    if (self.historyMode) {
        _internalSortOrder = explorerSortOrder;
        return;
    }
    XXTEDefaultsSetBasic(XXTExplorerViewEntryListSortOrderKey, explorerSortOrder);
}

#pragma mark - NSFileManager

- (BOOL)loadEntryListDataWithError:(NSError **)error {
    
    {
        BOOL homeEnabled = XXTEDefaultsBool(XXTExplorerViewEntryHomeEnabledKey, NO);
        [self.homeEntryList removeAllObjects];
        if ([self showsHomeSeries] && homeEnabled &&
            (self == [self.navigationController.viewControllers firstObject]) && !self.isPreviewed) {
            NSArray <NSDictionary *> *entrySeries = XXTEBuiltInDefaultsObject(XXTExplorerViewBuiltHomeSeries);
            if (entrySeries) {
                [self.homeEntryList addObjectsFromArray:entrySeries];
            }
        }
    }

    NSArray <XXTExplorerEntry *> *newEntryList = ({
        NSString *entryPath = self.entryPath;
        promiseFixPermission(entryPath, NO);
        
        BOOL hidesDot = XXTEDefaultsBool(XXTExplorerViewEntryListHideDotItemKey, YES);
        NSError *listError = nil;
        NSArray <NSString *> *entrySubdirectoryPathList = [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&listError];
        if (listError && error) {
            *error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:listError.localizedDescription}];
        }
        
        NSMutableArray <XXTExplorerEntry *> *entryDirectoryAttributesList = [[NSMutableArray alloc] init];
        NSMutableArray <XXTExplorerEntry *> *entryBundleAttributesList = [[NSMutableArray alloc] init];
        NSMutableArray <XXTExplorerEntry *> *entryOtherAttributesList = [[NSMutableArray alloc] init];
        
        for (NSString *entrySubdirectoryName in entrySubdirectoryPathList) {
            @autoreleasepool {
                if (hidesDot && [entrySubdirectoryName hasPrefix:@"."]) {
                    continue;
                }
                NSString *entrySubdirectoryPath = [entryPath stringByAppendingPathComponent:entrySubdirectoryName];
                XXTExplorerEntry *entryDetail = [self.class.explorerEntryParser entryOfPath:entrySubdirectoryPath withError:nil];
                if (!entryDetail) {
                    continue;
                }
                if ([self shouldDisplayEntry:entryDetail] == NO) {
                    continue;
                }
                if (entryDetail.isMaskedDirectory) {
                    [entryDirectoryAttributesList addObject:entryDetail];
                } else if (entryDetail.isBundle) {
                    [entryBundleAttributesList addObject:entryDetail];
                } else {
                    [entryOtherAttributesList addObject:entryDetail];
                }
            }
        }
        
        XXTExplorerViewEntryListSortField sortField = self.explorerSortField;
        XXTExplorerViewEntryListSortOrder sortOrder = self.explorerSortOrder;
        
        NSString *sortFieldString = [XXTExplorerEntry sortField2AttributeName:sortField];
        NSComparator comparator = ^NSComparisonResult(NSDictionary *_Nonnull obj1, NSDictionary *_Nonnull obj2)
        {
            if (sortOrder == XXTExplorerViewEntryListSortOrderAsc) {
                return [[obj1 valueForKey:sortFieldString] compare:[obj2 valueForKey:sortFieldString]];
            } else {
                return [[obj2 valueForKey:sortFieldString] compare:[obj1 valueForKey:sortFieldString]];
            }
        };
        
        [entryDirectoryAttributesList sortUsingComparator:comparator];
        [entryBundleAttributesList sortUsingComparator:comparator];
        [entryOtherAttributesList sortUsingComparator:comparator];

        NSMutableArray <XXTExplorerEntry *> *entryDetailList = [[NSMutableArray alloc] initWithCapacity:entrySubdirectoryPathList.count];
        
        [entryDetailList addObjectsFromArray:entryDirectoryAttributesList];
        [entryDetailList addObjectsFromArray:entryBundleAttributesList];
        [entryDetailList addObjectsFromArray:entryOtherAttributesList];
        
        entryDetailList;
    });
    [self.entryList removeAllObjects];
    [self.entryList addObjectsFromArray:newEntryList];
    [self reloadFooterView];
    
    if (error && *error) {
        return NO;
    }
    return YES;
}

- (void)loadEntryListData {
    NSError *entryLoadError = nil;
    [self loadEntryListDataWithError:&entryLoadError];
    if (entryLoadError) {
        toastError(self, entryLoadError);
    }
}

- (void)reloadFooterView {
    NSUInteger itemCount = self.entryList.count;
    if ([self.navigationController.viewControllers firstObject] == self &&
        [self.class.initialPath isEqualToString:self.entryPath] &&
        itemCount == 0)
    {
        [self.footerView setEmptyMode:YES];
    } else {
        [self.footerView setEmptyMode:NO];
        [self updateFooterView];
    }
}

- (void)updateFooterView {
    NSUInteger itemCount = self.entryList.count;
    NSString *itemCountString = nil;
    if (itemCount == 0) {
        itemCountString = NSLocalizedString(@"No item", nil);
    } else if (itemCount == 1) {
        itemCountString = NSLocalizedString(@"1 item", nil);
    } else {
        itemCountString = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), (unsigned long) itemCount];
    }
    NSString *usageString = nil;
    NSError *usageError = nil;
    NSDictionary *fileSystemAttributes = [self.class.explorerFileManager attributesOfFileSystemForPath:XXTERootPath() error:&usageError];
    if (!usageError) {
        NSNumber *deviceFreeSpace = fileSystemAttributes[NSFileSystemFreeSize];
        if (deviceFreeSpace != nil) {
            usageString = [NSByteCountFormatter stringFromByteCount:[deviceFreeSpace unsignedLongLongValue] countStyle:NSByteCountFormatterCountStyleFile];
        }
    }
    NSString *finalFooterString = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ free", nil), itemCountString, usageString];
    [self.footerView.footerLabel setText:finalFooterString];
}

- (void)reloadEntryListView {
    [self loadEntryListData];
    [self.tableView reloadData];
}

- (void)refreshControlTriggered:(UIRefreshControl *)refreshControl {
#ifndef APPSTORE
    if ([self.class isFetchingSelectedScript] == NO) {
        [self.class setFetchingSelectedScript:YES];
        [NSURLConnection POST:uAppDaemonCommandUrl(@"get_selected_script_file") JSON:@{}]
        .then(convertJsonString)
        .then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
                NSString *selectedScriptName = jsonDictionary[@"data"][@"filename"];
                if (selectedScriptName) {
                    NSString *selectedScriptPath = nil;
                    if ([selectedScriptName isAbsolutePath]) {
                        selectedScriptPath = selectedScriptName;
                    } else {
                        selectedScriptPath = [self.class.initialPath stringByAppendingPathComponent:selectedScriptName];
                    }
                    XXTEDefaultsSetObject(XXTExplorerViewEntrySelectedScriptPathKey, selectedScriptPath);
                }
            }
        })
        .catch(^(NSError *serverError) {
            toastDaemonError(self, serverError);
        })
        .finally(^() {
            if (refreshControl && [refreshControl isRefreshing]) {
                [self loadEntryListData];
                [self.tableView reloadData];
                [refreshControl endRefreshing];
            } else {
                UITableView *tableView = self.tableView;
                for (NSIndexPath *indexPath in [tableView indexPathsForVisibleRows]) {
                    [self reconfigureCellAtIndexPath:indexPath];
                }
            }
            [self.class setFetchingSelectedScript:NO];
        });
    }
    
#else
    
    if (refreshControl && [refreshControl isRefreshing]) {
        [self loadEntryListData];
        [self.tableView reloadData];
        [refreshControl endRefreshing];
    } else {
        UITableView *tableView = self.tableView;
        for (NSIndexPath *indexPath in [tableView indexPathsForVisibleRows])
        {
            [self reconfigureCellAtIndexPath:indexPath];
        }
    }
    [self.class setFetchingSelectedScript:NO];
    
#endif
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            return indexPath;
        } else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            return indexPath;
        }
    } else if (tableView == self.searchResultsController.tableView) {
        return indexPath;
    }
    return nil;
}  // delegate method

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}  // delegate method

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            if ([tableView isEditing]) {
                [self updateToolbarStatus];
            }
        }
    }
}  // delegate method

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            if ([tableView isEditing]) {
                [self updateToolbarStatus];
            } else {
                XXTExplorerEntry *entry = self.entryList[indexPath.row];
                NSString *entryPath = entry.entryPath;
                if (entry.isMaskedDirectory)
                {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    [self performDictionaryActionForEntry:entry];
                }
                else if (
                         entry.isMaskedRegular ||
                         entry.isBundle)
                {
                    if ([self.class.explorerFileManager isReadableFileAtPath:entryPath])
                    {
                        if ([self.class.explorerEntryService hasViewerForEntry:entry])
                        {
                            [tableView deselectRowAtIndexPath:indexPath animated:YES];
                            if (!XXTE_COLLAPSED)
                            {
                                
                            } // TODO: remain selected state when being viewed in collapsed detail view controller
                            [self performViewerActionForEntry:entry];
                        }
                        else
                        {
                            [tableView deselectRowAtIndexPath:indexPath animated:YES];
                            XXTExplorerEntryOpenWithViewController *openWithController = [[XXTExplorerEntryOpenWithViewController alloc] initWithEntry:entry];
                            openWithController.delegate = self;
                            XXTENavigationController *navController = [[XXTENavigationController alloc] initWithRootViewController:openWithController];
                            XXTE_START_IGNORE_PARTIAL
                            if (@available(iOS 8.0, *)) {
                                navController.modalPresentationStyle = UIModalPresentationPopover;
                                UIPopoverPresentationController *popoverController = navController.popoverPresentationController;
                                popoverController.sourceView = tableView;
                                popoverController.sourceRect = [tableView rectForRowAtIndexPath:indexPath];
                                popoverController.backgroundColor = XXTColorPlainBackground();
                            }
                            XXTE_END_IGNORE_PARTIAL
                            navController.presentationController.delegate = self;
                            [self.navigationController presentViewController:navController animated:YES completion:nil];
                        }
                    } else {
                        // TODO: not readable, unlock?
                        [tableView deselectRowAtIndexPath:indexPath animated:YES];
                        toastMessage(self, NSLocalizedString(@"Access denied.", nil));
                    }
                } else if (entry.isBrokenSymlink)
                { // broken symlink
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"The alias \"%@\" can't be opened because the original item can't be found.", nil), entry.localizedDisplayName]));
                }
                else
                { // not supported
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    toastMessage(self, NSLocalizedString(@"Only regular file, directory and symbolic link are supported.", nil));
                }
            }
        } else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            if ([tableView isEditing]) {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            } else {
                NSDictionary *entryDetail = self.homeEntryList[indexPath.row];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                [self performHomeActionForEntry:entryDetail];
            }
        }
    }
}  // delegate method

// Home Action

- (XXTExplorerViewController *)prepareForHomeActionForEntry:(NSDictionary *)entryDetail error:(NSError **)error {
    NSString *directoryRelativePath = entryDetail[@"path"];
    NSString *directoryPath = nil;
    if ([directoryRelativePath isAbsolutePath]) {
        directoryPath = directoryRelativePath;
    } else {
        directoryPath = [XXTERootPath() stringByAppendingPathComponent:directoryRelativePath];
    }
    NSError *accessError = nil;
    [self.class.explorerFileManager contentsOfDirectoryAtPath:directoryPath error:&accessError];
    if (accessError) {
        if (error) *error = accessError;
    } else {
        XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:directoryPath];
        return explorerViewController;
    }
    return nil;
}

- (void)performHomeActionForEntry:(NSDictionary *)entryDetail {
    NSError *prepareError = nil;
    UIViewController *controller = [self prepareForHomeActionForEntry:entryDetail error:&prepareError];
    if (controller) {
        [self.navigationController pushViewController:controller animated:YES];
    } else if (prepareError) {
        toastError(self, prepareError);
    }
}

// Item Action

- (XXTExplorerItemPreviewController *)prepareForItemPreviewActionForEntry:(XXTExplorerEntry *)entryDetail {
    XXTExplorerItemPreviewController *controller = [[XXTExplorerItemPreviewController alloc] initWithNibName:NSStringFromClass([XXTExplorerItemPreviewController class]) bundle:nil];
    controller.entryPath = entryDetail.entryPath;
    return controller;
}

// Directory Action

- (XXTExplorerViewController *)prepareForDictionaryActionForEntry:(XXTExplorerEntry *)entryDetail error:(NSError **)error {
    NSString *entryPath = entryDetail.entryPath;
    if (entryDetail.isMaskedDirectory)
    { // Directory or Symbolic Link Directory
        // We'd better try to access it before we enter it.
        NSError *accessError = nil;
        [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&accessError];
        if (accessError) {
            if (error) *error = accessError;
        } else {
            XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:entryPath];
            return explorerViewController;
        }
    }
    return nil;
}

- (void)performDictionaryActionForEntry:(XXTExplorerEntry *)entryDetail {
    NSError *prepareError = nil;
    UIViewController *controller = [self prepareForDictionaryActionForEntry:entryDetail error:&prepareError];
    if (controller) {
        [self.navigationController pushViewController:controller animated:YES];
    } else if (prepareError) {
        toastError(self, prepareError);
    }
}

// History Action

- (void)performHistoryActionForEntry:(XXTExplorerEntry *)entryDetail {
    NSString *entryPath = entryDetail.entryPath;
    if (entryDetail.isMaskedDirectory)
    {
        NSError *accessError = nil;
        [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&accessError];
        if (accessError) {
            toastError(self, accessError);
        } else {
            XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:entryPath];
            explorerViewController.historyMode = YES;
            explorerViewController.internalSortField = XXTExplorerViewEntryListSortFieldModificationDate;
            explorerViewController.internalSortOrder = XXTExplorerViewEntryListSortOrderDesc;
            [self.navigationController pushViewController:explorerViewController animated:YES];
        }
    }
}

// Viewer Action

- (void)performViewerActionForEntry:(XXTExplorerEntry *)entry {
    [self performViewerActionForEntry:entry animated:YES];
}

- (void)performViewerActionForEntry:(XXTExplorerEntry *)entry animated:(BOOL)animated {
    if (entry.isExecutable)
    { // if entry is executable, select it instead of viewer action
#ifndef APPSTORE
        [self performViewerExecutableActionForEntry:entry];
        return;
#endif
    }
    else if (entry.isConfigurable)
    { // if entry is configurable, configure it instead of viewer action
        [self performUnchangedButtonAction:XXTExplorerEntryButtonActionConfigure forEntry:entry];
        return;
    }
    // but, entry viewer
    UITableView *tableView = self.tableView;
    UIViewController <XXTEViewer> *viewer = [self.class.explorerEntryService viewerForEntry:entry];
    [self tableView:tableView showDetailController:viewer animated:animated];
}

- (void)performViewerExecutableActionForEntry:(XXTExplorerEntry *)entry
{
    NSString *entryPath = entry.entryPath;
    [self performViewerExecutableActionForEntryAtPath:entryPath];
}

- (void)performViewerExecutableActionForEntryAtPath:(NSString *)entryPath
{ // select executable entry
#ifndef APPSTORE
//    __block BOOL succeed = NO;
    UITableView *tableView = self.tableView;
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{@"filename": entryPath}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
            XXTEDefaultsSetObject(XXTExplorerViewEntrySelectedScriptPathKey, entryPath);
//            succeed = YES;
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select script: %@", nil), jsonDictionary[@"message"]];
        }
    })
    .catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    })
    .finally(^() {
//#ifdef DEBUG
//        XXTEDefaultsSetObject(XXTExplorerViewEntrySelectedScriptPathKey, entryPath);
//        succeed = YES;
//#endif
        blockInteractions(blockVC, NO);
        [self loadEntryListData];
        for (NSIndexPath *indexPath in [tableView indexPathsForVisibleRows])
        {
            // Selection animation
//            {
//                XXTExplorerEntry *entryDetail = self.entryList[indexPath.row];
//                BOOL isSelectedCell = [entryDetail.entryPath isEqualToString:entryPath];
//                if (isSelectedCell) {
//                    XXTExplorerViewCell *entryCell = [self.tableView cellForRowAtIndexPath:indexPath];
//                    [entryCell animateIndicatorForFlagType:XXTExplorerViewCellFlagTypeSelected];
//                }
//            }
            [self reconfigureCellAtIndexPath:indexPath];
        }
    });
#endif
}

// Accessory Action

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (![tableView isEditing]) {
            if (XXTExplorerViewSectionIndexList == indexPath.section) {
                XXTESwipeTableCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                [cell showSwipe:XXTESwipeDirectionLeftToRight animated:YES];
            }
        }
    }
}  // delegate method

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            return XXTExplorerViewCellHeight;
        } else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            return XXTExplorerViewHomeCellHeight;
        }
    } else if (tableView == self.searchResultsController.tableView) {
        return XXTExplorerViewCellHeight;
    }
    return 0;
}  // delegate method

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == section) {
            if (self.displayCurrentPath) {
                return 24.f;
            }
        } // Notice: assume that there will not be any headers for Home section
    } else if (tableView == self.searchResultsController.tableView) {
        return 24.f;
    }
    return 0;
}  // delegate method

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == section) {
            if (self.displayCurrentPath) {
                XXTExplorerHeaderView *entryHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
                if (!entryHeaderView)
                {
                    entryHeaderView = [[XXTExplorerHeaderView alloc] initWithReuseIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
                }
                [entryHeaderView.headerLabel setText:XXTTiledPath(self.entryPath)];
                entryHeaderView.userInteractionEnabled = YES;
                UITapGestureRecognizer *addressTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addressLabelTapped:)];
                addressTapGestureRecognizer.delegate = self;
                [entryHeaderView addGestureRecognizer:addressTapGestureRecognizer];
                return entryHeaderView;
            }
        } // Notice: assume that there will not be any headers for Home section
    } else if (tableView == self.searchResultsController.tableView) {
        if (section == 0) {
            XXTExplorerHeaderView *entryHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
            if (!entryHeaderView)
            {
                entryHeaderView = [[XXTExplorerHeaderView alloc] initWithReuseIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
            }
            [entryHeaderView.headerLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Search Results (%ld)", nil), self.searchResultsController.filteredEntryList.count]];
            return entryHeaderView;
        }
    }
    return nil;
}  // delegate method

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return XXTExplorerViewSectionIndexMax;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexHome == section) {
            return self.homeEntryList.count;
        } else if (XXTExplorerViewSectionIndexList == section) {
            return self.entryList.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            XXTExplorerEntry *entryDetail = self.entryList[indexPath.row];
            XXTExplorerViewCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewCellReuseIdentifier];
            if (!entryCell) {
                entryCell = [[XXTExplorerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewCellReuseIdentifier];
            }
            [self configureCell:entryCell withEntry:entryDetail];
            return entryCell;
        } else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            NSDictionary *entryDetail = self.homeEntryList[indexPath.row];
            XXTExplorerViewHomeCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewHomeCellReuseIdentifier];
            if (!entryCell) {
                entryCell = [[XXTExplorerViewHomeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewHomeCellReuseIdentifier];
            }
            [self configureHomeCell:entryCell withEntry:entryDetail];
            return entryCell;
        }
    }
    return [UITableViewCell new];
}

#pragma mark - UILongPressGestureRecognizer

- (void)entryCellDidLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (![self isEditing] && recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [recognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        if (!indexPath) return;
        if (indexPath.section == XXTExplorerViewSectionIndexHome) {
            XXTExplorerViewHomeCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell becomeFirstResponder];
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            UIMenuItem *hideItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Hide", nil) action:@selector(hideHomeItemTapped:)];
            [menuController setMenuItems:[NSArray arrayWithObjects:hideItem, nil]];
            [menuController setTargetRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView];
            [menuController setMenuVisible:YES animated:YES];
        } else {
            [self setEditing:YES animated:YES];
            if (self.tableView.delegate) {
                [self.tableView.delegate tableView:self.tableView willSelectRowAtIndexPath:indexPath];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:indexPath];
            }
        }
    }
}

#pragma mark - Cell Configuration

- (void)reconfigureCellAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) return;
    if (indexPath.section == XXTExplorerViewSectionIndexList) {
        if (indexPath.row < self.entryList.count) {
            XXTExplorerViewCell *entryCell = [self.tableView cellForRowAtIndexPath:indexPath];
            XXTExplorerEntry *entryDetail = self.entryList[indexPath.row];
            [self configureCell:entryCell withEntry:entryDetail];
        }
    }
    else if (indexPath.section == XXTExplorerViewSectionIndexHome) {
        if (indexPath.row < self.homeEntryList.count) {
            XXTExplorerViewHomeCell *entryCell = [self.tableView cellForRowAtIndexPath:indexPath];
            NSDictionary *entryDetail = self.homeEntryList[indexPath.row];
            [self configureHomeCell:entryCell withEntry:entryDetail];
        }
    }
}

- (void)configureCell:(XXTExplorerViewCell *)entryCell withEntry:(XXTExplorerEntry *)entry {
    entryCell.delegate = self;
    entryCell.entryTitleLabel.textColor = XXTColorPlainTitleText();
    entryCell.entrySubtitleLabel.textColor = XXTColorPlainSubtitleText();
    if (entry.isBrokenSymlink) {
        // broken symlink
        entryCell.entryTitleLabel.textColor = XXTColorDanger();
        entryCell.entrySubtitleLabel.textColor = XXTColorDanger();
        entryCell.flagType = XXTExplorerViewCellFlagTypeBroken;
    } else if (entry.isSymlink) {
        // symlink
        entryCell.entryTitleLabel.textColor = XXTColorForeground();
        entryCell.entrySubtitleLabel.textColor = XXTColorForeground();
        entryCell.flagType = XXTExplorerViewCellFlagTypeNone;
    } else {
        entryCell.entryTitleLabel.textColor = XXTColorPlainTitleText();
        entryCell.entrySubtitleLabel.textColor = XXTColorPlainSubtitleText();
        entryCell.flagType = XXTExplorerViewCellFlagTypeNone;
    }
    if (!entry.isMaskedDirectory &&
        [self.class.selectedScriptPath isEqualToString:entry.entryPath]) {
        // selected script itself
        entryCell.entryTitleLabel.textColor = XXTColorSuccess();
        entryCell.entrySubtitleLabel.textColor = XXTColorSuccess();
        entryCell.flagType = XXTExplorerViewCellFlagTypeSelected;
    } else if ((entry.isMaskedDirectory ||
                entry.isBundle) &&
               [[self.class selectedScriptPath] hasPrefix:entry.entryPath] &&
               [[[self.class selectedScriptPath] substringFromIndex:entry.entryPath.length] rangeOfString:@"/"].location != NSNotFound) {
        // selected script in directory / bundle
        entryCell.entryTitleLabel.textColor = XXTColorSuccess();
        entryCell.entrySubtitleLabel.textColor = XXTColorSuccess();
        entryCell.flagType = XXTExplorerViewCellFlagTypeSelectedInside;
    }
    NSString *fixedName = entry.localizedDisplayName;
    if (self.historyMode) {
        NSUInteger atLoc = [fixedName rangeOfString:@"@"].location + 1;
        if (atLoc != NSNotFound && atLoc < fixedName.length) {
            fixedName = [fixedName substringFromIndex:atLoc];
        }
    }
    entryCell.entryTitleLabel.text = fixedName;
    entryCell.entrySubtitleLabel.text = entry.localizedDescription;
    entryCell.entryIconImageView.image = entry.localizedDisplayIconImage;
    if (entryCell.accessoryType != UITableViewCellAccessoryNone)
    {
        entryCell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)configureHomeCell:(XXTExplorerViewHomeCell *)entryCell withEntry:(NSDictionary *)entryDetail {
    entryCell.entryIconImageView.image = [UIImage imageNamed:entryDetail[@"icon"]];
    entryCell.entryTitleLabel.text = entryDetail[@"title"];
    entryCell.entrySubtitleLabel.text = entryDetail[@"subtitle"];
    entryCell.entryTitleLabel.textColor = XXTColorPlainTitleText();
    entryCell.entrySubtitleLabel.textColor = XXTColorPlainSubtitleText();
}

#pragma mark - View Attachments

- (void)addressLabelTapped:(UITapGestureRecognizer *)recognizer {
    if (![self isEditing] && recognizer.state == UIGestureRecognizerStateEnded) {
        NSString *detailText = self.entryPath;
        if (detailText && detailText.length > 0) {
            UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 1.0);
            [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [[UIPasteboard generalPasteboard] setString:detailText];
                    fulfill(nil);
                });
            }].finally(^() {
                toastMessage(self, NSLocalizedString(@"Current path has been copied to the pasteboard.", nil));
                blockInteractions(blockVC, NO);
            });
        }
    }
}

- (void)hideHomeItemTapped:(id)sender {
    NSMutableArray <NSIndexPath *> *homeIndexes = [[NSMutableArray alloc] init];
    for (NSUInteger idx = 0; idx < self.homeEntryList.count; idx++) {
        [homeIndexes addObject:[NSIndexPath indexPathForRow:idx inSection:XXTExplorerViewSectionIndexHome]];
    }
    XXTEDefaultsSetBasic(XXTExplorerViewEntryHomeEnabledKey, NO);
    [self loadEntryListData];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[homeIndexes copy] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
    [self.tableView endUpdates];
#ifndef APPSTORE
    toastMessage(self, NSLocalizedString(@"\"Home Entries\" has been disabled, you can make it display again in \"More > User Defaults\".", nil));
#else
    toastMessage(self, NSLocalizedString(@"\"Home Entries\" has been disabled, you can make it display again in \"Settings > User Defaults\".", nil));
#endif
}

#pragma mark - Gesture Attachments

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (indexPath.section == XXTExplorerViewSectionIndexList) {
        XXTESwipeTableCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        return (cell.swipeState == XXTESwipeStateNone);
    }
    return (!self.isEditing);
}

#pragma mark - UIViewController (UIViewControllerEditing)

- (BOOL)isEditing {
    return [super isEditing];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    if (editing) {
        [self.toolbar updateStatus:XXTExplorerToolbarStatusEditing];
    } else {
        [self.toolbar updateStatus:XXTExplorerToolbarStatusDefault];
    }
    [self updateToolbarStatus];
    [self reloadFooterView];
}

#pragma mark - Preview

- (BOOL)isPreviewed {
    return self.previewDelegate != nil;
}

#pragma mark - Scroll to Rect

- (NSIndexPath *)indexPathForEntryAtPath:(NSString *)entryPath {
    for (NSUInteger idx = 0; idx < self.entryList.count; idx++) {
        XXTExplorerEntry *entryDetail = self.entryList[idx];
        if ([entryDetail.entryPath isEqualToString:entryPath]) {
            return [NSIndexPath indexPathForRow:idx inSection:XXTExplorerViewSectionIndexList];
        }
    }
    return nil;
}

#pragma mark - XXTExplorerFooterViewDelegate

- (void)footerView:(XXTExplorerFooterView *)view emptyButtonTapped:(UIButton *)sender {
    if (view == self.footerView) {
#ifndef APPSTORE
        NSDictionary *userInfo =
        @{XXTENotificationShortcutInterface: @"cloud",
          XXTENotificationShortcutUserData: @{  }};
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationShortcut object:nil userInfo:userInfo]];
#endif
    }
}

#pragma mark - UIViewControllerPreviewingDelegate

XXTE_START_IGNORE_PARTIAL
- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    UIViewController *presentController = nil;
    if ([viewControllerToCommit isKindOfClass:[self class]])
    {
        presentController = viewControllerToCommit;
    }
    else if ([viewControllerToCommit isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navController = (UINavigationController *)viewControllerToCommit;
        UIViewController *rootController = [navController.viewControllers firstObject];
        if ([rootController isKindOfClass:[self class]]) {
            XXTExplorerViewController *nextController = (XXTExplorerViewController *)rootController;
            XXTExplorerViewController *newNextController = [[XXTExplorerViewController alloc] initWithEntryPath:nextController.entryPath];
            presentController = newNextController;
        }
    }
    if ([presentController isKindOfClass:[UIViewController class]])
    {
        [self.navigationController pushViewController:presentController animated:NO];
    }
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    UITableView *tableView = self.tableView;
    if ([tableView isEditing]) {
        return nil;
    }
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:location];
    if (!indexPath) return nil;
    if (@available(iOS 9.0, *)) {
        previewingContext.sourceRect = [tableView rectForRowAtIndexPath:indexPath];
    }
    UITableViewCell *previewCell = [tableView cellForRowAtIndexPath:indexPath];
    NSError *prepareError = nil;
    if (XXTExplorerViewSectionIndexList == indexPath.section) {
        XXTExplorerEntry *entryDetail = self.entryList[indexPath.row];
        XXTExplorerViewController *controller =
        [self prepareForDictionaryActionForEntry:entryDetail error:&prepareError];
        if (controller)
        { // Directory Preview
            controller.previewDelegate = self;
            controller.previewActionDelegate = self;
            controller.previewActionSender = previewCell;
            XXTExplorerNavigationController *navController =
            [[XXTExplorerNavigationController alloc] initWithRootViewController:controller];
            return navController;
        }
        else
        { // Item Preview
            XXTExplorerItemPreviewController *itemController =
            [self prepareForItemPreviewActionForEntry:entryDetail];
            itemController.previewDelegate = self;
            itemController.previewActionDelegate = self;
            itemController.previewActionSender = previewCell;
            return itemController;
        }
    } else if (XXTExplorerViewSectionIndexHome == indexPath.section)
    { // Home Preview
        NSDictionary *entryDetail = self.homeEntryList[indexPath.row];
        XXTExplorerViewController *controller =
        [self prepareForHomeActionForEntry:entryDetail error:&prepareError];
        controller.previewDelegate = self;
        // controller.previewActionDelegate = self;
        // controller.previewActionSender = previewCell;
        // !!! You cannot perform any action in home preview !!!
        XXTExplorerNavigationController *navController =
        [[XXTExplorerNavigationController alloc] initWithRootViewController:controller];
        return navController;
    }
    return nil;
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - XXTExplorerItemPreviewActionDelegate

XXTE_START_IGNORE_PARTIAL
- (NSArray <UIPreviewAction *> *)itemPreviewController:(XXTExplorerItemPreviewController *)controller previewActionsForEntry:(XXTExplorerEntry *)entry
{
    return [self previewActionsForEntry:entry forEntryCell:controller.previewActionSender];
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (NSArray <id <UIPreviewActionItem>> *)previewActionItems {
    if ([_previewActionDelegate respondsToSelector:@selector(itemPreviewController:previewActionsForEntry:)]) {
        return [_previewActionDelegate directoryPreviewController:self previewActionsForEntry:self.entry];
    }
    return @[];
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - XXTExplorerDirectoryPreviewActionDelegate

XXTE_START_IGNORE_PARTIAL
- (NSArray <UIPreviewAction *> *)directoryPreviewController:(XXTExplorerViewController *)controller previewActionsForEntry:(XXTExplorerEntry *)entry
{
    return [self previewActionsForEntry:entry forEntryCell:controller.previewActionSender];
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - UIView Getters

- (UITableView *)tableView {
    if (!_tableView) {
        CGRect tableViewFrame = CGRectZero;
        tableViewFrame = CGRectMake(0.0, 44.0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 44.0);
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.allowsSelection = YES;
        tableView.allowsMultipleSelection = NO;
        tableView.allowsSelectionDuringEditing = YES;
        tableView.allowsMultipleSelectionDuringEditing = YES;
        tableView.backgroundColor = XXTColorPlainBackground();
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        if ([self allowDragAndDrop]) {
            if (@available(iOS 11.0, *)) {
                tableView.dragDelegate = self;
                tableView.dropDelegate = self;
            }
        }
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewCellReuseIdentifier];
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewHomeCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewHomeCellReuseIdentifier];
        UILongPressGestureRecognizer *cellLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(entryCellDidLongPress:)];
        cellLongPressGesture.delegate = self;
        [tableView addGestureRecognizer:cellLongPressGesture];
        _tableView = tableView;
    }
    return _tableView;
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
        _refreshControl = refreshControl;
    }
    return _refreshControl;
}

- (XXTExplorerFooterView *)footerView {
    if (!_footerView) {
        XXTExplorerFooterView *entryFooterView = [[XXTExplorerFooterView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 48.f)];
        entryFooterView.delegate = self;
        _footerView = entryFooterView;
    }
    return _footerView;
}

#pragma mark - UIAdaptivePresentationControllerDelegate (13.0+)

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController {
    [self reloadEntryListView];  // performance?
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    // better here?
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self updateSearchResultsForSearchController:self.searchController];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.searchBar.selectedScopeButtonIndex == 0) {
        // Current Directory
        NSArray <XXTExplorerEntry *> *searchEntries = self.entryList;
        NSString *searchString = searchController.searchBar.text;
        NSMutableArray <XXTExplorerEntry *> *filteredEntries = [NSMutableArray arrayWithCapacity:searchEntries.count];
        for (XXTExplorerEntry *entry in searchEntries) {
            if ([entry.entryName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [filteredEntries addObject:entry];
            }
        }
        self.searchResultsController.recursively = NO;
        self.searchResultsController.filteredEntryList = filteredEntries;
        [self.searchResultsController.tableView reloadData];
    } else if (searchController.searchBar.selectedScopeButtonIndex == 1) {
        // Recursively, Async
        
    }
}

#pragma mark - UISearchControllerDelegate

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
