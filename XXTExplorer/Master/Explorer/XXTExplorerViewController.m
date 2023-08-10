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
#import <SafariServices/SafariServices.h>

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

@interface XXTExplorerViewController ()
<UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate,
UIViewControllerPreviewingDelegate, XXTExplorerFooterViewDelegate,
XXTExplorerItemPreviewDelegate, XXTExplorerItemPreviewActionDelegate,
XXTExplorerDirectoryPreviewDelegate, XXTExplorerDirectoryPreviewActionDelegate
>

@property (nonatomic, strong) id<UIViewControllerPreviewing> previewingContext;

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong) UIDropInteraction *dropInteraction;
XXTE_END_IGNORE_PARTIAL

@property (nonatomic, strong) NSArray <NSString *> *entryPathsToLazySelect;

@end

@implementation XXTExplorerViewController {
    BOOL _firstTimeLoaded;
}

@synthesize tableView = _tableView;
@synthesize refreshControl = _refreshControl;
@synthesize sectionHeaderView = _sectionHeaderView;
@synthesize footerView = _footerView;

#pragma mark - Initializers

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
    self.definesPresentationContext = YES;
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

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerForceTouchCapability];
    
    if (self.title.length == 0) {
        NSString *title = nil;
        if (!title) {
            if (self == [self.navigationController.viewControllers firstObject]) {
                if (!self.isPreviewed) {
                    title = NSLocalizedString(@"My Scripts", nil);
                }
            }
        }
        if (!title) {
            NSString *entryPath = self.entryPath;
            if (entryPath) {
                NSString *entryName = [entryPath lastPathComponent];
                title = entryName;
            }
        }
        self.title = title;
    }
    
    {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
        
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
    
    {
        [self configureToolbarAndCover];
        UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
        [self.toolbar addInteraction:dropInteraction];
        _dropInteraction = dropInteraction;
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
    if (_firstTimeLoaded) {
        [self reloadEntryListView];
    } else if (!self.isPreviewed) {
        [self refreshControlTriggered:nil];
    }
    [self updateToolbarStatus];
    [self updateToolbarButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_firstTimeLoaded && !self.isPreviewed) {
        _firstTimeLoaded = YES;
    }
    if (!self.isPreviewed) {
        if ([self.navigationController.viewControllers firstObject] != self)
        {
            if (self.entryPathsToLazySelect == nil)
            {
                [self displaySwipeTutorialIfNecessary];
            }
        }
        [self lazySelectCellAnimatedIfNecessary];
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
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view.safeAreaLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
          [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
          ];
        [self.view addConstraints:constraints];
    } else {
        self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
        XXTE_START_IGNORE_PARTIAL
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
        [self.view addConstraints:constraints];
        XXTE_END_IGNORE_PARTIAL
    }
}

XXTE_START_IGNORE_PARTIAL
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self registerForceTouchCapability];
}
XXTE_END_IGNORE_PARTIAL

- (void)registerForceTouchCapability {
    if (self.allowsPreviewing) {
        if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
            if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                // retain the context to avoid registering more than once
                if (!self.previewingContext)
                {
                    XXTE_START_IGNORE_PARTIAL
                    self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
                    XXTE_END_IGNORE_PARTIAL
                }
            } else {
                XXTE_START_IGNORE_PARTIAL
                [self unregisterForPreviewingWithContext:self.previewingContext];
                XXTE_END_IGNORE_PARTIAL
                self.previewingContext = nil;
            }
        }
    }
}

- (void)restoreTheme {
    UIColor *barTintColor = XXTColorBarTint();
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    UINavigationBarAppearance *navigationBarAppearance = [[UINavigationBarAppearance alloc] init];
    [navigationBarAppearance configureWithOpaqueBackground];
    [navigationBarAppearance setBackgroundColor:barTintColor];
    [navigationBarAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName: XXTColorBarText(), NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    [navigationBar setStandardAppearance:navigationBarAppearance];
    [navigationBar setScrollEdgeAppearance:navigationBarAppearance];
    [navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: XXTColorBarText(), NSFontAttributeName: [UIFont boldSystemFontOfSize:18.f]}];
    navigationBar.tintColor = XXTColorTint();
    navigationBar.barTintColor = barTintColor;
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

- (BOOL)isPreviewed {
    return self.previewDelegate != nil;
}

- (XXTExplorerViewEntryListSortField)explorerSortField {
    return XXTEDefaultsEnum(XXTExplorerViewEntryListSortFieldKey, XXTExplorerViewEntryListSortFieldModificationDate);
}

- (XXTExplorerViewEntryListSortOrder)explorerSortOrder {
    return XXTEDefaultsEnum(XXTExplorerViewEntryListSortOrderKey, XXTExplorerViewEntryListSortOrderDesc);
}

- (void)setExplorerSortField:(XXTExplorerViewEntryListSortField)explorerSortField {
    XXTEDefaultsSetBasic(XXTExplorerViewEntryListSortFieldKey, explorerSortField);
}

- (void)setExplorerSortOrder:(XXTExplorerViewEntryListSortOrder)explorerSortOrder {
    XXTEDefaultsSetBasic(XXTExplorerViewEntryListSortOrderKey, explorerSortOrder);
}

#pragma mark - NSFileManager

- (BOOL)loadEntryListDataWithError:(NSError **)error {
    
    {
        BOOL homeEnabled = XXTEDefaultsBool(XXTExplorerViewEntryHomeEnabledKey, YES);
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
        NSComparator comparator = nil;
        if (sortField == XXTExplorerViewEntryListSortFieldDisplayName) {
            comparator = ^NSComparisonResult(NSDictionary *_Nonnull obj1, NSDictionary *_Nonnull obj2)
            {
                if (sortOrder == XXTExplorerViewEntryListSortOrderAsc) {
                    return [(NSString *)[obj1 valueForKey:sortFieldString] localizedStandardCompare:(NSString *)[obj2 valueForKey:sortFieldString]];
                } else {
                    return [(NSString *)[obj2 valueForKey:sortFieldString] localizedStandardCompare:(NSString *)[obj1 valueForKey:sortFieldString]];
                }
            };
        } else {
            comparator = ^NSComparisonResult(NSDictionary *_Nonnull obj1, NSDictionary *_Nonnull obj2)
            {
                if (sortOrder == XXTExplorerViewEntryListSortOrderAsc) {
                    return [[obj1 valueForKey:sortFieldString] compare:[obj2 valueForKey:sortFieldString]];
                } else {
                    return [[obj2 valueForKey:sortFieldString] compare:[obj1 valueForKey:sortFieldString]];
                }
            };
        }
        
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
}

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
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
        XXTE_END_IGNORE_PARTIAL
        if ([self allowDragAndDrop]) {
            tableView.dragDelegate = self;
            tableView.dropDelegate = self;
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

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            return indexPath;
        } else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            return indexPath;
        }
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
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                XXTExplorerEntry *entry = self.entryList[indexPath.row];
                [self performActionForEntry:entry sourceTableView:tableView sourceIndexPath:indexPath];
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

- (void)performActionForEntry:(XXTExplorerEntry *)entry sourceTableView:(UITableView *)tableView sourceIndexPath:(NSIndexPath *)indexPath
{
    NSString *entryPath = entry.entryPath;
    if (entry.isMaskedDirectory)
    {
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
                [self performViewerActionForEntry:entry];
            }
            else
            {
                XXTExplorerEntryOpenWithViewController *openWithController = [[XXTExplorerEntryOpenWithViewController alloc] initWithEntry:entry];
                openWithController.delegate = self;
                XXTENavigationController *navController = [[XXTENavigationController alloc] initWithRootViewController:openWithController];
                XXTE_START_IGNORE_PARTIAL
                navController.modalPresentationStyle = UIModalPresentationPopover;
                UIPopoverPresentationController *popoverController = navController.popoverPresentationController;
                popoverController.sourceView = tableView;
                popoverController.sourceRect = [tableView rectForRowAtIndexPath:indexPath];
                popoverController.backgroundColor = XXTColorPlainBackground();
                XXTE_END_IGNORE_PARTIAL
                navController.presentationController.delegate = self;
                [self.navigationController presentViewController:navController animated:YES completion:nil];
            }
        } else {
            toastMessage(self, NSLocalizedString(@"Access denied.", nil));
        }
    } else if (entry.isBrokenSymlink)
    { // broken symlink
        toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"The alias \"%@\" can't be opened because the original item can't be found.", nil), entry.localizedDisplayName]));
    }
    else
    { // not supported
        toastMessage(self, NSLocalizedString(@"Only regular file, directory and symbolic link are supported.", nil));
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
            explorerViewController.displayCurrentPath = self.displayCurrentPath;
            explorerViewController.internalSortField = self.internalSortField;
            explorerViewController.internalSortOrder = self.internalSortOrder;
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
            explorerViewController.displayCurrentPath = NO;
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
        [self performViewerExecutableActionForEntry:entry];
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
{
    UITableView *tableView = self.tableView;
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{ @"filename": entryPath }]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
            XXTEDefaultsSetObject(XXTExplorerViewEntrySelectedScriptPathKey, entryPath);
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select script: %@", nil), jsonDictionary[@"message"]];
        }
    })
    .catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
        [self loadEntryListData];
        for (NSIndexPath *indexPath in [tableView indexPathsForVisibleRows])
        {
            [self reconfigureCellAtIndexPath:indexPath];
        }
    });
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
    }
    return 0;
}  // delegate method

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == section) {
            if (self.displayCurrentPath) {
                XXTExplorerHeaderView *entryHeaderView = self.sectionHeaderView;
                if (!entryHeaderView) {
                    entryHeaderView = ({
                        XXTExplorerHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
                        if (!headerView)
                        {
                            headerView = [[XXTExplorerHeaderView alloc] initWithReuseIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
                        }
                        headerView.userInteractionEnabled = YES;
                        [headerView.headerLabel setText:XXTTiledPath(self.entryPath)];
                        UITapGestureRecognizer *addressTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addressLabelTapped:)];
                        addressTapGestureRecognizer.delegate = self;
                        [headerView addGestureRecognizer:addressTapGestureRecognizer];
                        headerView;
                    });
                    _sectionHeaderView = entryHeaderView;
                }
                return entryHeaderView;
            }
        } // Notice: assume that there will not be any headers for Home section
    }
    return nil;
}  // delegate method, lazy loading

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
            entryCell.delegate = self;
            [self configureCell:entryCell fromTableView:tableView withEntry:entryDetail];
            return entryCell;
        } else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            NSDictionary *entryDetail = self.homeEntryList[indexPath.row];
            XXTExplorerViewHomeCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewHomeCellReuseIdentifier];
            if (!entryCell) {
                entryCell = [[XXTExplorerViewHomeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewHomeCellReuseIdentifier];
            }
            [self configureHomeCell:entryCell fromTableView:tableView withEntry:entryDetail];
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
            XXTE_START_IGNORE_PARTIAL
            [menuController setTargetRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView];
            [menuController setMenuVisible:YES animated:YES];
            XXTE_END_IGNORE_PARTIAL
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
            entryCell.delegate = self;
            [self configureCell:entryCell fromTableView:self.tableView withEntry:entryDetail];
        }
    }
    else if (indexPath.section == XXTExplorerViewSectionIndexHome) {
        if (indexPath.row < self.homeEntryList.count) {
            XXTExplorerViewHomeCell *entryCell = [self.tableView cellForRowAtIndexPath:indexPath];
            NSDictionary *entryDetail = self.homeEntryList[indexPath.row];
            [self configureHomeCell:entryCell fromTableView:self.tableView withEntry:entryDetail];
        }
    }
}

- (void)configureCell:(XXTExplorerViewCell *)entryCell fromTableView:(UITableView *)tableView withEntry:(XXTExplorerEntry *)entry {
    UIColor *titleColor = XXTColorPlainTitleText();
    UIColor *subtitleColor = XXTColorPlainSubtitleText();
    XXTExplorerViewCellFlagType flagType = XXTExplorerViewCellFlagTypeNone;
    
    if (entry.isBrokenSymlink) {
        titleColor = XXTColorDanger();
        subtitleColor = XXTColorDanger();
        flagType = XXTExplorerViewCellFlagTypeBroken;
    } else if (entry.isSymlink) {
        titleColor = XXTColorForeground();
        subtitleColor = XXTColorForeground();
        flagType = XXTExplorerViewCellFlagTypeNone;
    } else {
        titleColor = XXTColorPlainTitleText();
        subtitleColor = XXTColorPlainSubtitleText();
        flagType = XXTExplorerViewCellFlagTypeNone;
    }
    if (!entry.isMaskedDirectory &&
        [[self.class selectedScriptPath] isEqualToString:entry.entryPath]) {
        // selected script itself
        titleColor = XXTColorSuccess();
        subtitleColor = XXTColorSuccess();
        flagType = XXTExplorerViewCellFlagTypeSelected;
    } else if ((entry.isMaskedDirectory ||
                entry.isBundle) &&
               [[self.class selectedScriptPath] hasPrefix:entry.entryPath] &&
               [[[self.class selectedScriptPath] substringFromIndex:entry.entryPath.length] rangeOfString:@"/"].location != NSNotFound) {
        // selected script in directory / bundle
        titleColor = XXTColorSuccess();
        subtitleColor = XXTColorSuccess();
        flagType = XXTExplorerViewCellFlagTypeSelectedInside;
    }
    
    NSString *fixedName = entry.localizedDisplayName;
    NSString *fixedDescription = nil;
    if (tableView == self.tableView) {
        fixedDescription = entry.localizedDescription;
        entryCell.entrySubtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    
    UIImage *fixedImage = entry.localizedDisplayIconImage;
    entryCell.flagType = flagType;
    entryCell.entryIconImageView.image = fixedImage;
    if (tableView == self.tableView) {
        entryCell.entryTitleLabel.textColor = titleColor;
        entryCell.entryTitleLabel.text = fixedName;
        entryCell.entrySubtitleLabel.textColor = subtitleColor;
        entryCell.entrySubtitleLabel.text = fixedDescription;
    }
    
    if (tableView == self.tableView) {
        entryCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        entryCell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
}

- (void)configureHomeCell:(XXTExplorerViewHomeCell *)entryCell fromTableView:(UITableView *)tableView withEntry:(NSDictionary *)entryDetail {
    entryCell.entryIconImageView.image = [UIImage imageNamed:entryDetail[@"icon"]];
    entryCell.entryTitleLabel.text = entryDetail[@"title"];
    entryCell.entrySubtitleLabel.text = entryDetail[@"subtitle"];
    entryCell.entryTitleLabel.textColor = XXTColorPlainTitleText();
    entryCell.entrySubtitleLabel.textColor = XXTColorPlainSubtitleText();
}

#pragma mark - Select Moved Cell

- (void)scrollToCellEntryAtPath:(NSString *)entryPath shouldSelect:(BOOL)select animated:(BOOL)animated {
    if (!entryPath) {
        return;
    }
    if (![self isViewLoaded]) {
        return;
    }
    UITableView *tableView = self.tableView;
    NSIndexPath *indexPath = [self indexPathForEntryAtPath:entryPath];
    if (indexPath != nil) {
        if (select) {
//            [self setEditing:YES animated:YES];
            [tableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:UITableViewScrollPositionMiddle];
        } else {
            [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:animated];
        }
    }
    if (select) {
        [self updateToolbarStatus];
    }
}

- (void)batchSelectCellEntriesAtPaths:(NSArray <NSString *> *)entryPaths animated:(BOOL)animated {
    if (!entryPaths) {
        return;
    }
    if (![self isViewLoaded]) {
        return;
    }
//    BOOL hasSetEditing = NO;
    BOOL hasSelected = NO;
    for (NSString *importedPath in entryPaths) {
        NSIndexPath *importedIndexPath = [self indexPathForEntryAtPath:importedPath];
        if (importedIndexPath) {
//            if (!hasSetEditing) {
//                [self setEditing:YES animated:animated];
//                hasSetEditing = YES;
//            }
            [self.tableView selectRowAtIndexPath:importedIndexPath animated:animated scrollPosition:UITableViewScrollPositionNone];
            hasSelected = YES;
        }
    }
    if (hasSelected) {
        [self updateToolbarStatus];
    }
}

- (void)scrollToCellEntryAtPath:(NSString *)entryPath animated:(BOOL)animated {
    if (!entryPath) {
        return;
    }
    [self scrollToCellEntryAtPath:entryPath shouldSelect:NO animated:animated];
}

- (void)selectCellEntryAtPath:(NSString *)entryPath animated:(BOOL)animated {
    if (!entryPath) {
        return;
    }
    if ([self isViewLoaded]) {
        [self scrollToCellEntryAtPath:entryPath shouldSelect:YES animated:animated];
    } else {
        [self setEntryPathsToLazySelect:@[ entryPath ]];
    }
}

- (void)selectCellEntriesAtPaths:(NSArray <NSString *> *)entryPaths animated:(BOOL)animated {
    if (!entryPaths) {
        return;
    }
    if ([self isViewLoaded]) {
        [self batchSelectCellEntriesAtPaths:entryPaths animated:animated];
    } else {
        [self setEntryPathsToLazySelect:entryPaths];
    }
}

- (void)lazySelectCellAnimatedIfNecessary {
    if (self.entryPathsToLazySelect) {
        if (self.entryPathsToLazySelect.count == 1) {
            [self selectCellEntryAtPath:[self.entryPathsToLazySelect firstObject] animated:YES];
        } else {
            [self selectCellEntriesAtPaths:self.entryPathsToLazySelect animated:YES];
        }
        self.entryPathsToLazySelect = nil;
    }
}

- (void)displaySwipeTutorialIfNecessary {
    BOOL tutorialDisplayed = XXTEDefaultsBool(XXTExplorerSwipeTutorialKey, NO);
    if (!tutorialDisplayed) {
        XXTExplorerViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:XXTExplorerViewSectionIndexList]];
        if (cell) {
            UIViewController *blockVC = blockInteractionsWithToast(self, YES, NO);
            toastMessage(self, NSLocalizedString(@"Swipe: View Options", nil));
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                blockInteractions(blockVC, NO);
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [cell showSwipe:XXTESwipeDirectionLeftToRight animated:YES completion:^(BOOL finished) {
                    if (finished) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [cell hideSwipeAnimated:YES completion:^(BOOL finished) {
                                if (finished) {
                                    XXTEDefaultsSetBasic(XXTExplorerSwipeTutorialKey, YES);
                                }
                            }];
                        });
                    }
                }];
            });
        }
    }
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
    if (!self.homeEntryList.count) {
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[homeIndexes copy] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadData];
        [self.tableView endUpdates];
        toastMessage(self, NSLocalizedString(@"\"Home Entries\" has been disabled, you can make it display again in \"More > User Defaults\".", nil));
    }
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
    SFSafariViewController *sfCtrl = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:uAppDefine(@"XXTOUCH_MARKET_URL")]];
    sfCtrl.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.navigationController presentViewController:sfCtrl animated:YES completion:nil];
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
    previewingContext.sourceRect = [tableView rectForRowAtIndexPath:indexPath];
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

#pragma mark - UIAdaptivePresentationControllerDelegate (13.0+)

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController {
    [self reloadEntryListView];  // performance?
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    // better here?
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
