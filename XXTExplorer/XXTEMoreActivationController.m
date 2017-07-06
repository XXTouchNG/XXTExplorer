//
//  XXTEMoreActivationController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 06/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreActivationController.h"
#import "XXTEMoreTitleDescriptionCell.h"
#import "XXTEMoreActivationOperationController.h"

@interface XXTEMoreActivationController ()

@end

@implementation XXTEMoreActivationController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
}

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

- (void)setup {
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = NSLocalizedString(@"Activation Config", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self reloadStaticTableViewData];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"" ];
    staticSectionFooters = @[ @"" ];
    
    XXTEMoreTitleDescriptionCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell1.titleLabel.text = NSLocalizedString(@"Up Press", nil);
    cell1.descriptionLabel.text = NSLocalizedString(@"Press \"Volume +\" Button", nil);
    
    XXTEMoreTitleDescriptionCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell2.titleLabel.text = NSLocalizedString(@"Down Press", nil);
    cell2.descriptionLabel.text = NSLocalizedString(@"Press \"Volume -\" Button", nil);
    
    XXTEMoreTitleDescriptionCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"Up Short Hold", nil);
    cell3.descriptionLabel.text = NSLocalizedString(@"Press and hold \"Volume +\" Button", nil);
    
    XXTEMoreTitleDescriptionCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell4.titleLabel.text = NSLocalizedString(@"Down Short Hold", nil);
    cell4.descriptionLabel.text = NSLocalizedString(@"Press and hold \"Volume -\" Button", nil);
    
    staticSectionRowNum = @[ @4 ];
    
    staticCells = @[
                    @[ cell1, cell2, cell3, cell4 ],
                    ];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [staticSectionRowNum[section] integerValue];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return 66.f;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *)staticCells[indexPath.section][indexPath.row];
        XXTEMoreActivationOperationController *operationController = [[XXTEMoreActivationOperationController alloc] initWithStyle:UITableViewStyleGrouped];
        operationController.actionIndex = indexPath.row;
        operationController.title = cell.titleLabel.text;
        [self.navigationController pushViewController:operationController animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return NSLocalizedString(staticSectionTitles[section], nil);
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return NSLocalizedString(staticSectionFooters[section], nil);
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return staticCells[indexPath.section][indexPath.row];
    }
    return [UITableViewCell new];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreActivationController dealloc]");
#endif
}

@end
