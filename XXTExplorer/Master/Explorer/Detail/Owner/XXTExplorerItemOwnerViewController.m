//
//  XXTExplorerItemOwnerViewController.m
//  XXTExplorer
//
//  Created by Zheng on 08/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTExplorerItemOwnerViewController.h"

#import "XXTEMoreSwitchCell.h"
#import "XXTEMoreTitleValueCell.h"

#import <pwd.h>
#import <grp.h>
#import <sys/stat.h>

typedef enum : NSUInteger {
    kXXTEOwnerTypeApply = 0,
    kXXTEOwnerTypeList,
    kXXTEOwnerTypeMax
} kXXTEOwnerType;

@interface XXTExplorerItemOwner : NSObject

@property (nonatomic, copy) NSString *ownerName;
@property (nonatomic, assign) uid_t ownerID;

@end

@implementation XXTExplorerItemOwner

@end


@interface XXTExplorerItemOwnerViewController ()

@property (nonatomic, strong) UIBarButtonItem *saveItem;
@property (nonatomic, strong) NSArray <XXTExplorerItemOwner *> *itemOwners;
@property (nonatomic, strong) XXTEMoreSwitchCell *applyCell;

@property (nonatomic, assign) pid_t currentOwnerID;
@property (nonatomic, assign) pid_t currentGroupID;

@end

@implementation XXTExplorerItemOwnerViewController

#pragma mark - Setup

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _entryPath = path;
        [self setup];
    }
    return self;
}

#define GRPSIZ 255

- (void)setup {
    NSMutableArray <XXTExplorerItemOwner *> *owners = [[NSMutableArray alloc] init];
    NSMutableArray <NSString *> *ownerNames = [[NSMutableArray alloc] init];
    gid_t group_buf[GRPSIZ];
    int num_groups = getgroups(GRPSIZ, group_buf);
    for (int i = 0; i < num_groups; i++) {
        struct group *entryGRInfo = getgrgid(group_buf[i]);
        if (entryGRInfo && entryGRInfo->gr_name) {
            int i = 0;
            while (entryGRInfo->gr_mem[i]) {
                char *member = entryGRInfo->gr_mem[i++];
                if (member) {
                    NSString *memberName = [[NSString alloc] initWithUTF8String:member];
                    if (![ownerNames containsObject:memberName]) {
                        [ownerNames addObject:memberName];
                        struct passwd *owner_wd = getpwnam(member);
                        if (owner_wd && owner_wd->pw_name && owner_wd->pw_uid) {
                            XXTExplorerItemOwner *owner = [[XXTExplorerItemOwner alloc] init];
                            owner.ownerID = owner_wd->pw_uid;
                            owner.ownerName = memberName;
                            [owners addObject:owner];
                        }
                    }
                }
            }
        }
    }
    _itemOwners = [owners copy];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreSwitchCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreSwitchCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreTitleValueCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.navigationItem.rightBarButtonItem = self.saveItem;
    
    XXTEMoreSwitchCell *cell_s = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell_s.titleLabel.text = NSLocalizedString(@"Apply Recursively", nil);
    _applyCell = cell_s;
    
    [self reloadOwnerStatus];
}

- (void)reloadOwnerStatus {
    NSString *entryPath = self.entryPath;
    struct stat entryStat;
    if (lstat([entryPath UTF8String], &entryStat) != 0) return;
    _currentOwnerID = entryStat.st_uid;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTEOwnerTypeMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == kXXTEOwnerTypeList) {
            return self.itemOwners.count;
        } else if (section == kXXTEOwnerTypeApply) {
            return 1;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        
    }
    return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEOwnerTypeList) {
            NSUInteger idx = indexPath.row;
            _currentOwnerID = self.itemOwners[idx].ownerID;
            for (NSIndexPath *vIndexPath in tableView.indexPathsForVisibleRows) {
                if (vIndexPath.section == kXXTEOwnerTypeList) {
                    [self tableView:tableView configureTitleValueCell:nil atIndexPath:vIndexPath];
                }
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEOwnerTypeList) {
            XXTEMoreTitleValueCell *cell =
            [tableView dequeueReusableCellWithIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
            if (nil == cell)
            {
                cell = [[XXTEMoreTitleValueCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
            }
            [self tableView:tableView configureTitleValueCell:cell atIndexPath:indexPath];
            return cell;
        } else if (indexPath.section == kXXTEOwnerTypeApply) {
            return self.applyCell;
        }
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView configureTitleValueCell:(XXTEMoreTitleValueCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kXXTEOwnerTypeList) {
        if (!cell)
        {
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }
        cell.titleLabel.text = self.itemOwners[indexPath.row].ownerName;
        if (self.currentOwnerID == self.itemOwners[indexPath.row].ownerID) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

#pragma mark - UIView Getter

- (UIBarButtonItem *)saveItem {
    if (!_saveItem) {
        _saveItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveItemTapped:)];
    }
    return _saveItem;
}

- (void)saveItemTapped:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldApplyRecursively {
    return self.applyCell.optionSwitch.on;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTExplorerItemOwnerViewController dealloc]");
#endif
}

@end

