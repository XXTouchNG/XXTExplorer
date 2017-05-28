//
//  XXTExplorerViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import "XXTExplorerViewController.h"
#import "XXTExplorerHeaderView.h"
#import "XXTExplorerFooterView.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerToolbar.h"
#import "UIView+XXTEToast.h"

typedef enum : NSUInteger {
    XXTExplorerViewSectionIndexHome = 0,
    XXTExplorerViewSectionIndexList,
    XXTExplorerViewSectionIndexMax
} XXTExplorerViewSectionIndex;

#define XXTEDefaultsBool(key) ([[self.explorerDefaults objectForKey:key] boolValue])
#define XXTEDefaultsEnum(key) ([[self.explorerDefaults objectForKey:key] unsignedIntegerValue])
#define XXTEDefaultsObject(key) ([self.explorerDefaults objectForKey:key])
#define XXTEDefaultsSetBasic(key, value) ([self.explorerDefaults setObject:@(value) forKey:key])
#define XXTEDefaultsSetObject(key, obj) ([self.explorerDefaults setObject:obj forKey:key])

@interface XXTExplorerViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, XXTExplorerToolbarDelegate>

@property (nonatomic, strong, readonly) NSFileManager *explorerFileManager;
@property (nonatomic, strong, readonly) NSDateFormatter *explorerDateFormatter;
@property (nonatomic, assign, readonly) NSUserDefaults *explorerDefaults; // u can use NSDictionary instead.

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *entryList;

@property (nonatomic, strong, readonly) XXTExplorerToolbar *toolbar;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) XXTExplorerFooterView *footerView;

@end

@implementation XXTExplorerViewController

+ (NSMutableArray <NSDictionary *> *)explorerPasteboard {
    static NSMutableArray *explorerPasteboard = nil;
    if (!explorerPasteboard) {
        explorerPasteboard = [[NSMutableArray alloc] init];
    }
    return explorerPasteboard;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithEntryPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        _explorerFileManager = [[NSFileManager alloc] init];
        _explorerDateFormatter = ({
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            dateFormatter;
        });
        _explorerDefaults = [NSUserDefaults standardUserDefaults];
        NSString *defaultSettingsPath = [[NSBundle mainBundle] pathForResource:@"XXTExplorerDefaults" ofType:@"plist"];
        NSDictionary *defaultSettings = [[NSDictionary alloc] initWithContentsOfFile:defaultSettingsPath];
        for (NSString *defaultKey in defaultSettings) {
            if (![self.explorerDefaults objectForKey:defaultKey])
            {
                [self.explorerDefaults setObject:defaultSettings[defaultKey] forKey:defaultKey];
            }
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = [self.entryPath lastPathComponent];
    
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
    [self updateToolbarButton:self.toolbar];
    [self updateToolbarStatus:self.toolbar];
    [self reloadEntryListView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self isEditing]) {
        [self setEditing:NO animated:YES];
    }
}

#pragma mark - Toolbar Status

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
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste status:nil enabled:YES];
    }
    else
    {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste status:nil enabled:NO];
    }
    if ([self isEditing])
    {
        if (([self.tableView indexPathsForSelectedRows].count) > 0)
        {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeShare status:nil enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeCompress status:nil enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash status:nil enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste status:nil enabled:YES];
        }
        else
        {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeShare status:nil enabled:NO];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeCompress status:nil enabled:NO];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash status:nil enabled:NO];
        }
    }
    else
    {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeScan status:nil enabled:YES];
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeAddItem status:nil enabled:YES];
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort status:nil enabled:YES];
    }
}

#pragma mark - File Management

- (void)reloadEntryListDataWithError:(NSError **)error
{
    _entryList = ({
        NSError *localError = nil;
        NSArray <NSString *> *entrySubdirectoryPathList = [self.explorerFileManager contentsOfDirectoryAtPath:self.entryPath error:&localError];
        if (localError && error) *error = localError;
        NSMutableArray <NSDictionary *> *entryDirectoryAttributesList = [[NSMutableArray alloc] init];
        NSMutableArray <NSDictionary *> *entryOtherAttributesList = [[NSMutableArray alloc] init];
        for (NSString *entrySubdirectoryName in entrySubdirectoryPathList)
        {
            NSString *entrySubdirectoryPath = [self.entryPath stringByAppendingPathComponent:entrySubdirectoryName];
            NSDictionary <NSString *, id> *entrySubdirectoryAttributes = [self.explorerFileManager attributesOfItemAtPath:entrySubdirectoryPath error:&localError];
            if (localError && error)
            {
                *error = localError;
                break;
            }
            NSString *entryNSFileType = entrySubdirectoryAttributes[NSFileType];
            NSString *entryBaseName = [entrySubdirectoryPath lastPathComponent];
            NSString *entryBaseExtension = [entryBaseName pathExtension];
            UIImage *entryIconImage = nil;
            NSString *entryBaseType = nil;
            if ([entryNSFileType isEqualToString:NSFileTypeRegular])
            {
                entryBaseType = XXTExplorerViewEntryAttributeTypeRegular;
            }
            else if ([entryNSFileType isEqualToString:NSFileTypeDirectory])
            {
                entryBaseType = XXTExplorerViewEntryAttributeTypeDirectory;
            }
            else if ([entryNSFileType isEqualToString:NSFileTypeSymbolicLink])
            {
                entryBaseType = XXTExplorerViewEntryAttributeTypeSymlink;
            }
            else {
                entryBaseType = XXTExplorerViewEntryAttributeTypeUnsupported;
            }
            NSString *entryRealType = entryBaseType;
            if ([entryBaseType isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink])
            {
                const char *entrySubdirectoryPathCString = [entrySubdirectoryPath UTF8String];
                struct stat entrySubdirectoryPathCStatStruct;
                bzero(&entrySubdirectoryPathCStatStruct, sizeof(struct stat));
                if (0 == stat(entrySubdirectoryPathCString, &entrySubdirectoryPathCStatStruct))
                {
                    if (S_ISDIR(entrySubdirectoryPathCStatStruct.st_mode))
                    {
                        entryRealType = XXTExplorerViewEntryAttributeTypeDirectory;
                    }
                    else if (S_ISREG(entrySubdirectoryPathCStatStruct.st_mode))
                    {
                        entryRealType = XXTExplorerViewEntryAttributeTypeRegular;
                    }
                    else
                    {
                        entryRealType = XXTExplorerViewEntryAttributeTypeUnsupported;
                    }
                }
            }
            if ([entryRealType isEqualToString:XXTExplorerViewEntryAttributeTypeRegular])
            {
                entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeRegular];
            }
            else if ([entryRealType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
            {
                entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeDirectory];
            }
            else if ([entryRealType isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink])
            {
                entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeSymlink];
            }
            else
            {
                entryIconImage = [UIImage imageNamed:XXTExplorerViewEntryAttributeTypeUnsupported];
            }
            NSDictionary *entryAttributes =
                @{
                  XXTExplorerViewEntryAttributeIconImage: entryIconImage,
                  XXTExplorerViewEntryAttributeDisplayName: entryBaseName,
                  XXTExplorerViewEntryAttributeName: entryBaseName,
                  XXTExplorerViewEntryAttributePath: entrySubdirectoryPath,
//                  XXTExplorerViewEntryAttributeRealPath: entrySubdirectoryPath,
                  XXTExplorerViewEntryAttributeCreationDate: entrySubdirectoryAttributes[NSFileCreationDate],
                  XXTExplorerViewEntryAttributeModificationDate: entrySubdirectoryAttributes[NSFileModificationDate],
                  XXTExplorerViewEntryAttributeSize: entrySubdirectoryAttributes[NSFileSize],
                  XXTExplorerViewEntryAttributeType: entryBaseType,
                  XXTExplorerViewEntryAttributeRealType: entryRealType,
                  XXTExplorerViewEntryAttributeExtension: entryBaseExtension
                  };
            // TODO: Parse bundle
            // TODO: Parse each entry using XXTExplorerEntryExtensions
            if ([entryRealType isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory])
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
    NSDictionary *fileSystemAttributes = [self.explorerFileManager attributesOfFileSystemForPath:self.entryPath error:&usageError];
    if (!usageError) {
        NSNumber *deviceFreeSpace = fileSystemAttributes[NSFileSystemFreeSize];
        if (deviceFreeSpace) {
            usageString = [NSByteCountFormatter stringFromByteCount:[deviceFreeSpace unsignedLongLongValue] countStyle:NSByteCountFormatterCountStyleFile];
        }
    }
    NSString *finalFooterString = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ free", nil), itemCountString, usageString];
    [self.footerView.footerLabel setText:finalFooterString];
}

- (void)loadEntryListView
{
    NSError *entryLoadError = nil;
    [self reloadEntryListDataWithError:&entryLoadError];
    if (entryLoadError) {
        [self.navigationController.view makeToast:[entryLoadError localizedDescription]];
    }
}

- (void)reloadEntryListView // (load + tableView reload)
{
    [self loadEntryListView];
    [self.tableView reloadData];
}

- (void)refreshEntryListView:(UIRefreshControl *)refreshControl {
    [self reloadEntryListView];
    if ([refreshControl isRefreshing]) {
        [refreshControl endRefreshing];
    }
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (XXTExplorerViewSectionIndexList == indexPath.section)
    {
        return YES;
    }
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (XXTExplorerViewSectionIndexList == indexPath.section) {
        return indexPath;
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
    if ([tableView isEditing]) {
        [self updateToolbarStatus:self.toolbar];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEditing]) {
        [self updateToolbarStatus:self.toolbar];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (tableView == self.tableView) {
            if (XXTExplorerViewSectionIndexList == indexPath.section) {
                NSDictionary *entryAttributes = self.entryList[indexPath.row];
                if ([entryAttributes[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory] ||
                    ([entryAttributes[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeSymlink] &&
                     [entryAttributes[XXTExplorerViewEntryAttributeRealType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory]))
                { // Directory or Symbolic Link Directory
                    NSString *directoryPath = entryAttributes[XXTExplorerViewEntryAttributePath];
                    // We'd better try to access it before we enter it.
                    NSError *accessError = nil;
                    [self.explorerFileManager contentsOfDirectoryAtPath:directoryPath error:&accessError];
                    if (accessError) {
                        [self.navigationController.view makeToast:[accessError localizedDescription]];
                    }
                    else {
                        XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:directoryPath];
                        [self.navigationController pushViewController:explorerViewController animated:YES];
                    }
                }
            }
            // TODO: We have no actions for Home section
        }
    }
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            return XXTExplorerViewCellHeight;
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            // TODO: Home section may have different cell height.
            return 0;
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return XXTExplorerViewSectionIndexMax;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexHome == section) {
            if (XXTEDefaultsBool(XXTExplorerViewSectionHomeEnabledKey)) {
                // TODO: There might be serval shortcuts in Home section, more than 1.
                return 1;
            } else {
                return 0;
            }
        }
        else if (XXTExplorerViewSectionIndexList == section) {
            return self.entryList.count;
        }
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
            [entryHeaderView.headerLabel setText:self.entryPath];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            XXTExplorerViewCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewCellReuseIdentifier];
            if (!entryCell) {
                entryCell = [[XXTExplorerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewCellReuseIdentifier];
            }
            entryCell.entryIconImageView.image = self.entryList[indexPath.row][XXTExplorerViewEntryAttributeIconImage];
            entryCell.entryTitleLabel.text = self.entryList[indexPath.row][XXTExplorerViewEntryAttributeName];
            entryCell.entrySubtitleLabel.text = [self.explorerDateFormatter stringFromDate:self.entryList[indexPath.row][XXTExplorerViewEntryAttributeCreationDate]];
            UILongPressGestureRecognizer *cellLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(entryCellDidLongPress:)];
            cellLongPressGesture.delegate = self;
            [entryCell addGestureRecognizer:cellLongPressGesture];
            return entryCell;
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            // TODO: Home section may have different cell, with another style of subtitles and icons.
        }
    }
    return [UITableViewCell new];
}

#pragma mark - Long Press Gesture

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
            [self reloadEntryListView];
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
            
        }
    }
}

#pragma mark - UIViewControllerEditing

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

@end
