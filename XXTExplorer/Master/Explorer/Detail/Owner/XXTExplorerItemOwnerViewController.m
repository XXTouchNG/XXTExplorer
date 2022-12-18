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

//#import <pwd.h>
//#import <grp.h>
#import <sys/stat.h>

#import "XXTEProcessDelegateObject.h"

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

@property (nonatomic, assign) uid_t currentOwnerID;

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
    
    pid_t pid = 0;
    const char *binary = add1s_binary();
    const char *args[] = { binary, JB_PREFIX "/bin/cat", "/etc/passwd", NULL };
    
    XXTEProcessDelegateObject *processObj = [[XXTEProcessDelegateObject alloc] init];
    NSArray <NSValue *> *fps = [processObj processOpen:args pidPointer:&pid];
    
    FILE *fp1 = [fps[0] pointerValue];
    if (fp1 == NULL) {
        toastMessage(self, NSLocalizedString(@"Cannot launch inspector process.", nil));
        return;
    }
    NSMutableString *output = [[NSMutableString alloc] init];
    char buf1[BUFSIZ];
    bzero(buf1, BUFSIZ);
    while (fgets(buf1, BUFSIZ, fp1) != NULL) {
        [output appendString:[NSString stringWithUTF8String:buf1]];
        bzero(buf1, BUFSIZ);
    }
    int status = [processObj processClose:fps pidPointer:&pid];
    if (status != 0) {
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot read \"%@\" from inspector process.", nil), @"/etc/passwd"]);
        return;
    }
    NSArray <NSString *> *outputLines = [output componentsSeparatedByString:@"\n"];
    for (NSString *outputLine in outputLines) {
        if ([outputLine hasPrefix:@"#"]) {
            continue;
        }
        NSArray <NSString *> *names = [outputLine componentsSeparatedByString:@":"];
        if (names.count != 7) {
            continue;
        }
        XXTExplorerItemOwner *owner = [[XXTExplorerItemOwner alloc] init];
        int ownerIntID = [names[2] intValue];
        owner.ownerID = (uid_t)ownerIntID;
        owner.ownerName = names[0];
        [owners addObject:owner];
    }
    
    _itemOwners = [owners copy];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.tableView.style == UITableViewStylePlain) {
        self.view.backgroundColor = XXTColorPlainBackground();
    } else {
        self.view.backgroundColor = XXTColorGroupedBackground();
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreSwitchCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreSwitchCellReuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreTitleValueCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreTitleValueCellReuseIdentifier];
    
    XXTE_START_IGNORE_PARTIAL
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    self.navigationItem.rightBarButtonItem = self.saveItem;
    
    XXTEMoreSwitchCell *cell_s = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell_s.titleLabel.text = NSLocalizedString(@"Apply Recursively", nil);
    _applyCell = cell_s;
    
    if (self.itemOwners) {
        self.saveItem.enabled = YES;
    }
    
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
        _saveItem.enabled = NO;
    }
    return _saveItem;
}

- (void)saveItemTapped:(UIBarButtonItem *)sender {
    
    UIViewController *blockController = blockInteractions(self, YES);
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @strongify(self);
        
        NSString *ownerName = nil;
        for (XXTExplorerItemOwner *owner in self.itemOwners) {
            if (owner.ownerID == self.currentOwnerID) {
                ownerName = owner.ownerName;
            }
        }
        if (!ownerName) return;
        
        int status = 0;
        pid_t pid = 0;
        
        const char *binary = add1s_binary();
        const char **args = NULL;
        if ([self shouldApplyRecursively]) {
            args = (const char **)malloc(sizeof(const char *) * 6);
            args[0] = binary;
            args[1] = JB_PREFIX "/usr/sbin/chown";
            args[2] = "-R";
            args[3] = [ownerName UTF8String];
            args[4] = [self.entryPath fileSystemRepresentation];
            args[5] = NULL;
        } else {
            args = (const char **)malloc(sizeof(const char *) * 5);
            args[0] = binary;
            args[1] = JB_PREFIX "/usr/sbin/chown";
            args[2] = [ownerName UTF8String];
            args[3] = [self.entryPath fileSystemRepresentation];
            args[4] = NULL;
        }
        
        XXTEProcessDelegateObject *processObj = [[XXTEProcessDelegateObject alloc] init];
        NSArray <NSValue *> *pipes = [processObj processOpen:args pidPointer:&pid];
        
        status = [processObj processClose:pipes pidPointer:&pid];
        
        free(args);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            blockInteractions(blockController, NO);
            if (status == 0) {
                if ([self->_delegate respondsToSelector:@selector(explorerEntryUpdater:entryDidUpdatedAtPath:)]) {
                    [self->_delegate explorerEntryUpdater:self entryDidUpdatedAtPath:self.entryPath];
                }
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Operation failed (%d).", nil), status]);
            }
        });
        
    });
}

- (BOOL)shouldApplyRecursively {
    return self.applyCell.optionSwitch.on;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end

