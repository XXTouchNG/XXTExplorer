//
//  XXTExplorerPermissionViewController.m
//  XXTExplorer
//
//  Created by Zheng on 08/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTExplorerPermissionViewController.h"

typedef enum : NSUInteger {
    kXXTEPermissionTypeApply = 0,
    kXXTEPermissionTypeOwner,
    kXXTEPermissionTypeGroup,
    kXXTEPermissionTypeEveryone,
    kXXTEPermissionTypeSpecial,
    kXXTEPermissionTypeMax
} kXXTEPermissionType;

#import <pwd.h>
#import <grp.h>
#import <sys/stat.h>

#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreSwitchCell.h"

@interface XXTExplorerPermissionViewController ()

@property (nonatomic, strong) UIBarButtonItem *saveItem;
@property (nonatomic, strong) XXTEMoreSwitchCell *applyCell;

@end

@implementation XXTExplorerPermissionViewController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
}

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

- (void)setup {
    
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    self.navigationItem.rightBarButtonItem = self.saveItem;
    
    [self reloadStaticTableViewData];
    [self reloadPermissionStatus];
}

- (void)reloadStaticTableViewData {
    
    XXTEMoreSwitchCell *cell_s = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell_s.titleLabel.text = NSLocalizedString(@"Apply Recursively", nil);
    _applyCell = cell_s;
    
    XXTEMoreTitleValueCell *cell1_1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1_1.titleLabel.text = NSLocalizedString(@"Read", nil);
    
    XXTEMoreTitleValueCell *cell1_2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1_2.titleLabel.text = NSLocalizedString(@"Write", nil);
    
    XXTEMoreTitleValueCell *cell1_4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1_4.titleLabel.text = NSLocalizedString(@"Execute", nil);
    
    XXTEMoreTitleValueCell *cell2_1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2_1.titleLabel.text = NSLocalizedString(@"Read", nil);
    
    XXTEMoreTitleValueCell *cell2_2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2_2.titleLabel.text = NSLocalizedString(@"Write", nil);
    
    XXTEMoreTitleValueCell *cell2_4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2_4.titleLabel.text = NSLocalizedString(@"Execute", nil);
    
    XXTEMoreTitleValueCell *cell3_1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3_1.titleLabel.text = NSLocalizedString(@"Read", nil);
    
    XXTEMoreTitleValueCell *cell3_2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3_2.titleLabel.text = NSLocalizedString(@"Write", nil);
    
    XXTEMoreTitleValueCell *cell3_4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3_4.titleLabel.text = NSLocalizedString(@"Execute", nil);
    
    XXTEMoreTitleValueCell *cell4_1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4_1.titleLabel.text = NSLocalizedString(@"Sticky", nil);
    
    XXTEMoreTitleValueCell *cell4_2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4_2.titleLabel.text = NSLocalizedString(@"Set GID", nil);
    
    XXTEMoreTitleValueCell *cell4_4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4_4.titleLabel.text = NSLocalizedString(@"Set UID", nil);
    
    staticCells = @[
                    @[ cell_s ],
                    @[ cell1_1, cell1_2, cell1_4 ],
                    @[ cell2_1, cell2_2, cell2_4 ],
                    @[ cell3_1, cell3_2, cell3_4 ],
                    @[ cell4_1, cell4_2, cell4_4 ],
                    ];
    staticSectionTitles = @[
                            @"", NSLocalizedString(@"Owner", nil), NSLocalizedString(@"Group", nil), NSLocalizedString(@"Everyone", nil), NSLocalizedString(@"Special", nil),
                            ];
    staticSectionFooters = @[
                             @"", @"", @"", @"", @""
                             ];
    
}

#define SetCellCheckmark(section, idx, flag) (staticCells[section][idx].accessoryType = flag ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone)

- (void)reloadPermissionStatus {
    NSString *entryPath = self.entryPath;
    struct stat entryStat;
    if (lstat([entryPath UTF8String], &entryStat) != 0) return;
    
    SetCellCheckmark(kXXTEPermissionTypeOwner, 0, entryStat.st_mode & S_IRUSR);
    SetCellCheckmark(kXXTEPermissionTypeOwner, 1, entryStat.st_mode & S_IWUSR);
    SetCellCheckmark(kXXTEPermissionTypeOwner, 2, entryStat.st_mode & S_IXUSR);
    
    SetCellCheckmark(kXXTEPermissionTypeGroup, 0, entryStat.st_mode & S_IRGRP);
    SetCellCheckmark(kXXTEPermissionTypeGroup, 1, entryStat.st_mode & S_IWGRP);
    SetCellCheckmark(kXXTEPermissionTypeGroup, 2, entryStat.st_mode & S_IXGRP);
    
    SetCellCheckmark(kXXTEPermissionTypeEveryone, 0, entryStat.st_mode & S_IROTH);
    SetCellCheckmark(kXXTEPermissionTypeEveryone, 1, entryStat.st_mode & S_IWOTH);
    SetCellCheckmark(kXXTEPermissionTypeEveryone, 2, entryStat.st_mode & S_IXOTH);
    
    SetCellCheckmark(kXXTEPermissionTypeSpecial, 0, entryStat.st_mode & S_ISVTX);
    SetCellCheckmark(kXXTEPermissionTypeSpecial, 1, entryStat.st_mode & S_ISGID);
    SetCellCheckmark(kXXTEPermissionTypeSpecial, 2, entryStat.st_mode & S_ISUID);
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTEPermissionTypeMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticCells[(NSUInteger) section].count;
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
        
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionTitles[(NSUInteger) section];
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionFooters[(NSUInteger) section];
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        UITableViewCell *cell = staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        
        return cell;
    }
    return [UITableViewCell new];
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
    NSLog(@"- [XXTExplorerPermissionViewController dealloc]");
#endif
}

@end
