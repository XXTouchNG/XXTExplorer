//
//  XXTEMoreRecordingController.m
//  XXTExplorer
//
//  Created by Zheng on 07/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreRecordingController.h"
#import "XXTEMoreTitleDescriptionCell.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import "UIView+XXTEToast.h"
#import "XXTENetworkDefines.h"

@interface XXTEMoreRecordingController ()
@property (nonatomic, assign) BOOL shouldRecordVolumeUp;
@property (nonatomic, assign) BOOL shouldRecordVolumeDown;

@end

@implementation XXTEMoreRecordingController {
    BOOL isFirstTimeLoaded;
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
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
    
    self.title = NSLocalizedString(@"Recording Config", nil);
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
    [NSURLConnection POST:uAppDaemonCommandUrl(@"get_record_conf") JSON:@{}]
    .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        return jsonDictionary[@"data"];
    })
    .then(^(NSDictionary *dataDictionary) {
        if (dataDictionary[@"record_volume_up"] && dataDictionary[@"record_volume_down"]) {
            self.shouldRecordVolumeUp = [dataDictionary[@"record_volume_up"] boolValue];
            self.shouldRecordVolumeDown = [dataDictionary[@"record_volume_down"] boolValue];
        }
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
    staticCells[0][(self.shouldRecordVolumeUp ? 0 : 1)].accessoryType = UITableViewCellAccessoryCheckmark;
    staticCells[0][(self.shouldRecordVolumeUp ? 1 : 0)].accessoryType = UITableViewCellAccessoryNone;
    staticCells[1][(self.shouldRecordVolumeDown ? 0 : 1)].accessoryType = UITableViewCellAccessoryCheckmark;
    staticCells[1][(self.shouldRecordVolumeDown ? 1 : 0)].accessoryType = UITableViewCellAccessoryNone;
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[@"Should Record \"Volume +\"", @"Should Record \"Volume -\""];
    staticSectionFooters = @[@"", @""];
    
    XXTEMoreTitleDescriptionCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell1.accessoryType = UITableViewCellAccessoryNone;
    cell1.titleLabel.text = NSLocalizedString(@"On", nil);
    cell1.descriptionLabel.text = NSLocalizedString(@"Record \"Volume +\" action.", nil);
    
    XXTEMoreTitleDescriptionCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryNone;
    cell2.titleLabel.text = NSLocalizedString(@"Off", nil);
    cell2.descriptionLabel.text = NSLocalizedString(@"Do not record \"Volume +\" action.", nil);
    
    XXTEMoreTitleDescriptionCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryNone;
    cell3.titleLabel.text = NSLocalizedString(@"On", nil);
    cell3.descriptionLabel.text = NSLocalizedString(@"Record \"Volume -\" action.", nil);
    
    XXTEMoreTitleDescriptionCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryNone;
    cell4.titleLabel.text = NSLocalizedString(@"Off", nil);
    cell4.descriptionLabel.text = NSLocalizedString(@"Do not record \"Volume -\" action.", nil);
    
    staticCells = @[
                    @[cell1, cell2],
                    @[cell3, cell4],
                    ];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return 2;
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
    if (tableView == self.tableView) {
        return 66.f;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        NSUInteger operationIndex = (NSUInteger) indexPath.row;
        blockUserInteractions(self.navigationController.view, YES);
        NSString *commandUrl = nil;
        if (indexPath.section == 0) {
            commandUrl = (indexPath.row == 0) ? uAppDaemonCommandUrl(@"set_record_volume_up_on") : uAppDaemonCommandUrl(@"set_record_volume_up_off");
        } else {
            commandUrl = (indexPath.row == 0) ? uAppDaemonCommandUrl(@"set_record_volume_down_on") : uAppDaemonCommandUrl(@"set_record_volume_down_off");
        }
        [NSURLConnection POST:commandUrl JSON:@{@"action": @(operationIndex)}]
        .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
                if (indexPath.section == 0) {
                    self.shouldRecordVolumeUp = (indexPath.row == 0);
                } else if (indexPath.section == 1) {
                    self.shouldRecordVolumeDown = (indexPath.row == 0);
                }
                [self updateOperationStatusDisplay];
                [self.tableView reloadData];
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
        XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *) staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        if (indexPath.section == 0) {
            if (indexPath.row == (self.shouldRecordVolumeUp ? 0 : 1)) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        } else {
            if (indexPath.row == (self.shouldRecordVolumeDown ? 0 : 1)) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreRecordingController dealloc]");
#endif
}

@end
