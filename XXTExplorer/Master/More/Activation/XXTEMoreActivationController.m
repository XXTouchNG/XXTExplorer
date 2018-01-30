//
//  XXTEMoreActivationController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 06/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreActivationController.h"

#import "XXTEMoreSwitchCell.h"
#import "XXTEMoreTitleDescriptionCell.h"
#import "XXTEMoreActivationOperationController.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import <objc/runtime.h>
#import "libactivator.h"
#import <dlfcn.h>
#import "XXTEModeSettingsController.h"
#import "LASettingsViewController+MyShowsAd.h"

#import "XXTEAppDefines.h"
#import "XXTENetworkDefines.h"
#import "XXTEUserInterfaceDefines.h"

typedef enum : NSUInteger {
    XXTEMoreActivationSectionInternalSwitch = 0,
    XXTEMoreActivationSectionInternalMethods,
    XXTEMoreActivationSectionActivator,
} XXTEMoreActivationSection;

static NSString * const kXXTEActivatorLibraryPath = @"/usr/lib/libactivator.dylib";
static NSString * const kXXTEActivatorListenerRunOrStop = @"com.1func.xxtouch.run_or_stop";
static NSString * const kXXTEActivatorListenerRunOrStopWithAlert = @"com.1func.xxtouch.run_or_stop_with_alert";
static void * activatorHandler = nil;

@interface XXTEMoreActivationController () <XXTEMoreActivationOperationControllerDelegate>

@property (nonatomic, assign, getter=isShortcutEnabled) BOOL shortcutEnabled;
@property (nonatomic, strong) UISwitch *activationSwitch;

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
    operationKeyNames = @[
                          @"click_volume_up",
                          @"click_volume_down",
                          @"hold_volume_up",
                          @"hold_volume_down"];
    operationStatus = [@{
                         @"click_volume_up": @(0),
                         @"click_volume_down": @(0),
                         @"hold_volume_up": @(0),
                         @"hold_volume_down": @(0)} mutableCopy];
    
    activatorHandler = NULL;
    if (0 == access([kXXTEActivatorLibraryPath UTF8String], R_OK)) {
#if !(TARGET_OS_SIMULATOR)
        activatorHandler = dlopen([kXXTEActivatorLibraryPath UTF8String], RTLD_LAZY);
        Class la = objc_getClass("LAActivator");
        if (!la) {
            fprintf(stderr, "%s\n", dlerror());
            return;
        }
        dlerror();
        LAActivator *sharedActivator = [la sharedInstance];
        BOOL hasSeen = [sharedActivator hasSeenListenerWithName:kXXTEActivatorListenerRunOrStop] && [sharedActivator hasSeenListenerWithName:kXXTEActivatorListenerRunOrStopWithAlert];
        if (hasSeen) {
            _activatorExists = YES;

            // Method Swizzing to hide Ads
            Method s1_Method =  class_getInstanceMethod([LASettingsViewController class], @selector(showsAd));
            Method s2_Method = class_getInstanceMethod([LASettingsViewController class], @selector(myShowsAd));
            method_exchangeImplementations(s1_Method, s2_Method);
        }
#endif
    } else {
        _activatorExists = NO;
    }
#ifdef DEBUG
    _activatorExists = NO;
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];

    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"Shortcut Config", nil);

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
    UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
    [PMKPromise promiseWithValue:self]
    .then(^(id value) {
        return [NSURLConnection POST:uAppDaemonCommandUrl(@"get_user_conf") JSON:@{}];
    })
    .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        return jsonDictionary[@"data"];
    })
    .then(^(NSDictionary *dataDictionary) {
        NSString *optionKeyName = @"device_control_toggle";
        if (dataDictionary[optionKeyName]) {
            BOOL operationType = [dataDictionary[optionKeyName] boolValue];
            self.shortcutEnabled = operationType;
            [self.activationSwitch setOn:operationType];
        }
        return self;
    })
    .then(^(id value) {
        return [NSURLConnection POST:uAppDaemonCommandUrl(@"get_volume_action_conf") JSON:@{}];
    })
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
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
        [self.tableView reloadData];
    });
}

- (void)updateOperationStatusDisplay {
    ((XXTEMoreTitleDescriptionCell *)staticCells[XXTEMoreActivationSectionInternalMethods][0]).descriptionLabel.text = [self operationDescriptionWithKey:@"click_volume_up"];
    ((XXTEMoreTitleDescriptionCell *)staticCells[XXTEMoreActivationSectionInternalMethods][1]).descriptionLabel.text = [self operationDescriptionWithKey:@"click_volume_down"];
    ((XXTEMoreTitleDescriptionCell *)staticCells[XXTEMoreActivationSectionInternalMethods][2]).descriptionLabel.text = [self operationDescriptionWithKey:@"hold_volume_up"];
    ((XXTEMoreTitleDescriptionCell *)staticCells[XXTEMoreActivationSectionInternalMethods][3]).descriptionLabel.text = [self operationDescriptionWithKey:@"hold_volume_down"];
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
    staticSectionTitles = @[@"", NSLocalizedString(@"Internal Shortcut", nil), NSLocalizedString(@"Activator", nil)];
    NSString *activatorInstallTip = @"";
    if (NO == self.activatorExists) {
        activatorInstallTip = NSLocalizedString(@"Open \"Cydia\" and install 3rd-party tweak \"Activator\" to customize more activation methods, or set up scheduled tasks.", nil);
    }
    staticSectionFooters = @[NSLocalizedString(@"Disable this feature to ignore all shortcut events that can launch or stop selected script.", nil), @"", activatorInstallTip];
    
    XXTEMoreSwitchCell *switchCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    switchCell.titleLabel.text = NSLocalizedString(@"Enable Shortcut", nil);
    switchCell.iconImage = [UIImage imageNamed:@"XXTEMoreIconActivationConfig"];
    UISwitch *mainSwitch = switchCell.optionSwitch;
    mainSwitch.on = YES;
    mainSwitch.enabled = YES;
    [mainSwitch addTarget:self action:@selector(optionSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.activationSwitch = mainSwitch;
    
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
    
    XXTEMoreTitleDescriptionCell *cellActivator = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cellActivator.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cellActivator.iconImage = [UIImage imageNamed:@"ActivatorIcon"];
    cellActivator.descriptionLabel.text = NSLocalizedString(@"Centralized gestures and button management for iOS.", nil);
    if (self.activatorExists) {
        cellActivator.titleLabel.text = NSLocalizedString(@"Configure \"Activator\"", nil);
    } else {
        cellActivator.titleLabel.text = NSLocalizedString(@"Install \"Activator\"", nil);
    }
    staticCells = @[
                    @[ switchCell ],
                    @[ cell1, cell2, cell3, cell4 ],
                    @[ cellActivator ],
                    ];
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
    if (tableView == self.tableView) {
        if (indexPath.section == XXTEMoreActivationSectionInternalSwitch) {
            return 66.f;
        }
        else if (indexPath.section == XXTEMoreActivationSectionInternalMethods) {
            return 66.f;
        }
        else if (indexPath.section == XXTEMoreActivationSectionActivator) {
            return 66.f;
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == XXTEMoreActivationSectionInternalMethods) {
            if (NO == self.activatorExists) {
                XXTEMoreTitleDescriptionCell *cell = (XXTEMoreTitleDescriptionCell *) staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
                XXTEMoreActivationOperationController *operationController = [[XXTEMoreActivationOperationController alloc] initWithStyle:UITableViewStyleGrouped];
                operationController.delegate = self;
                operationController.actionIndex = (NSUInteger) indexPath.row;
                operationController.title = cell.titleLabel.text;
                [self.navigationController pushViewController:operationController animated:YES];
            } else {
                toastMessage(self, NSLocalizedString(@"\"Activator\" is active, configure activation behaviours below.", nil));
            }
        } else if (indexPath.section == XXTEMoreActivationSectionActivator) {
            if (self.activatorExists) {
#if !(TARGET_OS_SIMULATOR)
                XXTEModeSettingsController *vc = [[XXTEModeSettingsController alloc] initWithMode:nil];
#else
                XXTEModeSettingsController *vc = [[XXTEModeSettingsController alloc] init];
#endif
                vc.title = NSLocalizedString(@"Activator", nil);
                [self.navigationController pushViewController:vc animated:YES];
            } else {
                NSString *activatorURLString = uAppDefine(@"ACTIVATOR_URL");
                NSURL *activatorURL = [NSURL URLWithString:activatorURLString];
                if ([[UIApplication sharedApplication] canOpenURL:activatorURL]) {
                    [[UIApplication sharedApplication] openURL:activatorURL];
                } else {
                    toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot open: \"%@\"", nil), activatorURL]);
                }
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

#pragma mark - Actions

- (void)optionSwitchChanged:(UISwitch *)sender {
    if (sender == self.activationSwitch) {
        BOOL changeToStatus = sender.on;
        UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
        @weakify(self);
        [NSURLConnection POST:uAppDaemonCommandUrl(@"set_user_conf") JSON:@{ @"device_control_toggle": @(changeToStatus) }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            @strongify(self);
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                self.shortcutEnabled = changeToStatus;
                [sender setOn:changeToStatus animated:YES];
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot save changes: %@", nil), jsonDictionary[@"message"]];
            }
        }).catch(^(NSError *serverError) {
            if (serverError.code == -1004) {
                toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                toastMessage(self, [serverError localizedDescription]);
            }
            [sender setOn:!changeToStatus animated:YES];
        }).finally(^() {
            blockInteractions(blockVC, NO);
        });
    }
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
    NSLog(@"- [XXTEMoreActivationController dealloc]");
#endif
}

@end
