//
//  XXTExplorerViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerViewController.h"
#import "XXTExplorerHeaderView.h"
#import "XXTExplorerFooterView.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerViewHomeCell.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerToolbar.h"
#import "XXTENotificationCenterDefines.h"
#import "UIView+XXTEToast.h"
#import <LGAlertView/LGAlertView.h>

typedef enum : NSUInteger {
    XXTExplorerViewSectionIndexHome = 0,
    XXTExplorerViewSectionIndexList,
    XXTExplorerViewSectionIndexMax
} XXTExplorerViewSectionIndex;

#define XXTEDefaultsBool(key) ([[self.class.explorerDefaults objectForKey:key] boolValue])
#define XXTEDefaultsEnum(key) ([[self.class.explorerDefaults objectForKey:key] unsignedIntegerValue])
#define XXTEDefaultsObject(key) ([self.class.explorerDefaults objectForKey:key])
#define XXTEDefaultsSetBasic(key, value) ([self.class.explorerDefaults setObject:@(value) forKey:key])
#define XXTEDefaultsSetObject(key, obj) ([self.class.explorerDefaults setObject:obj forKey:key])
#define XXTEBuiltInDefaultsBool(key) ([[self.class.explorerBuiltInDefaults objectForKey:key] boolValue])
#define XXTEBuiltInDefaultsEnum(key) ([[self.class.explorerBuiltInDefaults objectForKey:key] unsignedIntegerValue])
#define XXTEBuiltInDefaultsObject(key) ([self.class.explorerBuiltInDefaults objectForKey:key])

@interface XXTExplorerViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, XXTExplorerToolbarDelegate, XXTESwipeTableCellDelegate, LGAlertViewDelegate>

@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *entryList;
@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *homeEntryList;

@property (nonatomic, strong, readonly) XXTExplorerToolbar *toolbar;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) XXTExplorerFooterView *footerView;

@end

@implementation XXTExplorerViewController

+ (NSMutableArray <NSDictionary *> *)explorerPasteboard {
    static NSMutableArray *explorerPasteboard = nil;
    if (!explorerPasteboard) {
        explorerPasteboard = ({
            [[NSMutableArray alloc] init];
        });
    }
    return explorerPasteboard;
}

+ (NSString *)rootPath {
    static NSString *rootPath = nil;
    if (!rootPath) {
        rootPath = ({
            [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        });
    }
    return rootPath;
}

+ (NSFileManager *)explorerFileManager {
    static NSFileManager *explorerFileManager = nil;
    if (!explorerFileManager) {
        explorerFileManager = ({
            [[NSFileManager alloc] init];
        });
    }
    return explorerFileManager;
}

+ (NSDateFormatter *)explorerDateFormatter {
    static NSDateFormatter *explorerDateFormatter = nil;
    if (!explorerDateFormatter) {
        explorerDateFormatter = ({
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            dateFormatter;
        });
    }
    return explorerDateFormatter;
}

+ (NSUserDefaults *)explorerDefaults {
    static NSUserDefaults *explorerDefaults = nil;
    if (!explorerDefaults) {
        explorerDefaults = ({
            [NSUserDefaults standardUserDefaults];
        });
    }
    return explorerDefaults;
}

+ (NSDictionary *)explorerBuiltInDefaults {
    static NSDictionary *explorerBuiltInDefaults = nil;
    if (!explorerBuiltInDefaults) {
        explorerBuiltInDefaults = ({
            NSString *builtInDefaultsPath = [[NSBundle mainBundle] pathForResource:@"XXTExplorerBuiltInDefaults" ofType:@"plist"];
            [[NSDictionary alloc] initWithContentsOfFile:builtInDefaultsPath];
        });
    }
    return explorerBuiltInDefaults;
}

#pragma mark - Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         
     }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - UIViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupWithPath:nil];
    }
    return self;
}

- (instancetype)initWithEntryPath:(NSString *)path {
    if (self = [super init]) {
        [self setupWithPath:path];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    {
        NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"XXTExplorerDefaults" ofType:@"plist"];
        NSDictionary *defaults = [[NSDictionary alloc] initWithContentsOfFile:defaultsPath];
        for (NSString *defaultKey in defaults) {
            if (![self.class.explorerDefaults objectForKey:defaultKey])
            {
                [self.class.explorerDefaults setObject:defaults[defaultKey] forKey:defaultKey];
            }
        }
    }
    {
        if (!path) {
            NSString *initialRelativePath = XXTEBuiltInDefaultsObject(XXTExplorerViewInitialPath);
            NSString *initialPath = [[[self class] rootPath] stringByAppendingPathComponent:initialRelativePath];
            if (![self.class.explorerFileManager fileExistsAtPath:initialPath]) {
                assert(mkdir([initialPath UTF8String], 0755) == 0);
            }
            path = initialPath;
        }
        _entryPath = path;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self == self.navigationController.viewControllers[0]) {
        self.title = NSLocalizedString(@"My Scripts", nil);
    } else {
        self.title = [self.entryPath lastPathComponent];
    }
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 44.f, self.view.bounds.size.width, self.view.bounds.size.height - 44.f) style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.allowsSelection = YES;
        tableView.allowsMultipleSelection = NO;
        tableView.allowsSelectionDuringEditing = YES;
        tableView.allowsMultipleSelectionDuringEditing = YES;
        XXTE_START_IGNORE_PARTIAL
        if (XXTE_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewCellReuseIdentifier];
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewHomeCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewHomeCellReuseIdentifier];
        tableView;
    });
    
    [self.view addSubview:self.tableView];
    
    _toolbar = ({
        XXTExplorerToolbar *toolbar = [[XXTExplorerToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        toolbar.tapDelegate = self;
        toolbar;
    });
    [self.view addSubview:self.toolbar];
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    _refreshControl = ({
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshEntryListView:) forControlEvents:UIControlEventValueChanged];
        [tableViewController setRefreshControl:refreshControl];
        refreshControl;
    });
    [self.tableView.backgroundView insertSubview:self.refreshControl atIndex:0];
    
    _footerView = ({
        XXTExplorerFooterView *entryFooterView = [[XXTExplorerFooterView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 48.f)];
        entryFooterView;
    });
    [self.tableView setTableFooterView:self.footerView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
    [self updateToolbarButton:self.toolbar];
    [self updateToolbarStatus:self.toolbar];
    [self loadEntryListData];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([self isEditing]) {
        [self setEditing:NO animated:YES];
    }
}

#pragma mark - UINotification

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeInboxMoved]) {
        [self loadEntryListData];
        [self.tableView reloadData];
    }
}

#pragma mark - XXTExplorerToolbar

- (void)updateToolbarButton:(XXTExplorerToolbar *)toolbar {
    if (XXTEDefaultsEnum(XXTExplorerViewEntryListSortOrderKey) == XXTExplorerViewEntryListSortOrderAsc)
    {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort status:XXTExplorerToolbarButtonStatusNormal enabled:YES];
    }
    else
    {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort status:XXTExplorerToolbarButtonStatusSelected enabled:YES];
    }
}

- (void)updateToolbarStatus:(XXTExplorerToolbar *)toolbar {
    if ([[self class] explorerPasteboard].count > 0) {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:YES];
    }
    else
    {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:NO];
    }
    if ([self isEditing])
    {
        if (([self.tableView indexPathsForSelectedRows].count) > 0)
        {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeShare enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeCompress enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:YES];
        }
        else
        {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeShare enabled:NO];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeCompress enabled:NO];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash enabled:NO];
        }
    }
    else
    {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeScan enabled:YES];
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeAddItem enabled:YES];
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort enabled:YES];
    }
}

#pragma mark - NSFileManager

- (void)loadEntryListDataWithError:(NSError **)error
{
    {
        if (XXTEDefaultsBool(XXTExplorerViewSectionHomeEnabledKey) &&
            self == self.navigationController.viewControllers[0]) {
            _homeEntryList = XXTEBuiltInDefaultsObject(XXTExplorerViewSectionHomeSeriesKey);
        }
    }
    
    _entryList = ({
        NSError *localError = nil;
        NSArray <NSString *> *entrySubdirectoryPathList = [self.class.explorerFileManager contentsOfDirectoryAtPath:self.entryPath error:&localError];
        if (localError && error) *error = localError;
        NSMutableArray <NSDictionary *> *entryDirectoryAttributesList = [[NSMutableArray alloc] init];
        NSMutableArray <NSDictionary *> *entryOtherAttributesList = [[NSMutableArray alloc] init];
        for (NSString *entrySubdirectoryName in entrySubdirectoryPathList)
        {
            NSString *entrySubdirectoryPath = [self.entryPath stringByAppendingPathComponent:entrySubdirectoryName];
            NSDictionary *entryAttributes = [[XXTExplorerEntryParser sharedParser] entryOfPath:entrySubdirectoryPath withError:&localError];
            if (localError && error)
            {
                *error = localError;
                break;
            }
            // TODO: Parse each entry using XXTExplorerEntryExtensions
            if ([entryAttributes[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
            {
                [entryDirectoryAttributesList addObject:entryAttributes];
            }
            else
            {
                [entryOtherAttributesList addObject:entryAttributes];
            }
        }
        NSString *sortField = XXTEDefaultsObject(XXTExplorerViewEntryListSortFieldKey);
        NSUInteger sortOrder = XXTEDefaultsEnum(XXTExplorerViewEntryListSortOrderKey);
        NSComparator comparator = ^NSComparisonResult(NSDictionary * _Nonnull obj1, NSDictionary * _Nonnull obj2)
        {
            return (sortOrder == XXTExplorerViewEntryListSortOrderAsc) ? [obj1[sortField] compare:obj2[sortField]] : [obj2[sortField] compare:obj1[sortField]];
        };
        [entryDirectoryAttributesList sortUsingComparator:comparator];
        [entryOtherAttributesList sortUsingComparator:comparator];
        
        NSMutableArray <NSDictionary *> *entryAttributesList = [[NSMutableArray alloc] initWithCapacity:entrySubdirectoryPathList.count];
        [entryAttributesList addObjectsFromArray:entryDirectoryAttributesList];
        [entryAttributesList addObjectsFromArray:entryOtherAttributesList];
        entryAttributesList;
    });
    if (error && *error) _entryList = @[]; // clean entry list if error exists
    
    NSUInteger itemCount = self.entryList.count;
    NSString *itemCountString = nil;
    if (itemCount == 0) {
        itemCountString = NSLocalizedString(@"No item", nil);
    } else if (itemCount == 1) {
        itemCountString = NSLocalizedString(@"1 item", nil);
    } else  {
        itemCountString = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), (unsigned long)itemCount];
    }
    NSString *usageString = nil;
    NSError *usageError = nil;
    NSDictionary *fileSystemAttributes = [self.class.explorerFileManager attributesOfFileSystemForPath:self.entryPath error:&usageError];
    if (!usageError) {
        NSNumber *deviceFreeSpace = fileSystemAttributes[NSFileSystemFreeSize];
        if (deviceFreeSpace) {
            usageString = [NSByteCountFormatter stringFromByteCount:[deviceFreeSpace unsignedLongLongValue] countStyle:NSByteCountFormatterCountStyleFile];
        }
    }
    NSString *finalFooterString = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ free", nil), itemCountString, usageString];
    [self.footerView.footerLabel setText:finalFooterString];
}

- (void)loadEntryListData
{
    NSError *entryLoadError = nil;
    [self loadEntryListDataWithError:&entryLoadError];
    if (entryLoadError) {
        [self.navigationController.view makeToast:[entryLoadError localizedDescription]];
    }
}

- (void)refreshEntryListView:(UIRefreshControl *)refreshControl {
    [self loadEntryListData];
    [self.tableView reloadData];
    if ([refreshControl isRefreshing]) {
        [refreshControl endRefreshing];
    }
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section)
        {
            return YES;
        }
    }
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            return indexPath;
        } else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            return indexPath;
        }
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            if ([tableView isEditing]) {
                [self updateToolbarStatus:self.toolbar];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section)
        {
            if ([tableView isEditing]) {
                [self updateToolbarStatus:self.toolbar];
            } else {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                NSDictionary *entryAttributes = self.entryList[indexPath.row];
                if ([entryAttributes[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeTypeBundle]) {
                    
                }
                else if ([entryAttributes[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
                { // Directory or Symbolic Link Directory
                    NSString *directoryPath = entryAttributes[XXTExplorerViewEntryAttributePath];
                    // We'd better try to access it before we enter it.
                    NSError *accessError = nil;
                    [self.class.explorerFileManager contentsOfDirectoryAtPath:directoryPath error:&accessError];
                    if (accessError) {
                        [self.navigationController.view makeToast:[accessError localizedDescription]];
                    }
                    else {
                        XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:directoryPath];
                        [self.navigationController pushViewController:explorerViewController animated:YES];
                    }
                }
            }
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            if ([tableView isEditing]) {
                
            } else {
                NSDictionary *entryAttributes = self.homeEntryList[indexPath.row];
                NSString *directoryRelativePath = entryAttributes[XXTExplorerViewSectionHomeSeriesDetailPathKey];
                NSString *directoryPath = [[[self class] rootPath] stringByAppendingPathComponent:directoryRelativePath];
                NSError *accessError = nil;
                [self.class.explorerFileManager contentsOfDirectoryAtPath:directoryPath error:&accessError];
                if (accessError) {
                    [self.navigationController.view makeToast:[accessError localizedDescription]];
                }
                else {
                    XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:directoryPath];
                    [self.navigationController pushViewController:explorerViewController animated:YES];
                }
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (![tableView isEditing]) {
            if (XXTExplorerViewSectionIndexList == indexPath.section) {
                XXTESwipeTableCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                [cell showSwipe:XXTESwipeDirectionLeftToRight animated:YES];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            return XXTExplorerViewCellHeight;
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            return XXTExplorerViewHomeCellHeight;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == section) {
            return 24.f;
        } // Notice: assume that there will not be any headers for Home section
    }
    return 0;
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == section) {
            return 48.f;
        } // Notice: assume that there will not be any headers for Home section
    }
    return 0;
}
*/


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == section) {
            XXTExplorerHeaderView *entryHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
            if (!entryHeaderView) {
                entryHeaderView = [[XXTExplorerHeaderView alloc] initWithReuseIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
            }
            NSString *rootPath = [[self class] rootPath];
            NSRange rootRange = [self.entryPath rangeOfString:rootPath];
            if (rootRange.location == 0) {
                NSString *tiledPath = [self.entryPath stringByReplacingCharactersInRange:rootRange withString:@"~"];
                [entryHeaderView.headerLabel setText:tiledPath];
            } else {
                [entryHeaderView.headerLabel setText:self.entryPath];
            }
            return entryHeaderView;
        } // Notice: assume that there will not be any headers for Home section
    }
    return nil;
}

/*
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == section) {
            XXTExplorerFooterView *entryFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:XXTExplorerEntryFooterViewReuseIdentifier];
            if (!entryFooterView) {
                entryFooterView = [[XXTExplorerFooterView alloc] initWithReuseIdentifier:XXTExplorerEntryFooterViewReuseIdentifier];
            }
            NSUInteger itemCount = self.entryList.count;
            NSString *itemCountString = nil;
            if (itemCount == 0) {
                itemCountString = NSLocalizedString(@"No item", nil);
            } else if (itemCount == 1) {
                itemCountString = NSLocalizedString(@"1 item", nil);
            } else  {
                itemCountString = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), (unsigned long)itemCount];
            }
            NSString *usageString = nil;
            NSError *usageError = nil;
            NSDictionary *fileSystemAttributes = [self.explorerFileManager attributesOfFileSystemForPath:self.entryPath error:&usageError];
            if (!usageError) {
                NSNumber *deviceFreeSpace = fileSystemAttributes[NSFileSystemFreeSize];
                if (deviceFreeSpace) {
                    usageString = [NSByteCountFormatter stringFromByteCount:[deviceFreeSpace unsignedLongLongValue] countStyle:NSByteCountFormatterCountStyleFile];
                }
            }
            NSString *finalFooterString = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ free", nil), itemCountString, usageString];
            [entryFooterView.footerLabel setText:finalFooterString];
            return entryFooterView;
        } // Notice: assume that there will not be any footer for Home section
    }
    return nil;
}
*/

#pragma mark - UITableViewDataSource

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
        }
        else if (XXTExplorerViewSectionIndexList == section) {
            return self.entryList.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            XXTExplorerViewCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewCellReuseIdentifier];
            if (!entryCell) {
                entryCell = [[XXTExplorerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewCellReuseIdentifier];
            }
            entryCell.delegate = self;
            entryCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            entryCell.entryIconImageView.image = self.entryList[indexPath.row][XXTExplorerViewEntryAttributeIconImage];
            entryCell.entryTitleLabel.text = self.entryList[indexPath.row][XXTExplorerViewEntryAttributeName];
            entryCell.entrySubtitleLabel.text = [self.class.explorerDateFormatter stringFromDate:self.entryList[indexPath.row][XXTExplorerViewEntryAttributeCreationDate]];
            UILongPressGestureRecognizer *cellLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(entryCellDidLongPress:)];
            cellLongPressGesture.delegate = self;
            [entryCell addGestureRecognizer:cellLongPressGesture];
            return entryCell;
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            XXTExplorerViewHomeCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewHomeCellReuseIdentifier];
            if (!entryCell) {
                entryCell = [[XXTExplorerViewHomeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewHomeCellReuseIdentifier];
            }
            entryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            entryCell.entryIconImageView.image = [UIImage imageNamed:self.homeEntryList[indexPath.row][XXTExplorerViewSectionHomeSeriesDetailIconKey]];
            entryCell.entryTitleLabel.text = self.homeEntryList[indexPath.row][XXTExplorerViewSectionHomeSeriesDetailTitleKey];
            entryCell.entrySubtitleLabel.text = self.homeEntryList[indexPath.row][XXTExplorerViewSectionHomeSeriesDetailSubtitleKey];
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
        [self setEditing:YES animated:YES];
        if (self.tableView.delegate) {
            [self.tableView.delegate tableView:self.tableView willSelectRowAtIndexPath:indexPath];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return (!self.isEditing);
}

#pragma mark - XXTExplorerToolbarDelegate

- (void)toolbar:(XXTExplorerToolbar *)toolbar buttonTypeTapped:(NSString *)buttonType {
    if (toolbar == self.toolbar) {
        if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeScan])
        {
            
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeAddItem])
        {
            
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeSort])
        {
            if (XXTEDefaultsEnum(XXTExplorerViewEntryListSortOrderKey) != XXTExplorerViewEntryListSortOrderAsc)
            {
                XXTEDefaultsSetBasic(XXTExplorerViewEntryListSortOrderKey, XXTExplorerViewEntryListSortOrderAsc);
                XXTEDefaultsSetObject(XXTExplorerViewEntryListSortFieldKey, XXTExplorerViewEntryAttributeName);
            }
            else
            {
                XXTEDefaultsSetBasic(XXTExplorerViewEntryListSortOrderKey, XXTExplorerViewEntryListSortOrderDesc);
                XXTEDefaultsSetObject(XXTExplorerViewEntryListSortFieldKey, XXTExplorerViewEntryAttributeCreationDate);
            }
            [self updateToolbarButton:self.toolbar];
            [self loadEntryListData];
            [self.tableView reloadData];
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypePaste])
        {
            
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeCompress])
        {
            
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeShare])
        {
            
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeTrash])
        {
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            NSString *formatString = nil;
            if (selectedIndexPaths.count == 1) {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"Delete 1 item?\nThis operation cannot be revoked.", nil)];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"Delete %d items?\nThis operation cannot be revoked.", nil), selectedIndexPaths.count];
            }
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Confirm", nil)
                                                                message:formatString
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[  ]
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            objc_setAssociatedObject(alertView, @selector(removeEntriesAtIndexPaths:), selectedIndexPaths, OBJC_ASSOCIATION_COPY_NONATOMIC);
            [alertView showAnimated:YES completionHandler:nil];
        }
    }
}

#pragma mark - UIViewController (UIViewControllerEditing)

- (BOOL)isEditing {
    return [self.tableView isEditing];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    if (editing) {
        [self.toolbar updateStatus:XXTExplorerToolbarStatusEditing];
    }
    else
    {
        [self.toolbar updateStatus:XXTExplorerToolbarStatusDefault];
    }
    [self updateToolbarStatus:self.toolbar];
}

#pragma mark - XXTESwipeTableCellDelegate

- (BOOL)swipeTableCell:(XXTESwipeTableCell *) cell canSwipe:(XXTESwipeDirection) direction fromPoint:(CGPoint) point {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (entryDetail) {
        return YES;
    }
    return NO;
}

- (BOOL)swipeTableCell:(XXTESwipeTableCell *) cell tappedButtonAtIndex:(NSInteger)index direction:(XXTESwipeDirection)direction fromExpansion:(BOOL)fromExpansion {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (direction == XXTESwipeDirectionLeftToRight)
    {
        
    }
    else if (direction == XXTESwipeDirectionRightToLeft)
    {
        NSString *formatString = [NSString stringWithFormat:NSLocalizedString(@"Delete %@?\nThis operation cannot be revoked.", nil), entryDetail[XXTExplorerViewEntryAttributeName]];
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Confirm", nil)
                                                            message:formatString
                                                              style:LGAlertViewStyleActionSheet
                                                       buttonTitles:@[  ]
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                           delegate:self];
        objc_setAssociatedObject(alertView, @selector(removeEntryCell:), cell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [alertView showAnimated:YES completionHandler:nil];
    }
    return NO;
}

- (NSArray *)swipeTableCell:(XXTESwipeTableCell *)cell swipeButtonsForDirection:(XXTESwipeDirection)direction
             swipeSettings:(XXTESwipeSettings *)swipeSettings expansionSettings:(XXTESwipeExpansionSettings *)expansionSettings {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (direction == XXTESwipeDirectionLeftToRight)
    {
        NSMutableArray *swipeButtons = [[NSMutableArray alloc] init];
        
        if (YES == [entryDetail[XXTExplorerViewEntryAttributePermission] containsObject:XXTExplorerViewEntryAttributePermissionExecuteable])
        {
            XXTESwipeButton *swipeLaunchButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"XXTExplorerActionIconLaunch"]
                                                                  backgroundColor:[XXTE_COLOR colorWithAlphaComponent:1.f]
                                                                           insets:UIEdgeInsetsMake(0, 24, 0, 24)];
            [swipeButtons addObject:swipeLaunchButton];
        }
        if (YES == [entryDetail[XXTExplorerViewEntryAttributePermission] containsObject:XXTExplorerViewEntryAttributePermissionEditable]
            && [entryDetail[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeRegular])
        {
            XXTESwipeButton *swipeEditButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"XXTExplorerActionIconEdit"]
                                                                backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.8f]
                                                                         insets:UIEdgeInsetsMake(0, 24, 0, 24)];
            [swipeButtons addObject:swipeEditButton];
        }
        XXTESwipeButton *swipePropertyButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"XXTExplorerActionIconProperty"]
                                                                backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.6f]
                                                                         insets:UIEdgeInsetsMake(0, 24, 0, 24)];
        [swipeButtons addObject:swipePropertyButton];
        return swipeButtons;
    }
    else if (direction == XXTESwipeDirectionRightToLeft)
    {
        XXTESwipeButton *swipeTrashButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:@"XXTExplorerActionIconTrash"]
                                                             backgroundColor:XXTE_DANGER_COLOR
                                                                      insets:UIEdgeInsetsMake(0, 24, 0, 24)];
        return @[ swipeTrashButton ];
    }
    return @[];
}

#pragma mark - LGAlertViewDelegate

- (void)alertViewDestructed:(LGAlertView *)alertView {
    SEL selectors[] = {
        @selector(removeEntryCell:),
        @selector(removeEntriesAtIndexPaths:),
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    for (int i = 0; i < sizeof(selectors) / sizeof(SEL); i++) {
        SEL selector = selectors[i];
        id obj = objc_getAssociatedObject(alertView, selector);
        objc_setAssociatedObject(alertView, selector, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (obj) {
            [self performSelector:selector withObject:obj];
            break;
        }
    }
#pragma clang diagnostic pop
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    objc_removeAssociatedObjects(alertView);
}

- (void)removeEntryCell:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    NSError *removeError = nil;
    BOOL result = [self.class.explorerFileManager removeItemAtPath:entryDetail[XXTExplorerViewEntryAttributePath] error:&removeError];
    if (result) {
        [self loadEntryListData];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } else {
        if (removeError) {
            [self.navigationController.view makeToast:[removeError localizedDescription]];
        }
    }
}

- (void)removeEntriesAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    
}

@end
