//
//  XXTEDbTableListViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEDbTableListViewController.h"

#import "XXTEDatabaseManager.h"
#import "XXTESQLiteDatabaseManager.h"

#import "XXTEDbTableContentViewController.h"
#import "XXTEDbReader.h"

#import "XXTEMoreLinkCell.h"

@interface XXTEDbTableListViewController ()
{
    id<XXTEDatabaseManager> _dbm;
    NSString *_databasePath;
}

@property (nonatomic, strong) NSArray<NSString *> *tables;

@end

@implementation XXTEDbTableListViewController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Database Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[@"db", @"sqlite", @"sqlite3"];
}

+ (Class)relatedReader {
    return [XXTEDbReader class];
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _entryPath = path;
        _databasePath = [path copy];
        _dbm = [self databaseManagerForFileAtPath:_databasePath];
        [_dbm open];
        [self getAllTables];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.tableView.style == UITableViewStylePlain) {
        self.view.backgroundColor = XXTColorPlainBackground();
    } else {
        self.view.backgroundColor = XXTColorGroupedBackground();
    }
    
    if (self.title.length == 0) {
        if (self.entryPath) {
            NSString *entryName = [self.entryPath lastPathComponent];
            self.title = entryName;
        } else {
            self.title = [[self class] viewerName];
        }
    }
    
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreLinkCell class]) bundle:nil] forCellReuseIdentifier:XXTEMoreLinkCellReuseIdentifier];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

- (id<XXTEDatabaseManager>)databaseManagerForFileAtPath:(NSString *)path
{
    return [[XXTESQLiteDatabaseManager alloc] initWithPath:path];
}

- (void)getAllTables
{
    NSArray <NSDictionary<NSString *, id> *> *resultArray = [_dbm queryAllTables];
    NSMutableArray <NSString *> *array = [NSMutableArray array];
    for (NSDictionary <NSString *, id> *dict in resultArray) {
        NSString *columnName = (NSString *)dict[@"name"] ? : @"";
        [array addObject:columnName];
    }
    self.tables = array;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tables.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXTEMoreLinkCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEMoreLinkCellReuseIdentifier forIndexPath:indexPath];
    if (indexPath.row < self.tables.count) {
        cell.titleLabel.text = self.tables[indexPath.row];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    XXTEDbTableContentViewController *contentViewController = [[XXTEDbTableContentViewController alloc] init];
    
    contentViewController.contentsArray = [_dbm queryAllDataWithTableName:self.tables[indexPath.row]];
    contentViewController.columnsArray = [_dbm queryAllColumnsWithTableName:self.tables[indexPath.row]];
    
    contentViewController.title = self.tables[indexPath.row];
    [self.navigationController pushViewController:contentViewController animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:NSLocalizedString(@"%lu tables", nil), (unsigned long)self.tables.count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
