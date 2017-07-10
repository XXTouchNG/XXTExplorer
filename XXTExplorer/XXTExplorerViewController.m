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
#import "XXTExplorerEntryService.h"
#import "XXTExplorerViewController.h"
#import "XXTExplorerHeaderView.h"
#import "XXTExplorerFooterView.h"
#import "XXTExplorerToolbar.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerViewHomeCell.h"
#import "XXTExplorerDefaults.h"
#import "XXTENotificationCenterDefines.h"
#import "UIView+XXTEToast.h"
#import <LGAlertView/LGAlertView.h>
#import "XXTEDispatchDefines.h"
#import "zip.h"
#import "XXTExplorerCreateItemViewController.h"
#import "XXTExplorerCreateItemNavigationController.h"
#import "XXTEScanViewController.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import "XXTEUserInterfaceDefines.h"
#import "XXTENetworkDefines.h"
#import "XXTExplorerItemDetailViewController.h"
#import "XXTExplorerItemDetailNavigationController.h"

typedef enum : NSUInteger {
    XXTExplorerViewSectionIndexHome = 0,
    XXTExplorerViewSectionIndexList,
    XXTExplorerViewSectionIndexMax
} XXTExplorerViewSectionIndex;

static BOOL _kXXTExplorerFetchingSelectedScript = NO;

#define XXTEDefaultsBool(key) ([[self.class.explorerDefaults objectForKey:key] boolValue])
#define XXTEDefaultsEnum(key) ([[self.class.explorerDefaults objectForKey:key] unsignedIntegerValue])
#define XXTEDefaultsObject(key) ([self.class.explorerDefaults objectForKey:key])
#define XXTEDefaultsSetBasic(key, value) ([self.class.explorerDefaults setObject:@(value) forKey:key])
#define XXTEDefaultsSetObject(key, obj) ([self.class.explorerDefaults setObject:obj forKey:key])
#define XXTEBuiltInDefaultsBool(key) ([[self.class.explorerBuiltInDefaults objectForKey:key] boolValue])
#define XXTEBuiltInDefaultsEnum(key) ([[self.class.explorerBuiltInDefaults objectForKey:key] unsignedIntegerValue])
#define XXTEBuiltInDefaultsObject(key) ([self.class.explorerBuiltInDefaults objectForKey:key])

@interface XXTExplorerViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, XXTExplorerToolbarDelegate, XXTESwipeTableCellDelegate, LGAlertViewDelegate>

@end

@implementation XXTExplorerViewController {
    BOOL firstTimeLoaded;
    BOOL busyOperationProgressFlag;
}

+ (UIPasteboard *)explorerPasteboard {
    static UIPasteboard *explorerPasteboard = nil;
    if (!explorerPasteboard) {
        explorerPasteboard = ({
            [UIPasteboard pasteboardWithName:XXTExplorerPasteboardName create:YES];
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

+ (NSString *)initialPath {
    static NSString *initialPath = nil;
    if (!initialPath) {
        initialPath = ({
            NSString *initialRelativePath = XXTEBuiltInDefaultsObject(XXTExplorerViewInitialPath);
            [self.class.rootPath stringByAppendingPathComponent:initialRelativePath];
        });
    }
    return initialPath;
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

+ (XXTExplorerEntryParser *)explorerEntryParser {
    static XXTExplorerEntryParser *explorerEntryParser = nil;
    if (!explorerEntryParser) {
        explorerEntryParser = [[XXTExplorerEntryParser alloc] init];
    }
    return explorerEntryParser;
}

+ (XXTExplorerEntryService *)explorerEntryService {
    static XXTExplorerEntryService *explorerEntryService = nil;
    if (!explorerEntryService) {
        explorerEntryService = [[XXTExplorerEntryService alloc] init];
    }
    return explorerEntryService;
}

+ (BOOL)isFetchingSelectedScript {
    return _kXXTExplorerFetchingSelectedScript;
}

+ (void)setFetchingSelectedScript:(BOOL)fetching {
    _kXXTExplorerFetchingSelectedScript = fetching;
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

+ (NSString *)selectedScriptPath {
    return XXTEDefaultsObject(XXTExplorerViewSelectedScriptPathKey);
}

- (instancetype)initWithEntryPath:(NSString *)path {
    if (self = [super init]) {
        [self setupWithPath:path];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    {
        NSString *userDefaultsPath = [[NSBundle mainBundle] pathForResource:XXTExplorerDefaults ofType:@"plist"];
        NSDictionary *userDefaults = [[NSDictionary alloc] initWithContentsOfFile:userDefaultsPath];
        NSArray *explorerUserDefaults = userDefaults[@"EXPLORER_USER_DEFAULTS"];
        for (NSDictionary *explorerUserDefault in explorerUserDefaults) {
            NSString *defaultKey = explorerUserDefault[@"key"];
            if (![self.class.explorerDefaults objectForKey:defaultKey])
            {
                id defaultValue = explorerUserDefault[@"default"];
                [self.class.explorerDefaults setObject:defaultValue forKey:defaultKey];
            }
        }
    }
    {
        if (!path) {
            if (![self.class.explorerFileManager fileExistsAtPath:self.class.initialPath]) {
                NSError *createDirectoryError = nil;
                BOOL createDirectoryResult = [self.class.explorerFileManager createDirectoryAtPath:self.class.initialPath withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
                if (!createDirectoryResult) {

                }
            }
            path = self.class.initialPath;
        }
        _entryPath = path;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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

    [self loadEntryListData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
    [self updateToolbarButton:self.toolbar];
    [self updateToolbarStatus:self.toolbar];
    if (firstTimeLoaded) {
        [self loadEntryListData];
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!firstTimeLoaded) {
        firstTimeLoaded = YES;
    }
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
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
    } else if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidBecomeActive]) {
        [self refreshEntryListView:nil];
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
    if ([[[self class] explorerPasteboard] strings].count > 0) {
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
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:NO];
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
        } else {
            _homeEntryList = nil;
        }
    }
    
    _entryList = ({
        BOOL hidesDot = XXTEDefaultsBool(XXTExplorerViewEntryListHideDotItemKey);
        NSError *localError = nil;
        NSArray <NSString *> *entrySubdirectoryPathList = [self.class.explorerFileManager contentsOfDirectoryAtPath:self.entryPath error:&localError];
        if (localError && error) *error = localError;
        NSMutableArray <NSDictionary *> *entryDirectoryAttributesList = [[NSMutableArray alloc] init];
        NSMutableArray <NSDictionary *> *entryOtherAttributesList = [[NSMutableArray alloc] init];
        for (NSString *entrySubdirectoryName in entrySubdirectoryPathList)
        {
            if (hidesDot && [entrySubdirectoryName hasPrefix:@"."]) {
                continue;
            }
            NSString *entrySubdirectoryPath = [self.entryPath stringByAppendingPathComponent:entrySubdirectoryName];
            NSDictionary *entryAttributes = [self.class.explorerEntryParser entryOfPath:entrySubdirectoryPath withError:&localError];
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
    NSDictionary *fileSystemAttributes = [self.class.explorerFileManager attributesOfFileSystemForPath:self.class.rootPath error:&usageError];
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
        showUserMessage(self.navigationController.view, [entryLoadError localizedDescription]);
    }
}

- (void)refreshEntryListView:(UIRefreshControl *)refreshControl {
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
                    XXTEDefaultsSetObject(XXTExplorerViewSelectedScriptPathKey, selectedScriptPath);
                }
            }
        })
        .catch(^(NSError *serverError) {
            if (serverError.code == -1004) {
                showUserMessage(self.navigationController.view, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                showUserMessage(self.navigationController.view, [serverError localizedDescription]);
            }
        })
        .finally(^() {
            [self loadEntryListData];
            [self.tableView reloadData];
            if (refreshControl && [refreshControl isRefreshing]) {
                [refreshControl endRefreshing];
            }
            [self.class setFetchingSelectedScript:NO];
        });
    }
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

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
                NSString *entryMaskType = entryAttributes[XXTExplorerViewEntryAttributeMaskType];
                NSString *entryName = entryAttributes[XXTExplorerViewEntryAttributeName];
                NSString *entryPath = entryAttributes[XXTExplorerViewEntryAttributePath];
                NSString *internalExt = entryAttributes[XXTExplorerViewEntryAttributeInternalExtension];
                if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
                { // Directory or Symbolic Link Directory
                    // We'd better try to access it before we enter it.
                    NSError *accessError = nil;
                    [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&accessError];
                    if (accessError) {
                        showUserMessage(self.navigationController.view, [accessError localizedDescription]);
                    }
                    else {
                        XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:entryPath];
                        [self.navigationController pushViewController:explorerViewController animated:YES];
                    }
                }
                else if (
                        [entryMaskType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular] ||
                        [entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle])
                {
                    if ([self.class.explorerFileManager isReadableFileAtPath:entryPath]) {
                        if ([internalExt isEqualToString:XXTExplorerViewEntryAttributeInternalExtensionArchive])
                        {
                            [self tableView:tableView archiveEntryTappedForRowWithIndexPath:indexPath];
                        }
                        else if ([internalExt isEqualToString:XXTExplorerViewEntryAttributeInternalExtensionExecutable])
                        {
                            blockUserInteractions(self, YES);
                            [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{ @"filename": entryPath}]
                            .then(convertJsonString)
                            .then(^(NSDictionary *jsonDictionary) {
                                if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
                                    XXTEDefaultsSetObject(XXTExplorerViewSelectedScriptPathKey, entryPath);
                                } else {
                                    @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select script: %@", nil), jsonDictionary[@"message"]];
                                }
                            })
                            .catch(^(NSError *serverError) {
                                if (serverError.code == -1004) {
                                    showUserMessage(self.navigationController.view, NSLocalizedString(@"Could not connect to the daemon.", nil));
                                } else {
                                    showUserMessage(self.navigationController.view, [serverError localizedDescription]);
                                }
                            })
                            .finally(^() {
                                blockUserInteractions(self, NO);
                                [self loadEntryListData];
                                [self.tableView reloadData];
                            });
                        }
                        else
                        {
                            if ([self.class.explorerEntryService hasDefaultViewControllerForEntry:entryAttributes])
                            {
    
                            }
                            else
                            {
                                // TODO: Assign Open In Methods...
                                [self.navigationController.view makeToast:[NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be opened because the file extension can't be recognized.", nil), entryName]];
                            }
                        }
                    } else {
                        // TODO: not readable
                    }
                }
                else if ([entryMaskType isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink])
                {
                    showUserMessage(self.navigationController.view, [NSString stringWithFormat:NSLocalizedString(@"The alias \"%@\" can't be opened because the original item can't be found.", nil), entryName]);
                }
                else
                {
                    showUserMessage(self.navigationController.view, NSLocalizedString(@"Only regular file, directory and symbolic link are supported.", nil));
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
                NSString *directoryPath = [self.class.rootPath stringByAppendingPathComponent:directoryRelativePath];
                NSError *accessError = nil;
                [self.class.explorerFileManager contentsOfDirectoryAtPath:directoryPath error:&accessError];
                if (accessError) {
                    showUserMessage(self.navigationController.view, [accessError localizedDescription]);
                }
                else {
                    XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:directoryPath];
                    [self.navigationController pushViewController:explorerViewController animated:YES];
                }
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView archiveEntryTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entryAttributes = self.entryList[indexPath.row];
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Unarchive Confirm", nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Unarchive \"%@\" to current directory?", nil), entryAttributes[XXTExplorerViewEntryAttributeName]]
                                                          style:LGAlertViewStyleActionSheet
                                                   buttonTitles:@[  ]
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                       delegate:self];
    objc_setAssociatedObject(alertView, @selector(alertView:unarchiveEntryAtIndexPath:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alertView showAnimated:YES completionHandler:nil];
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == section) {
            XXTExplorerHeaderView *entryHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
            if (!entryHeaderView) {
                entryHeaderView = [[XXTExplorerHeaderView alloc] initWithReuseIdentifier:XXTExplorerEntryHeaderViewReuseIdentifier];
            }
            NSString *rootPath = self.class.rootPath;
            NSRange rootRange = [self.entryPath rangeOfString:rootPath];
            if (rootRange.location == 0) {
                NSString *tiledPath = [self.entryPath stringByReplacingCharactersInRange:rootRange withString:@"~"];
                [entryHeaderView.headerLabel setText:tiledPath];
            } else {
                [entryHeaderView.headerLabel setText:self.entryPath];
            }
            entryHeaderView.userInteractionEnabled = YES;
            UITapGestureRecognizer *addressTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addressLabelTapped:)];
            addressTapGestureRecognizer.delegate = self;
            [entryHeaderView addGestureRecognizer:addressTapGestureRecognizer];
            return entryHeaderView;
        } // Notice: assume that there will not be any headers for Home section
    }
    return nil;
}

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
            NSDictionary *entryDetail = self.entryList[indexPath.row];
            XXTExplorerViewCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewCellReuseIdentifier];
            if (!entryCell) {
                entryCell = [[XXTExplorerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewCellReuseIdentifier];
            }
            entryCell.delegate = self;
            entryCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            entryCell.entryIconImageView.image = entryDetail[XXTExplorerViewEntryAttributeIconImage];
            entryCell.entryTitleLabel.text = entryDetail[XXTExplorerViewEntryAttributeName];
            if ([entryDetail[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink] &&
                [entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink]) {
                // broken symlink
                entryCell.entryTitleLabel.textColor = XXTE_COLOR_DANGER;
                entryCell.flagType = XXTExplorerViewCellFlagTypeBroken;
            }
            else if ([entryDetail[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink] &&
                     ![entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBrokenSymlink]) {
                // symlink
                entryCell.entryTitleLabel.textColor = XXTE_COLOR;
                entryCell.flagType = XXTExplorerViewCellFlagTypeNone;
            }
            else {
                entryCell.entryTitleLabel.textColor = [UIColor blackColor];
                entryCell.flagType = XXTExplorerViewCellFlagTypeNone;
            }
            if (![entryDetail[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory] &&
                [self.class.selectedScriptPath isEqualToString:entryDetail[XXTExplorerViewEntryAttributePath]]) {
                // path itself
                entryCell.entryTitleLabel.textColor = XXTE_COLOR_SUCCESS;
                entryCell.flagType = XXTExplorerViewCellFlagTypeSelected;
            }
            else if ([entryDetail[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory] &&
                     [self.class.selectedScriptPath hasPrefix:entryDetail[XXTExplorerViewEntryAttributePath]]) {
                // in path
                entryCell.entryTitleLabel.textColor = XXTE_COLOR_SUCCESS;
                entryCell.flagType = XXTExplorerViewCellFlagTypeSelected;
            }
            entryCell.entrySubtitleLabel.text = [self.class.explorerDateFormatter stringFromDate:entryDetail[XXTExplorerViewEntryAttributeCreationDate]];
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
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
}

- (void)addressLabelTapped:(UITapGestureRecognizer *)recognizer {
    if (![self isEditing] && recognizer.state == UIGestureRecognizerStateEnded) {
        NSString *detailText = ((XXTExplorerHeaderView *)recognizer.view).headerLabel.text;
        if (detailText && detailText.length > 0) {
            blockUserInteractions(self, YES);
            [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                [[UIPasteboard generalPasteboard] setString:detailText];
                fulfill(nil);
            }].finally(^() {
                showUserMessage(self.navigationController.view, NSLocalizedString(@"Current path has been copied to the pasteboard.", nil));
                blockUserInteractions(self, NO);
            });
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
            XXTEScanViewController *scanViewController = [[XXTEScanViewController alloc] init];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scanViewController];
            [self presentViewController:navController animated:YES completion:nil];
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeAddItem])
        {
            XXTExplorerCreateItemViewController *createItemViewController = [[XXTExplorerCreateItemViewController alloc] initWithEntryPath:self.entryPath];
            XXTExplorerCreateItemNavigationController *createItemNavigationController = [[XXTExplorerCreateItemNavigationController alloc] initWithRootViewController:createItemViewController];
            [self.navigationController presentViewController:createItemNavigationController animated:YES completion:nil];
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
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            if (!selectedIndexPaths) {
                selectedIndexPaths = @[];
            }
            NSString *formatString = nil;
            if (selectedIndexPaths.count == 1) {
                NSIndexPath *firstIndexPath = selectedIndexPaths[0];
                NSDictionary *firstAttributes = self.entryList[firstIndexPath.row];
                formatString = [NSString stringWithFormat:NSLocalizedString(@"\"%@\"", nil), firstAttributes[XXTExplorerViewEntryAttributeName]];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), selectedIndexPaths.count];
            }
            BOOL clearEnabled = NO;
            NSArray <NSString *> *pasteboardArray = [self.class.explorerPasteboard strings];
            NSUInteger pasteboardCount = pasteboardArray.count;
            NSString *pasteboardFormatString = nil;
            if (pasteboardCount == 0)
            {
                pasteboardFormatString = NSLocalizedString(@"No item", nil);
                clearEnabled = NO;
            }
            else
            {
                if (pasteboardCount == 1) {
                    pasteboardFormatString = NSLocalizedString(@"1 item", nil);
                } else {
                    pasteboardFormatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), pasteboardCount];
                }
                clearEnabled = YES;
            }
            if ([self isEditing])
            {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Pasteboard", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"%@ stored.", nil), pasteboardFormatString]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[
                                                                              [NSString stringWithFormat:@"Copy %@", formatString]
                                                                              ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clear Pasteboard", nil)
                                                                   delegate:self];
                alertView.destructiveButtonEnabled = clearEnabled;
                alertView.buttonsIconImages = @[ [UIImage imageNamed:XXTExplorerAlertViewActionPasteboardExportCopy] ];
                objc_setAssociatedObject(alertView, [XXTExplorerAlertViewAction UTF8String], XXTExplorerAlertViewActionPasteboardImport, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(alertView, [XXTExplorerAlertViewContext UTF8String], selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(alertView, @selector(alertView:clearPasteboardEntriesStored:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated];
            }
            else
            {
                NSString *entryName = [self.entryPath lastPathComponent];
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Pasteboard", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"%@ stored.", nil), pasteboardFormatString]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[
                                                                              [NSString stringWithFormat:@"Paste to \"%@\"", entryName],
                                                                              [NSString stringWithFormat:@"Move to \"%@\"", entryName],
                                                                              [NSString stringWithFormat:@"Create Link at \"%@\"", entryName]
                                                                              ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clear Pasteboard", nil)
                                                                   delegate:self];
                alertView.destructiveButtonEnabled = clearEnabled;
                alertView.buttonsEnabled = (pasteboardCount != 0);
                alertView.buttonsIconImages = @[ [UIImage imageNamed:XXTExplorerAlertViewActionPasteboardExportPaste], [UIImage imageNamed:XXTExplorerAlertViewActionPasteboardExportCut], [UIImage imageNamed:XXTExplorerAlertViewActionPasteboardExportLink] ];
                objc_setAssociatedObject(alertView, [XXTExplorerAlertViewAction UTF8String], XXTExplorerAlertViewActionPasteboardExport, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(alertView, [XXTExplorerAlertViewContext UTF8String], self.entryPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(alertView, @selector(alertView:clearPasteboardEntriesStored:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated];
            }
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeCompress])
        {
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            NSString *formatString = nil;
            if (selectedIndexPaths.count == 1) {
                NSIndexPath *firstIndexPath = selectedIndexPaths[0];
                NSDictionary *firstAttributes = self.entryList[firstIndexPath.row];
                formatString = [NSString stringWithFormat:@"\"%@\"", firstAttributes[XXTExplorerViewEntryAttributeName]];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), selectedIndexPaths.count];
            }
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Archive Confirm", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Archive %@?", nil), formatString]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[  ]
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            objc_setAssociatedObject(alertView, @selector(alertView:archiveEntriesAtIndexPaths:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [alertView showAnimated:YES completionHandler:nil];
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeShare])
        {
            
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeTrash])
        {
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            NSString *formatString = nil;
            if (selectedIndexPaths.count == 1) {
                NSIndexPath *firstIndexPath = selectedIndexPaths[0];
                NSDictionary *firstAttributes = self.entryList[firstIndexPath.row];
                formatString = [NSString stringWithFormat:@"\"%@\"", firstAttributes[XXTExplorerViewEntryAttributeName]];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), selectedIndexPaths.count];
            }
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Confirm", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Delete %@?\nThis operation cannot be revoked.", nil), formatString]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[  ]
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            objc_setAssociatedObject(alertView, @selector(alertView:removeEntriesAtIndexPaths:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [alertView showAnimated:YES completionHandler:nil];
        }
    }
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
    }
    else
    {
        [self.toolbar updateStatus:XXTExplorerToolbarStatusDefault];
    }
    [self updateToolbarStatus:self.toolbar];
}

#pragma mark - XXTESwipeTableCellDelegate

- (BOOL)swipeTableCell:(XXTESwipeTableCell *)cell canSwipe:(XXTESwipeDirection)direction fromPoint:(CGPoint)point {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (entryDetail) {
        return YES;
    }
    return NO;
}

- (BOOL)swipeTableCell:(XXTESwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(XXTESwipeDirection)direction fromExpansion:(BOOL)fromExpansion {
    static char * const XXTESwipeButtonAction = "XXTESwipeButtonAction";
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    NSString *entryPath = entryDetail[XXTExplorerViewEntryAttributePath];
    if (direction == XXTESwipeDirectionLeftToRight)
    {
        NSString *buttonAction = objc_getAssociatedObject(cell.leftButtons[index], XXTESwipeButtonAction);
        if ([buttonAction isEqualToString:@"Launch"]) {
            BOOL selectAfterLaunch = XXTEDefaultsBool(XXTExplorerViewSelectLaunchedScriptKey);
            blockUserInteractions(self, YES);
            [NSURLConnection POST:uAppDaemonCommandUrl(@"is_running") JSON:@{}]
            .then(convertJsonString)
            .then(^(NSDictionary *jsonDirectory) {
                if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
                    return [NSURLConnection POST:uAppDaemonCommandUrl(@"launch_script_file") JSON:@{ @"filename": entryPath, @"envp": @{ @"XXTOUCH_LAUNCH_VIA": @"APPLICATION" } }];
                } else {
                    @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
                }
            })
            .then(convertJsonString)
            .then(^(NSDictionary *jsonDirectory) {
                if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
                    if (selectAfterLaunch) {
                        return [NSURLConnection POST:uAppDaemonCommandUrl(@"select_script_file") JSON:@{ @"filename": entryPath }];
                    }
                } else {
                    @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot launch script: %@", nil), jsonDirectory[@"message"]];
                }
                return [PMKPromise promiseWithValue:@{}];
            })
            .then(convertJsonString)
            .then(^(NSDictionary *jsonDirectory) {
                if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
                    XXTEDefaultsSetObject(XXTExplorerViewSelectedScriptPathKey, entryPath);
                    [self loadEntryListData];
                    [self.tableView reloadData];
                } else {
                    @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select script: %@", nil), jsonDirectory[@"message"]];
                }
            })
            .catch(^(NSError *serverError) {
                if (serverError.code == -1004) {
                    showUserMessage(self.navigationController.view, NSLocalizedString(@"Could not connect to the daemon.", nil));
                } else {
                    showUserMessage(self.navigationController.view, [serverError localizedDescription]);
                }
            })
            .finally(^() {
                blockUserInteractions(self, NO);
            });
        } else if ([buttonAction isEqualToString:@"Property"]) {
            XXTExplorerItemDetailViewController *detailController = [[XXTExplorerItemDetailViewController alloc] initWithEntry:entryDetail];
            XXTExplorerItemDetailNavigationController *detailNavigationController = [[XXTExplorerItemDetailNavigationController alloc] initWithRootViewController:detailController];
            [self.navigationController presentViewController:detailNavigationController animated:YES completion:nil];
        }
    }
    else if (direction == XXTESwipeDirectionRightToLeft && index == 0)
    {
        NSString *buttonAction = objc_getAssociatedObject(cell.rightButtons[index], XXTESwipeButtonAction);
        if ([buttonAction isEqualToString:@"Trash"]) {
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Confirm", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Delete \"%@\"?\nThis operation cannot be revoked.", nil), entryDetail[XXTExplorerViewEntryAttributeName]]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[  ]
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            objc_setAssociatedObject(alertView, @selector(alertView:removeEntryCell:), cell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [alertView showAnimated:YES completionHandler:nil];
        }
    }
    return NO;
}

- (NSArray *)swipeTableCell:(XXTESwipeTableCell *)cell swipeButtonsForDirection:(XXTESwipeDirection)direction
             swipeSettings:(XXTESwipeSettings *)swipeSettings expansionSettings:(XXTESwipeExpansionSettings *)expansionSettings {
    static char * const XXTESwipeButtonAction = "XXTESwipeButtonAction";
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (direction == XXTESwipeDirectionLeftToRight)
    {
        NSMutableArray *swipeButtons = [[NSMutableArray alloc] init];
        
        if (YES == [entryDetail[XXTExplorerViewEntryAttributePermission] containsObject:XXTExplorerViewEntryAttributePermissionExecuteable])
        {
            XXTESwipeButton *swipeLaunchButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconLaunch]
                                                                  backgroundColor:[XXTE_COLOR colorWithAlphaComponent:1.f]
                                                                           insets:UIEdgeInsetsMake(0, 24, 0, 24)];
            objc_setAssociatedObject(swipeLaunchButton, XXTESwipeButtonAction, @"Launch", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:swipeLaunchButton];
        }
        if (YES == [entryDetail[XXTExplorerViewEntryAttributePermission] containsObject:XXTExplorerViewEntryAttributePermissionEditable]
            && [entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeTypeRegular])
        {
            XXTESwipeButton *swipeEditButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconEdit]
                                                                backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.8f]
                                                                         insets:UIEdgeInsetsMake(0, 24, 0, 24)];
            objc_setAssociatedObject(swipeEditButton, XXTESwipeButtonAction, @"Edit", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:swipeEditButton];
        }
        XXTESwipeButton *swipePropertyButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconProperty]
                                                                backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.6f]
                                                                         insets:UIEdgeInsetsMake(0, 24, 0, 24)];
        objc_setAssociatedObject(swipePropertyButton, XXTESwipeButtonAction, @"Property", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [swipeButtons addObject:swipePropertyButton];
        return swipeButtons;
    }
    else if (direction == XXTESwipeDirectionRightToLeft)
    {
        XXTESwipeButton *swipeTrashButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconTrash]
                                                             backgroundColor:XXTE_COLOR_DANGER
                                                                      insets:UIEdgeInsetsMake(0, 24, 0, 24)];
        objc_setAssociatedObject(swipeTrashButton, XXTESwipeButtonAction, @"Trash", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return @[ swipeTrashButton ];
    }
    return @[];
}

#pragma mark - LGAlertViewDelegate

- (void)alertView:(LGAlertView *)alertView clickedButtonAtIndex:(NSUInteger)index title:(NSString *)title {
    NSString *action = objc_getAssociatedObject(alertView, [XXTExplorerAlertViewAction UTF8String]);
    id obj = objc_getAssociatedObject(alertView, [XXTExplorerAlertViewContext UTF8String]);
    if (action) {
        if ([action isEqualToString:XXTExplorerAlertViewActionPasteboardImport])
        {
            if (index == 0)
                [self alertView:alertView copyPasteboardItemsAtIndexPaths:obj];
        }
        else if ([action isEqualToString:XXTExplorerAlertViewActionPasteboardExport])
        {
            if (index == 0)
                [self alertView:alertView pastePasteboardItemsAtPath:obj];
            else if (index == 1)
                [self alertView:alertView movePasteboardItemsAtPath:obj];
            else if (index == 2)
                [self alertView:alertView symlinkPasteboardItemsAtPath:obj];
        }
    }
}

- (void)alertViewDestructed:(LGAlertView *)alertView {
    SEL selectors[] = {
        @selector(alertView:removeEntryCell:),
        @selector(alertView:removeEntriesAtIndexPaths:),
        @selector(alertView:archiveEntriesAtIndexPaths:),
        @selector(alertView:unarchiveEntryAtIndexPath:),
        @selector(alertView:clearPasteboardEntriesStored:)
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    for (int i = 0; i < sizeof(selectors) / sizeof(SEL); i++) {
        SEL selector = selectors[i];
        id obj = objc_getAssociatedObject(alertView, selector);
        if (obj) {
            [self performSelector:selector withObject:alertView withObject:obj];
            break;
        }
    }
#pragma clang diagnostic pop
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    if (busyOperationProgressFlag) {
        busyOperationProgressFlag = NO;
    } else {
        [alertView dismissAnimated];
    }
}

#pragma mark - AlertView Actions

- (void)alertView:(LGAlertView *)alertView copyPasteboardItemsAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    NSMutableArray <NSString *> *selectedEntryPaths = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        [selectedEntryPaths addObject:self.entryList[indexPath.row][XXTExplorerViewEntryAttributePath]];
    }
    [self.class.explorerPasteboard setStrings:[[NSArray alloc] initWithArray:selectedEntryPaths]];
    [alertView dismissAnimated];
    [self setEditing:NO animated:YES];
}

- (void)alertView:(LGAlertView *)alertView clearPasteboardEntriesStored:(NSArray <NSIndexPath *> *)indexPaths {
    [self.class.explorerPasteboard setStrings:@[]];
    [alertView dismissAnimated];
    [self updateToolbarStatus:self.toolbar];
}

#pragma mark - Busy Operations

- (void)alertView:(LGAlertView *)alertView movePasteboardItemsAtPath:(NSString *)path {
    NSArray <NSString *> *storedPaths = [self.class.explorerPasteboard strings];
    NSUInteger storedCount = storedPaths.count;
    NSMutableArray <NSString *> *storedNames = [[NSMutableArray alloc] initWithCapacity:storedCount];
    for (NSString *storedPath in storedPaths) {
        [storedNames addObject:[storedPath lastPathComponent]];
    }
    NSString *storedDisplayName = nil;
    if (storedCount == 1) {
        storedDisplayName = [NSString stringWithFormat:@"\"%@\"", [storedPaths[0] lastPathComponent]];
    } else {
        storedDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), storedCount];
    }
    NSString *destinationPath = path;
    NSString *destinationName = [destinationPath lastPathComponent];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Move", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Move %@ to \"%@\"", nil), storedDisplayName, destinationName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    NSMutableArray <NSString *> *resultPaths = [[NSMutableArray alloc] initWithCapacity:storedCount];
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [self alertView:alertView1 clearPasteboardEntriesStored:nil];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        if (error) {
            showUserMessage(self.navigationController.view, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
            for (NSUInteger i = 0; i < self.entryList.count; i++) {
                NSDictionary *entryDetail = self.entryList[i];
                BOOL shouldSelect = NO;
                for (NSString *resultPath in resultPaths) {
                    if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:resultPath]) {
                        shouldSelect = YES;
                    }
                }
                if (shouldSelect) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            [self updateToolbarStatus:self.toolbar];
        }
    };
    if (busyOperationProgressFlag) {
        return;
    }
    busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSError *error = nil;
            NSMutableArray <NSString *> *recursiveSubpaths = [[NSMutableArray alloc] initWithArray:storedPaths];
            NSMutableArray <NSString *> *recursiveSubnames = [[NSMutableArray alloc] initWithArray:storedNames];
            while (recursiveSubnames.count != 0) {
                if (error != nil) break;
                NSString *enumPath = [recursiveSubpaths lastObject];
                NSString *enumName = [recursiveSubnames lastObject];
                dispatch_async_on_main_queue(^{
                    callbackBlock(enumPath);
                });
                [recursiveSubpaths removeLastObject];
                [recursiveSubnames removeLastObject];
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:enumName];
                BOOL isDirectory = NO;
                BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                if (!fileExists) {
                    // TODO: pause by non-exists error
                    continue;
                }
                if (fileExists) {
                    NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                        if (isDirectory) {
                            NSArray <NSString *> *groupSubnames = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                            if (groupSubnames.count != 0) {
                                NSMutableArray <NSString *> *groupSubpathsAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                                NSMutableArray <NSString *> *groupSubnamesAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                                for (NSString *groupSubname in groupSubnames) {
                                    [groupSubpathsAppended addObject:[enumPath stringByAppendingPathComponent:groupSubname]];
                                    [groupSubnamesAppended addObject:[enumName stringByAppendingPathComponent:groupSubname]];
                                }
                                BOOL mkdirResult = (mkdir([targetPath fileSystemRepresentation], 0755) == 0);
                                if (!mkdirResult) {
                                    // TODO: pause by mkdir error
                                }
                                [recursiveSubpaths addObject:enumPath];
                                [recursiveSubnames addObject:enumName];
                                [recursiveSubpaths addObjectsFromArray:groupSubpathsAppended];
                                [recursiveSubnames addObjectsFromArray:groupSubnamesAppended];
                            } else {
                                BOOL rmdirResult = (rmdir([enumPath fileSystemRepresentation]) == 0);
                                if (!rmdirResult) {
                                    // TODO: pause by rmdir error
                                }
                            }
                            continue;
                        }
                    }
                }
                BOOL moveResult = [fileManager moveItemAtPath:enumPath toPath:targetPath error:&error];
                if (!moveResult) {
                    // TODO: pause by move error
                    break;
                }
                if (!busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Moving process terminated: User interrupt occurred.", nil) }];
                    break;
                }
            }
            for (NSString *storedName in storedNames) {
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:storedName];
                BOOL isDirectory = NO;
                BOOL exists = [fileManager fileExistsAtPath:targetPath isDirectory:&isDirectory];
                if (exists) {
                    [resultPaths addObject:targetPath];
                }
            }
            BOOL result = (resultPaths.count != 0);
            dispatch_async_on_main_queue(^{
                busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView pastePasteboardItemsAtPath:(NSString *)path {
    NSArray <NSString *> *storedPaths = [self.class.explorerPasteboard strings];
    NSUInteger storedCount = storedPaths.count;
    NSMutableArray <NSString *> *storedNames = [[NSMutableArray alloc] initWithCapacity:storedCount];
    for (NSString *storedPath in storedPaths) {
        [storedNames addObject:[storedPath lastPathComponent]];
    }
    NSString *storedDisplayName = nil;
    if (storedCount == 1) {
        storedDisplayName = [NSString stringWithFormat:@"\"%@\"", [storedPaths[0] lastPathComponent]];
    } else {
        storedDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), storedCount];
    }
    NSString *destinationPath = path;
    NSString *destinationName = [destinationPath lastPathComponent];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Paste", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Paste %@ to \"%@\"", nil), storedDisplayName, destinationName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    NSMutableArray <NSString *> *resultPaths = [[NSMutableArray alloc] initWithCapacity:storedCount];
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        if (error) {
            showUserMessage(self.navigationController.view, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
            for (NSUInteger i = 0; i < self.entryList.count; i++) {
                NSDictionary *entryDetail = self.entryList[i];
                BOOL shouldSelect = NO;
                for (NSString *resultPath in resultPaths) {
                    if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:resultPath]) {
                        shouldSelect = YES;
                    }
                }
                if (shouldSelect) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            [self updateToolbarStatus:self.toolbar];
        }
    };
    if (busyOperationProgressFlag) {
        return;
    }
    busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSError *error = nil;
            NSMutableArray <NSString *> *recursiveSubpaths = [[NSMutableArray alloc] initWithArray:storedPaths];
            NSMutableArray <NSString *> *recursiveSubnames = [[NSMutableArray alloc] initWithArray:storedNames];
            while (recursiveSubnames.count != 0) {
                if (error != nil) break;
                NSString *enumPath = [recursiveSubpaths lastObject];
                NSString *enumName = [recursiveSubnames lastObject];
                dispatch_async_on_main_queue(^{
                    callbackBlock(enumPath);
                });
                [recursiveSubpaths removeLastObject];
                [recursiveSubnames removeLastObject];
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:enumName];
                BOOL isDirectory = NO;
                BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                if (!fileExists) {
                    // TODO: pause by non-exists error
                    continue;
                }
                if (fileExists) {
                    NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                        if (isDirectory) {
                            NSArray <NSString *> *groupSubnames = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                            NSMutableArray <NSString *> *groupSubpathsAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                            NSMutableArray <NSString *> *groupSubnamesAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                            for (NSString *groupSubname in groupSubnames) {
                                [groupSubpathsAppended addObject:[enumPath stringByAppendingPathComponent:groupSubname]];
                                [groupSubnamesAppended addObject:[enumName stringByAppendingPathComponent:groupSubname]];
                            }
                            BOOL mkdirResult = (mkdir([targetPath fileSystemRepresentation], 0755) == 0);
                            if (!mkdirResult) {
                                // TODO: pause by mkdir error
                            }
                            [recursiveSubpaths addObjectsFromArray:groupSubpathsAppended];
                            [recursiveSubnames addObjectsFromArray:groupSubnamesAppended];
                            continue;
                        }
                    }
                }
                BOOL copyResult = [fileManager copyItemAtPath:enumPath toPath:targetPath error:&error];
                if (!copyResult) {
                    // TODO: pause by copy error
                    break;
                }
                if (!busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Pasting process terminated: User interrupt occurred.", nil) }];
                    break;
                }
            }
            for (NSString *storedName in storedNames) {
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:storedName];
                BOOL isDirectory = NO;
                BOOL exists = [fileManager fileExistsAtPath:targetPath isDirectory:&isDirectory];
                if (exists) {
                    [resultPaths addObject:targetPath];
                }
            }
            BOOL result = (resultPaths.count != 0);
            dispatch_async_on_main_queue(^{
                busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView symlinkPasteboardItemsAtPath:(NSString *)path {
    NSArray <NSString *> *storedPaths = [self.class.explorerPasteboard strings];
    NSUInteger storedCount = storedPaths.count;
    NSString *storedDisplayName = nil;
    if (storedCount == 1) {
        storedDisplayName = [NSString stringWithFormat:@"\"%@\"", [storedPaths[0] lastPathComponent]];
    } else {
        storedDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), storedCount];
    }
    NSString *destinationPath = path;
    NSString *destinationName = [destinationPath lastPathComponent];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Link", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Link %@ to \"%@\"", nil), storedDisplayName, destinationName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    NSMutableArray <NSString *> *resultPaths = [[NSMutableArray alloc] initWithCapacity:storedCount];
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        if (error) {
            showUserMessage(self.navigationController.view, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
            for (NSUInteger i = 0; i < self.entryList.count; i++) {
                NSDictionary *entryDetail = self.entryList[i];
                BOOL shouldSelect = NO;
                for (NSString *resultPath in resultPaths) {
                    if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:resultPath]) {
                        shouldSelect = YES;
                    }
                }
                if (shouldSelect) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            [self updateToolbarStatus:self.toolbar];
        }
    };
    if (busyOperationProgressFlag) {
        return;
    }
    busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSError *error = nil;
            for (NSString *storedPath in storedPaths) {
                if (error != nil) break;
                dispatch_async_on_main_queue(^{
                    callbackBlock(storedPath);
                });
                NSString *storedName = [storedPath lastPathComponent];
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:storedName];
                BOOL linkResult = [fileManager createSymbolicLinkAtPath:targetPath withDestinationPath:storedPath error:&error];
                if (!linkResult) {
                    // TODO: pause by link error
                    break;
                }
                [resultPaths addObject:targetPath];
                if (!busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Linking process terminated: User interrupt occurred.", nil) }];
                    break;
                }
            }
            BOOL result = (resultPaths.count != 0);
            dispatch_async_on_main_queue(^{
                busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView removeEntryCell:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    NSString *entryPath = entryDetail[XXTExplorerViewEntryAttributePath];
    NSString *entryName = entryDetail[XXTExplorerViewEntryAttributeName];
    NSUInteger entryCount = 1;
    NSMutableArray <NSIndexPath *> *deletedPaths = [[NSMutableArray alloc] initWithCapacity:entryCount];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Delete", nil)
                                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Deleting \"%@\"", nil), entryName]
                                                                              style:LGAlertViewStyleActionSheet
                                                                  progressLabelText:entryPath
                                                                       buttonTitles:nil
                                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                             destructiveButtonTitle:nil
                                                                           delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self setEditing:NO animated:YES];
        if (error == nil) {
            [self loadEntryListData];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:deletedPaths withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            showUserMessage(self.navigationController.view, [error localizedDescription]);
        }
    };
    if (busyOperationProgressFlag) {
        return;
    }
    busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSError *error = nil;
            NSMutableArray <NSString *> *recursiveSubpaths = [[NSMutableArray alloc] initWithObjects:entryPath, nil];
            while (recursiveSubpaths.count != 0) {
                if (error != nil) break;
                NSString *enumPath = [recursiveSubpaths lastObject];
                dispatch_async_on_main_queue(^{
                    callbackBlock(enumPath);
                });
                [recursiveSubpaths removeLastObject];
                BOOL isDirectory = NO;
                BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                if (fileExists) {
                    NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                        if (isDirectory) {
                            NSArray <NSString *> *groupSubpaths = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                            if (groupSubpaths.count != 0) {
                                NSMutableArray <NSString *> *groupSubpathsAppended = [[NSMutableArray alloc] initWithCapacity:groupSubpaths.count];
                                for (NSString *groupSubpath in groupSubpaths) {
                                    [groupSubpathsAppended addObject:[enumPath stringByAppendingPathComponent:groupSubpath]];
                                }
                                [recursiveSubpaths addObject:enumPath];
                                [recursiveSubpaths addObjectsFromArray:groupSubpathsAppended];
                                continue;
                            }
                        }
                    }
                }
                BOOL removeResult = [fileManager removeItemAtPath:enumPath error:&error];
                if (!removeResult) {
                    // TODO: pause by remove error
                }
                if (!busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Removing process terminated: User interrupt occurred.", nil) }];
                    break;
                }
            }
            if ([fileManager fileExistsAtPath:entryPath] == NO) {
                [deletedPaths addObject:indexPath];
            }
            BOOL result = (deletedPaths.count != 0);
            dispatch_async_on_main_queue(^{
                busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView removeEntriesAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    NSMutableArray <NSString *> *entryPaths = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        [entryPaths addObject:self.entryList[indexPath.row][XXTExplorerViewEntryAttributePath]];
    }
    NSUInteger entryCount = entryPaths.count;
    NSMutableArray <NSIndexPath *> *deletedPaths = [[NSMutableArray alloc] initWithCapacity:entryCount];
    NSString *entryDisplayName = nil;
    if (entryCount == 1) {
        entryDisplayName = [NSString stringWithFormat:@"\"%@\"", [entryPaths[0] lastPathComponent]];
    } else {
        entryDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), entryPaths.count];
    }
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Delete", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Deleting %@", nil), entryDisplayName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self setEditing:NO animated:YES];
        if (error == nil) {
            [self loadEntryListData];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:deletedPaths withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            showUserMessage(self.navigationController.view, [error localizedDescription]);
        }
    };
    if (busyOperationProgressFlag) {
        return;
    }
    busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSMutableArray <NSString *> *recursiveSubpaths = [[NSMutableArray alloc] initWithArray:entryPaths];
            NSError *error = nil;
            while (recursiveSubpaths.count != 0) {
                if (error != nil) break;
                NSString *enumPath = [recursiveSubpaths lastObject];
                dispatch_async_on_main_queue(^{
                    callbackBlock(enumPath);
                });
                [recursiveSubpaths removeLastObject];
                
                BOOL isDirectory = NO;
                BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                if (fileExists) {
                    NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                        if (isDirectory) {
                            NSArray <NSString *> *groupSubpaths = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                            if (groupSubpaths.count != 0) {
                                NSMutableArray <NSString *> *groupSubpathsAppended = [[NSMutableArray alloc] initWithCapacity:groupSubpaths.count];
                                for (NSString *groupSubpath in groupSubpaths) {
                                    [groupSubpathsAppended addObject:[enumPath stringByAppendingPathComponent:groupSubpath]];
                                }
                                [recursiveSubpaths addObject:enumPath];
                                [recursiveSubpaths addObjectsFromArray:groupSubpathsAppended];
                                continue;
                            }
                        }
                    }
                }
                BOOL removeResult = [fileManager removeItemAtPath:enumPath error:&error];
                if (!removeResult) {
                    // TODO: pause by remove error
                }
                if (!busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Removing process terminated: User interrupt occurred.", nil) }];
                    break;
                }
            }
            for (NSUInteger i = 0; i < entryPaths.count; i++) {
                NSString *entryPath = entryPaths[i];
                if ([fileManager fileExistsAtPath:entryPath] == NO) {
                    [deletedPaths addObject:indexPaths[i]];
                }
            }
            BOOL result = (deletedPaths.count != 0);
            dispatch_async_on_main_queue(^{
                busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView archiveEntriesAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    NSString *currentPath = self.entryPath;
    NSMutableArray <NSString *> *entryNames = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        [entryNames addObject:self.entryList[indexPath.row][XXTExplorerViewEntryAttributeName]];
    }
    NSUInteger entryCount = entryNames.count;
    NSString *entryDisplayName = nil;
    NSString *archiveName = nil;
    if (entryCount == 1) {
        archiveName = entryNames[0];
        entryDisplayName = [NSString stringWithFormat:@"\"%@\"", archiveName];
    } else {
        archiveName = @"Archive";
        entryDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), entryNames.count];
    }
    NSString *archiveNameWithExt = [NSString stringWithFormat:@"%@.zip", archiveName];
    NSString *archivePath = [currentPath stringByAppendingPathComponent:archiveNameWithExt];
    NSUInteger archiveIndex = 2;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    while ([fileManager fileExistsAtPath:archivePath])
    {
        archiveNameWithExt = [NSString stringWithFormat:@"%@-%lu.zip", archiveName, (unsigned long)archiveIndex];
        archivePath = [currentPath stringByAppendingPathComponent:archiveNameWithExt];
        archiveIndex++;
    }
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Archive", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Archive %@ to \"%@\"", nil), entryDisplayName, archiveNameWithExt]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        [self setEditing:YES animated:YES];
        for (NSUInteger i = 0; i < self.entryList.count; i++) {
            NSDictionary *entryDetail = self.entryList[i];
            if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:archivePath]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                break;
            }
        }
        [self updateToolbarStatus:self.toolbar];
        if (error) {
            showUserMessage(self.navigationController.view, [error localizedDescription]);
        }
    };
    if (busyOperationProgressFlag) {
        return;
    }
    busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            struct zip_t *zip = zip_open([archivePath fileSystemRepresentation], ZIP_DEFAULT_COMPRESSION_LEVEL, 'w');
            NSError *error = nil;
            BOOL result = (zip != NULL);
            if (NO == result) {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot create archive file \"%@\".", nil), archivePath] }];
            }
            else
            {
                NSMutableArray <NSString *> *recursiveSubnames = [[NSMutableArray alloc] initWithArray:entryNames];
                while (recursiveSubnames.count != 0) {
                    if (error != nil) break;
                    NSString *enumName = [recursiveSubnames lastObject];
                    NSString *enumPath = [currentPath stringByAppendingPathComponent:enumName];
                    dispatch_async_on_main_queue(^{
                        callbackBlock(enumPath);
                    });
                    [recursiveSubnames removeLastObject];
                    BOOL isDirectory = NO;
                    BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                    if (fileExists) {
                        NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                        if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                            if (isDirectory) {
                                NSArray <NSString *> *groupSubnames = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                                if (groupSubnames.count == 0) {
                                    enumName = [enumName stringByAppendingString:@"/"];
                                } else {
                                    NSMutableArray <NSString *> *groupSubnamesAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                                    for (NSString *groupSubname in groupSubnames) {
                                        [groupSubnamesAppended addObject:[enumName stringByAppendingPathComponent:groupSubname]];
                                    }
                                    [recursiveSubnames addObjectsFromArray:groupSubnamesAppended];
                                    continue;
                                }
                            }
                        }
                    }
                    int open_result = zip_entry_open(zip, [enumName fileSystemRepresentation]);
                    {
                        zip_entry_fwrite(zip, [enumPath fileSystemRepresentation]);
                    }
                    int close_result = zip_entry_close(zip);
                    if (open_result != 0 || close_result != 0) {
                        // TODO: pause by archive error
                    }
                    if (!busyOperationProgressFlag) {
                        error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Archiving process terminated: User interrupt occurred.", nil) }];
                        break;
                    }
                }
                zip_close(zip);
            }
            dispatch_async_on_main_queue(^{
                busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView unarchiveEntryAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entryAttributes = self.entryList[indexPath.row];
    NSString *entryName = entryAttributes[XXTExplorerViewEntryAttributeName];
    NSString *entryPath = entryAttributes[XXTExplorerViewEntryAttributePath];
    NSString *destinationPath = [entryPath stringByDeletingPathExtension];
    NSString *destinationPathWithIndex = destinationPath;
    NSUInteger destinationIndex = 2;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    while ([fileManager fileExistsAtPath:destinationPathWithIndex])
    {
        destinationPathWithIndex = [NSString stringWithFormat:@"%@-%lu", destinationPath, (unsigned long)destinationIndex];
        destinationIndex++;
    }
    NSString *destinationName = [destinationPathWithIndex lastPathComponent];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Unarchive", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Unarchiving \"%@\" to \"%@\"", nil), entryName, destinationName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:entryPath
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        [self setEditing:YES animated:YES];
        for (NSUInteger i = 0; i < self.entryList.count; i++) {
            NSDictionary *entryDetail = self.entryList[i];
            if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:destinationPathWithIndex]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                break;
            }
        }
        [self updateToolbarStatus:self.toolbar];
        if (error) {
            showUserMessage(self.navigationController.view, [error localizedDescription]);
        }
    };
    if (busyOperationProgressFlag) {
        return;
    }
    busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            const char *extractFrom = [entryPath fileSystemRepresentation];
            const char *extractTo = [destinationPathWithIndex fileSystemRepresentation];
            NSError *error = nil;
            BOOL result = (mkdir(extractTo, 0755) == 0);
            if (NO == result) {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot create destination directory \"%@\".", nil), destinationPathWithIndex] }];
            }
            else
            {
                int (^extract_callback)(const char *, void *) = ^int (const char *filename, void *arg) {
                    dispatch_async_on_main_queue(^{
                        callbackBlock([NSString stringWithUTF8String:filename]);
                    });
                    if (!busyOperationProgressFlag) {
                        return -1;
                    }
                    return 0;
                };
                int arg = 2;
                int status = zip_extract(extractFrom, extractTo, extract_callback, &arg);
                result = (status == 0);
                if (NO == result) {
                    if (!busyOperationProgressFlag) {
                        error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Unarchiving process terminated: User interrupt occurred.", nil) }];
                    } else {
                        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:status userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot read archive file \"%@\".", nil), entryPath] }];
                    }
                }
            }
            dispatch_async_on_main_queue(^{
                busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTExplorerViewController dealloc]");
#endif
}

@end
