//
//  XXTEMoreApplicationDetailController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreApplicationDetailController.h"
#import <LGAlertView/LGAlertView.h>
#import <PromiseKit/PromiseKit.h>
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreRemoteAddressCell.h"
#import "XXTEMoreActionCell.h"
#import "XXTENetworkDefines.h"

typedef enum : NSUInteger {
    kXXTEMoreApplicationDetailSectionIndexDetail = 0,
    kXXTEMoreApplicationDetailSectionIndexBundlePath,
    kXXTEMoreApplicationDetailSectionIndexContainerPath,
    kXXTEMoreApplicationDetailSectionIndexAction,
    kXXTEMoreApplicationDetailSectionIndexMax
} kXXTEMoreApplicationDetailSectionIndex;

@interface XXTEMoreApplicationDetailController () <LGAlertViewDelegate>

@end

@implementation XXTEMoreApplicationDetailController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
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
    self.hidesBottomBarWhenPushed = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.applicationDetail[@"applicationLocalizedName"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self reloadStaticTableViewData];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"Detail", @"Bundle Path", @"Container Path", @"Actions" ];
    
    XXTEMoreTitleValueCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Name", nil);
    cell1.valueLabel.text = self.applicationDetail[@"applicationLocalizedName"];
    
    XXTEMoreTitleValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Bundle ID", nil);
    cell2.valueLabel.text = self.applicationDetail[@"applicationIdentifier"];
    
    XXTEMoreRemoteAddressCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteAddressCell class]) owner:nil options:nil] lastObject];
    cell3.addressLabel.text = self.applicationDetail[@"applicationBundle"];
    
    XXTEMoreRemoteAddressCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteAddressCell class]) owner:nil options:nil] lastObject];
    cell4.addressLabel.text = self.applicationDetail[@"applicationContainer"];
    
    XXTEMoreActionCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreActionCell class]) owner:nil options:nil] lastObject];
    cell5.actionNameLabel.textColor = XXTE_COLOR_DANGER;
    cell5.actionNameLabel.text = NSLocalizedString(@"Clean Application Data", nil);
    
    staticSectionRowNum = @[ @2, @1, @1, @1 ];
    
    staticCells = @[
                    @[ cell1, cell2 ],
                    //
                    @[ cell3 ],
                    //
                    @[ cell4 ],
                    //
                    @[ cell5 ]
                    ];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return kXXTEMoreApplicationDetailSectionIndexMax;
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
        if (indexPath.section == kXXTEMoreApplicationDetailSectionIndexBundlePath || indexPath.section == kXXTEMoreApplicationDetailSectionIndexContainerPath) {
            return UITableViewAutomaticDimension;
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreApplicationDetailSectionIndexDetail) {
            NSString *detailText = ((XXTEMoreTitleValueCell *)staticCells[indexPath.section][indexPath.row]).valueLabel.text;
            blockUserInteractions(self.navigationController.view, YES);
            [PMKPromise promiseWithValue:@YES].then(^() {
                [[UIPasteboard generalPasteboard] setString:detailText];
            }).finally(^() {
                showUserMessage(self.navigationController.view, NSLocalizedString(@"Copied to the pasteboard.", nil));
                blockUserInteractions(self.navigationController.view, NO);
            });
        } else if (indexPath.section == kXXTEMoreApplicationDetailSectionIndexBundlePath || indexPath.section == kXXTEMoreApplicationDetailSectionIndexContainerPath) {
            NSString *detailText = ((XXTEMoreRemoteAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
            blockUserInteractions(self.navigationController.view, YES);
            [PMKPromise promiseWithValue:@YES].then(^() {
                [[UIPasteboard generalPasteboard] setString:detailText];
            }).finally(^() {
                showUserMessage(self.navigationController.view, NSLocalizedString(@"Path has been copied to the pasteboard.", nil));
                blockUserInteractions(self.navigationController.view, NO);
            });
        } else if (indexPath.section == kXXTEMoreApplicationDetailSectionIndexAction) {
            if (indexPath.row == 0) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clean Confirm", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Clean all the data of the application \"%@\"?\nThis operation cannot be revoked.", nil), self.applicationDetail[@"applicationIdentifier"]]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                                   delegate:self];
                [alertView showAnimated:YES completionHandler:nil];
            }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return staticCells[indexPath.section][indexPath.row];
    }
    return [UITableViewCell new];
}


#pragma mark - LGAlertViewDelegate

- (void)alertView:(LGAlertView *)alertView clickedButtonAtIndex:(NSUInteger)index title:(NSString *)title {
    if (index == 0) {
        
    }
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
}

@end
