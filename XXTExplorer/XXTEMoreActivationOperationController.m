//
//  XXTEMoreActivationOperationController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 06/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreActivationOperationController.h"
#import "XXTEMoreTitleDescriptionCell.h"
#import <PromiseKit/PromiseKit.h>
#import "NSURLConnection+PromiseKit.h"
#import "UIView+XXTEToast.h"
#import "XXTENetworkDefines.h"

@interface XXTEMoreActivationOperationController ()

@end

@implementation XXTEMoreActivationOperationController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
    NSArray <NSString *> *operationKeyNames;
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
    _selectedOperation = NSUIntegerMax;
    operationKeyNames = @[ @"click_volume_up", @"click_volume_down", @"hold_volume_up", @"hold_volume_down" ];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self reloadStaticTableViewData];
    [self reloadDynamicTableViewData];
}

- (void)reloadDynamicTableViewData {
    blockUserInteractions(self.navigationController.view, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"get_volume_action_conf") JSON:@{  }]
    .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        return jsonDictionary[@"data"];
    })
    .then(^(NSDictionary *dataDictionary) {
        self.selectedOperation = [dataDictionary[operationKeyNames[self.actionIndex]] integerValue];
    })
    .catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            showUserMessage(self.navigationController.view, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            showUserMessage(self.navigationController.view, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockUserInteractions(self.navigationController.view, NO);
        [self.tableView reloadData];
    });
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"" ];
    staticSectionFooters = @[ @"" ];
    
    XXTEMoreTitleDescriptionCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell1.accessoryType = UITableViewCellAccessoryNone;
    cell1.titleLabel.text = NSLocalizedString(@"Pop-up Menu", nil);
    cell1.descriptionLabel.text = NSLocalizedString(@"Ask you for a choice.", nil);
    
    XXTEMoreTitleDescriptionCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryNone;
    cell2.titleLabel.text = NSLocalizedString(@"Launch / Stop Selected Script", nil);
    cell2.descriptionLabel.text = NSLocalizedString(@"Launch or stop the selected script directly.", nil);
    
    XXTEMoreTitleDescriptionCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryNone;
    cell3.titleLabel.text = NSLocalizedString(@"No Action", nil);
    cell3.descriptionLabel.text = NSLocalizedString(@"Nothing will be performed.", nil);
    
    staticSectionRowNum = @[ @3 ];
    
    staticCells = @[
                    @[ cell1, cell2, cell3 ],
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
        if (indexPath.section == 0) {
            NSUInteger operationIndex = indexPath.row;
            blockUserInteractions(self.navigationController.view, YES);
            [NSURLConnection POST:[NSString stringWithFormat:uAppDaemonCommandUrl(@"set_%@_action"), operationKeyNames[self.actionIndex]] JSON:@{  }]
            .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
                if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
                    self.selectedOperation = operationIndex;
                    for (XXTEMoreTitleDescriptionCell *cell1 in staticCells[indexPath.section]) {
                        cell1.accessoryType = UITableViewCellAccessoryNone;
                    }
                    XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *)staticCells[indexPath.section][indexPath.row];
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    if (_delegate && [_delegate respondsToSelector:@selector(activationOperationController:operationSelectedWithIndex:)]) {
                        [_delegate activationOperationController:self operationSelectedWithIndex:operationIndex];
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
                blockUserInteractions(self.navigationController.view, NO);
            });
        }
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
        XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *)staticCells[indexPath.section][indexPath.row];
        if (indexPath.row == self.selectedOperation) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreActivationOperationController dealloc]");
#endif
}

@end
