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
#import <PromiseKit/NSURLConnection+PromiseKit.h>


@interface XXTEMoreActivationOperationController ()

@end

@implementation XXTEMoreActivationOperationController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
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
    operationKeyNames = @[@"click_volume_up", @"click_volume_down", @"hold_volume_up", @"hold_volume_down"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.tableView.style == UITableViewStylePlain) {
        self.view.backgroundColor = XXTColorPlainBackground();
    } else {
        self.view.backgroundColor = XXTColorGroupedBackground();
    }

    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self reloadStaticTableViewData];
    [self reloadDynamicTableViewData];
}

- (void)reloadDynamicTableViewData {
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"get_volume_action_conf") JSON:@{}]
            .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
                return jsonDictionary[@"data"];
            })
            .then(^(NSDictionary *dataDictionary) {
                NSNumber *selectedOperation = dataDictionary[self->operationKeyNames[self.actionIndex]];
                if (selectedOperation != nil) {
                    self->_selectedOperation = (NSUInteger) [selectedOperation integerValue];
                }
            })
            .then(^() {
                [self updateOperationStatusDisplay];
            })
            .catch(^(NSError *serverError) {
                toastDaemonError(self, serverError);
            })
            .finally(^() {
                blockInteractions(blockVC, NO);
                [self.tableView reloadData];
            });
}

- (void)updateOperationStatusDisplay {
    for (XXTEMoreTitleDescriptionCell *cell1 in staticCells[0]) {
        cell1.accessoryType = UITableViewCellAccessoryNone;
    }
    XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *) staticCells[0][self.selectedOperation];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[@""];
    staticSectionFooters = @[@""];

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

    staticCells = @[
            @[cell1, cell2, cell3],
    ];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticCells[(NSUInteger) section].count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            NSUInteger operationIndex = (NSUInteger) indexPath.row;
            UIViewController *blockVC = blockInteractions(self, YES);
            NSString *commandUrl = [NSString stringWithFormat:uAppDaemonCommandUrl(@"set_%@_action"), operationKeyNames[self.actionIndex]];
            [NSURLConnection POST:commandUrl JSON:@{@"action": @(operationIndex)}]
                    .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
                        if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
                            self.selectedOperation = operationIndex;
                            [self updateOperationStatusDisplay];
                            if (self->_delegate && [self->_delegate respondsToSelector:@selector(activationOperationController:operationSelectedWithIndex:)]) {
                                [self->_delegate activationOperationController:self operationSelectedWithIndex:operationIndex];
                            }
                        }
                    })
                    .catch(^(NSError *serverError) {
                        toastDaemonError(self, serverError);
                    })
                    .finally(^() {
                        blockInteractions(blockVC, NO);
                    });
        }
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
        XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *) staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
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
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
