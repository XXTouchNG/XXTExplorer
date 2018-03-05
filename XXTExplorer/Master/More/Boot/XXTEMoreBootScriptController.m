//
//  XXTEMoreBootScriptController.m
//  XXTExplorer
//
//  Created by Zheng on 08/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreBootScriptController.h"
#import "XXTEMoreLinkCell.h"
#import "XXTEMoreSwitchCell.h"
#import "XXTEMoreAddressCell.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import "XXTExplorerViewController+SharedInstance.h"
#import "XXTExplorerItemPicker.h"


@interface XXTEMoreBootScriptController () <XXTExplorerItemPickerDelegate>
@property (nonatomic, strong) UISwitch *bootScriptSwitch;
@property (nonatomic, copy) NSString *bootScriptPath;

@end

@implementation XXTEMoreBootScriptController {
    BOOL isFirstTimeLoaded;
    NSArray <NSMutableArray <UITableViewCell *> *> *staticCells;
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

- (instancetype) initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"Boot Script", nil);
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

- (void)updateBootScriptDisplay {
    XXTEMoreAddressCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell2.addressLabel.text = self.bootScriptPath.length > 0 ? self.bootScriptPath : NSLocalizedString(@"N/A", nil);
    
    XXTEMoreLinkCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"Select Boot Script", nil);
    
    staticCells[1][0] = cell2;
    staticCells[1][1] = cell3;
    
    if (self.bootScriptPath) {
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
    cell1.titleLabel.text = NSLocalizedString(@"Enable Boot Script", nil);
    cell1.iconImage = [UIImage imageNamed:@"XXTEMoreIconBootScript"];
    [cell1.optionSwitch addTarget:self action:@selector(optionSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.bootScriptSwitch = cell1.optionSwitch;
    
    XXTEMoreAddressCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell2.addressLabel.text = self.bootScriptPath.length > 0 ? self.bootScriptPath : NSLocalizedString(@"N/A", nil);
    
    XXTEMoreLinkCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
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
    UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
    @weakify(self);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"get_startup_conf") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        @strongify(self);
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            BOOL bootScriptEnabled = [jsonDictionary[@"data"][@"startup_run"] boolValue];
            if (bootScriptEnabled) {
                NSString *bootScriptName = jsonDictionary[@"data"][@"startup_script"];
                if (bootScriptName) {
                    if ([bootScriptName isAbsolutePath]) {
                        self.bootScriptPath = bootScriptName;
                    } else {
                        self.bootScriptPath = [XXTExplorerViewController.initialPath stringByAppendingPathComponent:bootScriptName];
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
        toastDaemonError(self, serverError);
    }).finally(^() {
        blockInteractions(blockVC, NO);
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
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                return 66.f;
            }
        } else if (indexPath.section == 1) {
            return 44.f;
        }
    }
    return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                return 66.f;
            }
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                if (@available(iOS 8.0, *)) {
                    return UITableViewAutomaticDimension;
                } else {
                    UITableViewCell *cell = staticCells[indexPath.section][indexPath.row];
                    [cell setNeedsUpdateConstraints];
                    [cell updateConstraintsIfNeeded];
                    
                    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
                    [cell setNeedsLayout];
                    [cell layoutIfNeeded];
                    
                    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
                    return (height > 0) ? (height + 1.0) : 44.f;
                }
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
                NSString *addressText = self.bootScriptPath;
                if (addressText && addressText.length > 0) {
                    UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:addressText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        toastMessage(self, NSLocalizedString(@"Boot script path has been copied to the pasteboard.", nil));
                        blockInteractions(blockVC, NO);
                    });
                }
            } else if (indexPath.row == 1) {
                NSString *rootPath = [XXTExplorerViewController initialPath];
                XXTExplorerItemPicker *itemPicker = [[XXTExplorerItemPicker alloc] initWithEntryPath:rootPath];
                itemPicker.delegate = self;
                itemPicker.allowedExtensions = @[ @"xxt", @"xpp", @"lua" ];
                itemPicker.selectedBootScriptPath = self.bootScriptPath;
                [self.navigationController pushViewController:itemPicker animated:YES];
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

- (void)optionSwitchChanged:(UISwitch *)sender {
    if (sender == self.bootScriptSwitch) {
        BOOL changeToStatus = sender.on;
        NSString *changeToCommand = nil;
        if (changeToStatus)
            changeToCommand = @"set_startup_run_on";
        else
            changeToCommand = @"set_startup_run_off";
        @weakify(self);
        UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
        [NSURLConnection POST:uAppDaemonCommandUrl(changeToCommand) JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            @strongify(self);
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                if (changeToStatus) {
                    NSString *bootScriptName = jsonDictionary[@"data"][@"startup_script"];
                    if (bootScriptName) {
                        if ([bootScriptName isAbsolutePath]) {
                            self.bootScriptPath = bootScriptName;
                        } else {
                            self.bootScriptPath = [XXTExplorerViewController.initialPath stringByAppendingPathComponent:bootScriptName];
                        }
                    }
                } else {
                    self.bootScriptPath = nil;
                }
                [self updateBootScriptDisplay];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                [sender setOn:changeToStatus animated:YES];
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot save changes: %@", nil), jsonDictionary[@"message"]];
            }
        }).catch(^(NSError *serverError) {
            toastDaemonError(self, serverError);
            [sender setOn:!changeToStatus animated:YES];
        }).finally(^() {
            blockInteractions(blockVC, NO);
        });
    }
}

#pragma mark - XXTExplorerItemPickerDelegate

- (void)itemPicker:(XXTExplorerItemPicker *)picker didSelectItemAtPath:(NSString *)path {
    UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
    @weakify(self);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"select_startup_script_file") JSON:@{ @"filename": path }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        @strongify(self);
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            self.bootScriptPath = path;
            [self updateBootScriptDisplay];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot save changes: %@", nil), jsonDictionary[@"message"]];
        }
    }).catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    }).finally(^() {
        blockInteractions(blockVC, NO);
        [picker.navigationController popToViewController:self animated:YES];
    });
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEMoreBootScriptController dealloc]");
#endif
}

@end
