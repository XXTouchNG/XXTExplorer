//
//  XXTExplorerViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"
#import "XXTExplorerHeaderView.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerDefaults.h"
#import "UIView+XXTEToast.h"

typedef enum : NSUInteger {
    XXTExplorerViewSectionIndexHome = 0,
    XXTExplorerViewSectionIndexList,
    XXTExplorerViewSectionIndexMax
} XXTExplorerViewSectionIndex;

#define XXTEDefaultsBool(key) ([[self.explorerDefaults objectForKey:key] boolValue])
#define XXTEDefaultsEnum(key) ([[self.explorerDefaults objectForKey:key] unsignedIntegerValue])
#define XXTEDefaultsObject(key) ([self.explorerDefaults objectForKey:key])

@interface XXTExplorerViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) NSFileManager *explorerFileManager;
@property (nonatomic, strong, readonly) NSDateFormatter *explorerDateFormatter;
@property (nonatomic, assign, readonly) NSUserDefaults *explorerDefaults; // u can use NSDictionary instead.

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *entryList;

@property (nonatomic, strong, readonly) UITableView *tableView;

@end

@implementation XXTExplorerViewController

- (instancetype)initWithEntryPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        _explorerFileManager = [[NSFileManager alloc] init];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        _explorerDateFormatter = dateFormatter;
        _explorerDefaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = [self.entryPath lastPathComponent];
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        XXTE_START_IGNORE_PARTIAL
        if (XXTE_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewCellReuseIdentifier];
        tableView;
    });
    
    [self.view addSubview:self.tableView];
    
    [self loadEntryListView];
}

#pragma mark - File Management

- (void)reloadEntryListDataWithError:(NSError **)error
{
    _entryList = ({
        NSError *localError = nil;
        NSArray <NSString *> *entrySubdirectoryPathList = [self.explorerFileManager contentsOfDirectoryAtPath:self.entryPath error:&localError];
        if (localError && error) *error = localError;
        NSMutableArray <NSDictionary *> *entryAttributesList = [[NSMutableArray alloc] initWithCapacity:entrySubdirectoryPathList.count];
        for (NSString *entrySubdirectoryName in entrySubdirectoryPathList) {
            NSString *entrySubdirectoryPath = [self.entryPath stringByAppendingPathComponent:entrySubdirectoryName];
            NSDictionary <NSString *, id> *entrySubdirectoryAttributes = [self.explorerFileManager attributesOfItemAtPath:entrySubdirectoryPath error:&localError];
            if (localError && error) {
                *error = localError;
                break;
            }
            NSString *entryNSFileType = entrySubdirectoryAttributes[NSFileType];
            NSString *entryBaseName = [entrySubdirectoryPath lastPathComponent];
            NSString *entryBaseType = nil;
            if ([entryNSFileType isEqualToString:NSFileTypeRegular]) {
                entryBaseType = XXTExplorerViewEntryAttributeTypeRegular;
            }
            else if ([entryNSFileType isEqualToString:NSFileTypeDirectory]) {
                entryBaseType = XXTExplorerViewEntryAttributeTypeDirectory;
            }
            else if ([entryNSFileType isEqualToString:NSFileTypeSymbolicLink]) {
                entryBaseType = XXTExplorerViewEntryAttributeTypeSymlink;
            }
            else {
                entryBaseType = XXTExplorerViewEntryAttributeTypeUnsupported;
            }
            // TODO: We need a default icon for each entry
            NSDictionary *entryAttributes =
                @{
                  XXTExplorerViewEntryAttributeDisplayName: entryBaseName,
                  XXTExplorerViewEntryAttributeName: entryBaseName,
                  XXTExplorerViewEntryAttributePath: entrySubdirectoryPath,
                  XXTExplorerViewEntryAttributeRealPath: entrySubdirectoryPath,
                  XXTExplorerViewEntryAttributeCreationDate: entrySubdirectoryAttributes[NSFileCreationDate],
                  XXTExplorerViewEntryAttributeModificationDate: entrySubdirectoryAttributes[NSFileModificationDate],
                  XXTExplorerViewEntryAttributeSize: entrySubdirectoryAttributes[NSFileSize],
                  XXTExplorerViewEntryAttributeType: entryBaseType,
                  XXTExplorerViewEntryAttributeRealType: entryBaseType,
                  };
            // TODO: Parse symbolic link
            // TODO: Parse bundle
            // TODO: Parse each entry using XXTExplorerEntryExtensions
            [entryAttributesList addObject:entryAttributes];
        }
        // TODO: Sort entry list
        entryAttributesList;
    });
    if (error && *error) _entryList = @[]; // clean entry list if error exists
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // TODO: We have no edit mode for now.
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (XXTExplorerViewSectionIndexList == indexPath.section) {
            XXTExplorerViewCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewCellReuseIdentifier];
            if (!entryCell) {
                entryCell = [[XXTExplorerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewCellReuseIdentifier];
            }
            entryCell.entryTitleLabel.text = self.entryList[indexPath.row][XXTExplorerViewEntryAttributeName];
            entryCell.entrySubtitleLabel.text = [self.explorerDateFormatter stringFromDate:self.entryList[indexPath.row][XXTExplorerViewEntryAttributeModificationDate]];
            return entryCell;
        }
        else if (XXTExplorerViewSectionIndexHome == indexPath.section) {
            // TODO: Home section may have different cell, with another style of subtitles and icons.
        }
    }
    return [UITableViewCell new];
}

@end
