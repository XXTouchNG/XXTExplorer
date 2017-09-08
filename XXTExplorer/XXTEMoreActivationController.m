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

#import <objc/runtime.h>
#import "libactivator.h"
#import <dlfcn.h>

typedef enum : NSUInteger {
    kXXTEActivatorListenerRunOrStopWithAlertIndex = 0,
    kXXTEActivatorListenerRunOrStopIndex = 1,
} kXXTEActivatorListenerIndex;

static NSString * const kXXTEActivatorLibraryPath = @"/usr/lib/libactivator.dylib";
static NSString * const kXXTEActivatorListenerRunOrStop = @"com.1func.xxtouch.run_or_stop";
static NSString * const kXXTEActivatorListenerRunOrStopWithAlert = @"com.1func.xxtouch.run_or_stop_with_alert";
static void * activatorHandler = nil;

@interface XXTEMoreActivationController () <XXTEMoreActivationOperationControllerDelegate>
@property (nonatomic, assign) BOOL activatorExists;

@end

@implementation XXTEMoreActivationController {
    BOOL isFirstTimeLoaded;
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
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
    
    activatorHandler = NULL;
    if (0 == access([kXXTEActivatorLibraryPath UTF8String], R_OK)) {
        activatorHandler = dlopen([kXXTEActivatorLibraryPath UTF8String], RTLD_LAZY);
        Class la = objc_getClass("LAActivator");
        if (!la) {
            fprintf(stderr, "%s\n", dlerror());
            return;
        }
        dlerror();
        LAActivator *sharedActivator = [la sharedInstance];
        BOOL hasSeen = [sharedActivator hasSeenListenerWithName:kXXTEActivatorListenerRunOrStop];
        if (hasSeen) {
            _activatorExists = YES;
        }
    } else {
        _activatorExists = NO;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_8) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"Activation Config", nil);

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
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
    blockUserInteractions(self, YES, 2.0);
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
                    showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
                } else {
                    showUserMessage(self, [serverError localizedDescription]);
                }
            })
            .finally(^() {
                blockUserInteractions(self, NO, 2.0);
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
    staticSectionTitles = @[@"", NSLocalizedString(@"Activator", nil)];
    staticSectionFooters = @[@"", NSLocalizedString(@"\"Activator\" is active, configure activation behaviours here.", nil)];

    XXTEMoreTitleDescriptionCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell1.titleLabel.text = NSLocalizedString(@"Press \"Volume +\"", nil);
    cell1.descriptionLabel.text = NSLocalizedString(@"No action", nil);

    XXTEMoreTitleDescriptionCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell2.titleLabel.text = NSLocalizedString(@"Press \"Volume -\"", nil);
    cell2.descriptionLabel.text = NSLocalizedString(@"No action", nil);

    XXTEMoreTitleDescriptionCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"Press & Hold \"Volume +\"", nil);
    cell3.descriptionLabel.text = NSLocalizedString(@"No action", nil);

    XXTEMoreTitleDescriptionCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell4.titleLabel.text = NSLocalizedString(@"Press & Hold \"Volume -\"", nil);
    cell4.descriptionLabel.text = NSLocalizedString(@"No action", nil);
    
    if (self.activatorExists) {
        XXTEMoreTitleDescriptionCell *cellActivator1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
        cellActivator1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cellActivator1.titleLabel.text = NSLocalizedString(@"Pop-up Menu", nil);
        cellActivator1.descriptionLabel.text = NSLocalizedString(@"Ask you for a choice.", nil);
        
        XXTEMoreTitleDescriptionCell *cellActivator2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
        cellActivator2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cellActivator2.titleLabel.text = NSLocalizedString(@"Launch / Stop Selected Script", nil);
        cellActivator2.descriptionLabel.text = NSLocalizedString(@"Launch or stop the selected script directly.", nil);
        
        staticCells = @[
                        @[ cell1, cell2, cell3, cell4 ],
                        @[ cellActivator1, cellActivator2 ],
                        ];
    } else {
        staticCells = @[
                        @[cell1, cell2, cell3, cell4],
                        ];
    }
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return staticCells.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticCells[section].count;
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
            if (NO == self.activatorExists) {
                XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *) staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
                XXTEMoreActivationOperationController *operationController = [[XXTEMoreActivationOperationController alloc] initWithStyle:UITableViewStyleGrouped];
                operationController.delegate = self;
                operationController.actionIndex = (NSUInteger) indexPath.row;
                operationController.title = cell.titleLabel.text;
                [self.navigationController pushViewController:operationController animated:YES];
            } else {
                showUserMessage(self, NSLocalizedString(@"\"Activator\" is active, configure activation behaviours below.", nil));
            }
        } else if (indexPath.section == 1) {
            if (indexPath.row == kXXTEActivatorListenerRunOrStopWithAlertIndex) {
                LAListenerSettingsViewController *vc = [objc_getClass("LAListenerSettingsViewController") new];
                vc.listenerName = kXXTEActivatorListenerRunOrStopWithAlert;
                vc.title = NSLocalizedString(@"Pop-up Menu", nil);
                [self.navigationController pushViewController:vc animated:YES];
            } else if (indexPath.row == kXXTEActivatorListenerRunOrStopIndex) {
                LAListenerSettingsViewController *vc = [objc_getClass("LAListenerSettingsViewController") new];
                vc.listenerName = kXXTEActivatorListenerRunOrStop;
                vc.title = NSLocalizedString(@"Launch / Stop Selected Script", nil);
                [self.navigationController pushViewController:vc animated:YES];
            }
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
    if (activatorHandler != NULL) {
        dlclose(activatorHandler);
    }
#ifdef DEBUG
    NSLog(@"[XXTEMoreActivationController dealloc]");
#endif
}

@end
