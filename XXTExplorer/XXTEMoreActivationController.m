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
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import "UIView+XXTEToast.h"
#import "XXTENetworkDefines.h"

@interface XXTEMoreActivationController ()

@end

@implementation XXTEMoreActivationController {
    BOOL isFirstTimeLoaded;
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
    NSArray <NSString *> *operationKeyNames;
    NSMutableDictionary <NSString *, NSNumber *> *operationStatus;
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
    operationKeyNames = @[@"click_volume_up", @"click_volume_down", @"hold_volume_up", @"hold_volume_down"];
    operationStatus = [@{@"click_volume_up": @(0), @"click_volume_down": @(0), @"hold_volume_up": @(0), @"hold_volume_down": @(0)} mutableCopy];
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
    [self reloadDynamicTableViewData];
}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    if (isFirstTimeLoaded) {
//        [self reloadDynamicTableViewData];
//    }
//    isFirstTimeLoaded = YES;
//}

- (void)reloadDynamicTableViewData {
    blockUserInteractions(self.navigationController.view, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"get_volume_action_conf") JSON:@{}]
            .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
                return jsonDictionary[@"data"];
            })
            .then(^(NSDictionary *dataDictionary) {
                [[operationStatus allKeys] enumerateObjectsUsingBlock:^(NSString *optionKeyName, NSUInteger idx, BOOL *stop) {
                    if (dataDictionary[optionKeyName]) {
                        NSInteger operationType = [dataDictionary[optionKeyName] integerValue];
                        operationStatus[optionKeyName] = @(operationType);
                    }
                }];
            })
            .then(^() {
                [self updateOperationStatusDisplay];
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

- (void)updateOperationStatusDisplay {
    ((XXTEMoreTitleDescriptionCell *)staticCells[0][0]).descriptionLabel.text = [self operationDescriptionWithKey:@"click_volume_up"];
    ((XXTEMoreTitleDescriptionCell *)staticCells[0][1]).descriptionLabel.text = [self operationDescriptionWithKey:@"click_volume_down"];
    ((XXTEMoreTitleDescriptionCell *)staticCells[0][2]).descriptionLabel.text = [self operationDescriptionWithKey:@"hold_volume_up"];
    ((XXTEMoreTitleDescriptionCell *)staticCells[0][3]).descriptionLabel.text = [self operationDescriptionWithKey:@"hold_volume_down"];
}

- (NSString *)operationDescriptionWithKey:(NSString *)key {
    NSString *descriptionString = nil;
    NSInteger operationType = [operationStatus[key] integerValue];
    if (operationType == 0) {
        descriptionString = NSLocalizedString(@"Pop-up Menu", nil);
    }
    else if (operationType == 1) {
        descriptionString = NSLocalizedString(@"Launch / Stop Selected Script", nil);
    }
    else if (operationType == 2) {
        descriptionString = NSLocalizedString(@"No Action", nil);
    }
    return descriptionString;
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[@""];
    staticSectionFooters = @[@""];

    XXTEMoreTitleDescriptionCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell1.titleLabel.text = NSLocalizedString(@"Press \"Volume +\"", nil);
    cell1.descriptionLabel.text = @"";

    XXTEMoreTitleDescriptionCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell2.titleLabel.text = NSLocalizedString(@"Press \"Volume -\"", nil);
    cell2.descriptionLabel.text = @"";

    XXTEMoreTitleDescriptionCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"Press & Hold \"Volume +\"", nil);
    cell3.descriptionLabel.text = @"";

    XXTEMoreTitleDescriptionCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell4.titleLabel.text = NSLocalizedString(@"Press & Hold \"Volume -\"", nil);
    cell4.descriptionLabel.text = @"";

    staticSectionRowNum = @[@4];

    staticCells = @[
            @[cell1, cell2, cell3, cell4],
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
        XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *) staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        XXTEMoreActivationOperationController *operationController = [[XXTEMoreActivationOperationController alloc] initWithStyle:UITableViewStyleGrouped];
        operationController.delegate = self;
        operationController.actionIndex = (NSUInteger) indexPath.row;
        operationController.title = cell.titleLabel.text;
        [self.navigationController pushViewController:operationController animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return NSLocalizedString(staticSectionTitles[(NSUInteger) section], nil);
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return NSLocalizedString(staticSectionFooters[(NSUInteger) section], nil);
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
    }
    return [UITableViewCell new];
}

#pragma mark - XXTEMoreActivationOperationControllerDelegate

- (void)activationOperationController:(XXTEMoreActivationOperationController *)controller operationSelectedWithIndex:(NSUInteger)index {
    operationStatus[operationKeyNames[controller.actionIndex]] = @(index);
    [self updateOperationStatusDisplay];
    [self.tableView reloadData];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreActivationController dealloc]");
#endif
}

@end
