//
//  XXTEMoreBootScriptController.m
//  XXTExplorer
//
//  Created by Zheng on 08/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreBootScriptController.h"
#import "XXTEMoreLinkNoIconCell.h"
#import "XXTEMoreSwitchCell.h"
#import "XXTEMoreAddressCell.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import "UIView+XXTEToast.h"
#import "XXTENetworkDefines.h"
#import "XXTExplorerViewController+SharedInstance.h"
#import "XXTEMoreBootScriptPicker.h"

@interface XXTEMoreBootScriptController () <XXTEMoreBootScriptPickerDelegate>
@property (nonatomic, strong) UISwitch *bootScriptSwitch;

@end

@implementation XXTEMoreBootScriptController {
    BOOL isFirstTimeLoaded;
    NSArray <NSMutableArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
    NSString *bootScriptPath;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype) initWithStyle:(UITableViewStyle)style {
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
    self.title = NSLocalizedString(@"Boot Script", nil);
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

- (void)updateBootScriptDisplay {
    XXTEMoreAddressCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell2.addressLabel.text = bootScriptPath.length > 0 ? bootScriptPath : @"N/A";
    
    XXTEMoreLinkNoIconCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"Select Boot Script", nil);
    
    staticCells[1][0] = cell2;
    staticCells[1][1] = cell3;
    
    if (bootScriptPath) {
        staticSectionTitles = @[ @"", NSLocalizedString(@"Current Script", nil) ];
        staticSectionRowNum = @[ @1, @2 ];
    } else {
        staticSectionTitles = @[ @"", @"" ];
        staticSectionRowNum = @[ @1, @0 ];
    }
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"", NSLocalizedString(@"Current Script", nil) ];
    staticSectionFooters = @[ NSLocalizedString(@"Warning: Bootscript could leave system at a unpredictable state. You can hold \"Volume +\" before booting to stop vulnerable script from being launched.", nil), @"" ];
    
    XXTEMoreSwitchCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = @"Enable Boot Script";
    cell1.iconImageView.image = [UIImage imageNamed:@"XXTEMoreIconBootScript"];
    [cell1.optionSwitch addTarget:self action:@selector(bootScriptOptionSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.bootScriptSwitch = cell1.optionSwitch;
    
    XXTEMoreAddressCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell2.addressLabel.text = bootScriptPath.length > 0 ? bootScriptPath : @"N/A";
    
    XXTEMoreLinkNoIconCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"Select Boot Script", nil);
    
    staticCells = @[
                    [@[ cell1 ] mutableCopy],
                    //
                    [@[ cell2, cell3 ] mutableCopy]
                    ];
    
    [self updateBootScriptDisplay];
}

- (void)reloadDynamicTableViewData {
    blockUserInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"get_startup_conf") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            BOOL bootScriptEnabled = [jsonDictionary[@"data"][@"startup_run"] boolValue];
            if (bootScriptEnabled) {
                NSString *bootScriptName = jsonDictionary[@"data"][@"startup_script"];
                if (bootScriptName) {
                    if ([bootScriptName isAbsolutePath]) {
                        bootScriptPath = bootScriptName;
                    } else {
                        bootScriptPath = [XXTExplorerViewController.initialPath stringByAppendingPathComponent:bootScriptName];
                    }
                }
            }
            [self updateBootScriptDisplay];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (self.bootScriptSwitch.isOn != bootScriptEnabled) {
                [self.bootScriptSwitch setOn:bootScriptEnabled];
            }
        }
    }).catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            showUserMessage(self, [serverError localizedDescription]);
        }
    }).finally(^() {
        blockUserInteractions(self, NO);
    });
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
        return [staticSectionRowNum[section] integerValue];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                return 66.f;
            }
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                return UITableViewAutomaticDimension;
            } else {
                return 44.f;
            }
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                NSString *addressText = bootScriptPath;
                if (addressText && addressText.length > 0) {
                    blockUserInteractions(self, YES);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:addressText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        showUserMessage(self, NSLocalizedString(@"Boot script path has been copied to the pasteboard.", nil));
                        blockUserInteractions(self, NO);
                    });
                }
            } else if (indexPath.row == 1) {
                XXTEMoreBootScriptPicker *bootScriptPicker = [[XXTEMoreBootScriptPicker alloc] init];
                bootScriptPicker.delegate = self;
                bootScriptPicker.allowedExtensions = @[ @"xxt", @"xpp", @"lua", @"luac" ];
                bootScriptPicker.selectedBootScriptPath = bootScriptPath;
                [self.navigationController pushViewController:bootScriptPicker animated:YES];
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
        return staticCells[indexPath.section][indexPath.row];
    }
    return [UITableViewCell new];
}

#pragma mark - UIControl Actions

- (void)bootScriptOptionSwitchChanged:(UISwitch *)sender {
    if (sender == self.bootScriptSwitch) {
        BOOL changeToStatus = sender.on;
        NSString *changeToCommand = nil;
        if (changeToStatus)
            changeToCommand = @"set_startup_run_on";
        else
            changeToCommand = @"set_startup_run_off";
        blockUserInteractions(self, YES);
        [NSURLConnection POST:uAppDaemonCommandUrl(changeToCommand) JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                if (changeToStatus) {
                    NSString *bootScriptName = jsonDictionary[@"data"][@"startup_script"];
                    if (bootScriptName) {
                        if ([bootScriptName isAbsolutePath]) {
                            bootScriptPath = bootScriptName;
                        } else {
                            bootScriptPath = [XXTExplorerViewController.initialPath stringByAppendingPathComponent:bootScriptName];
                        }
                    }
                } else {
                    bootScriptPath = nil;
                }
                [self updateBootScriptDisplay];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.bootScriptSwitch setOn:changeToStatus animated:YES];
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot switch boot script: %@", nil), jsonDictionary[@"message"]];
            }
        }).catch(^(NSError *serverError) {
            if (serverError.code == -1004) {
                showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                showUserMessage(self, [serverError localizedDescription]);
            }
            [self.bootScriptSwitch setOn:!changeToStatus animated:YES];
        }).finally(^() {
            blockUserInteractions(self, NO);
        });
    }
}

#pragma mark - XXTEMoreBootScriptPickerDelegate

- (void)bootScriptPicker:(XXTEMoreBootScriptPicker *)picker didSelectedBootScriptPath:(NSString *)path {
    blockUserInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"select_startup_script_file") JSON:@{ @"filename": path }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            bootScriptPath = path;
            [self updateBootScriptDisplay];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot select boot script: %@", nil), jsonDictionary[@"message"]];
        }
    }).catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            showUserMessage(self, [serverError localizedDescription]);
        }
    }).finally(^() {
        blockUserInteractions(self, NO);
        [picker.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreBootScriptController dealloc]");
#endif
}

@end
