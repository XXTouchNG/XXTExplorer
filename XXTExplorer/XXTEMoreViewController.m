//
//  XXTEMoreViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreCell.h"
#import "XXTEMoreViewController.h"
#import <PromiseKit/PromiseKit.h>
#import "NSURLConnection+PromiseKit.h"
#import "UIView+XXTEToast.h"
#import "XXTENetworkDefines.h"
#import "XXTEMoreApplicationListController.h"

typedef enum : NSUInteger {
    kXXTEMoreSectionIndexRemote = 0,
    kXXTEMoreSectionIndexService,
    kXXTEMoreSectionIndexAuthentication,
    kXXTEMoreSectionIndexSettings,
    kXXTEMoreSectionIndexSystem,
    kXXTEMoreSectionIndexHelp,
    kXXTEMoreSectionIndexMax
} kXXTEMoreSectionIndex;

@interface XXTEMoreViewController ()
@property (weak, nonatomic) UISwitch *remoteAccessSwitch;

@end

@implementation XXTEMoreViewController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSNumber *> *staticSectionRowNum;
    NSString *webServerUrl;
    NSString *bonjourWebServerUrl;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"More", nil);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self reloadStaticTableViewData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    blockUserInteractions(self.navigationController.view, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"is_remote_access_opened") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            BOOL remoteAccessStatus = [jsonDictionary[@"data"][@"opened"] boolValue];
            if (remoteAccessStatus) {
                webServerUrl = jsonDictionary[@"data"][@"webserver_url"];
                bonjourWebServerUrl = jsonDictionary[@"data"][@"bonjour_webserver_url"];
                if (webServerUrl.length == 0 || bonjourWebServerUrl.length == 0) {
                    @throw NSLocalizedString(@"Please connected to Wi-fi network and try again later.", nil);
                }
            } else {
                webServerUrl = nil;
                bonjourWebServerUrl = nil;
            }
            [self reloadStaticTableViewData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kXXTEMoreSectionIndexRemote] withRowAnimation:UITableViewRowAnimationAutomatic];
            self.remoteAccessSwitch.on = remoteAccessStatus;
        }
    }).catch(^(NSError *serverError) {
         showUserMessage(self.navigationController.view, [serverError localizedDescription]);
    }).finally(^() {
        blockUserInteractions(self.navigationController.view, NO);
    });
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"Remote", @"Daemon", @"Authentication", @"Settings", @"System", @"Help" ];
    
    XXTEMoreRemoteSwitchCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteSwitchCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Remote Access", nil);
    cell1.selectionStyle = UITableViewCellSelectionStyleNone;
    cell1.imageView.image = [UIImage imageNamed:@"XXTEMoreIconRemoteAccess"];
    [cell1.optionSwitch addTarget:self action:@selector(remoteAccessOptionSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.remoteAccessSwitch = cell1.optionSwitch;
    
    XXTEMoreLinkCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryNone;
    cell2.imageView.image = [UIImage imageNamed:@"XXTEMoreIconRestartService"];
    cell2.titleLabel.text = NSLocalizedString(@"Restart Service", nil);
    
    XXTEMoreLinkCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.imageView.image = [UIImage imageNamed:@"XXTEMoreIconAuthentication"];
    cell3.titleLabel.text = NSLocalizedString(@"Authentication", nil);
    
    XXTEMoreLinkCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell4.imageView.image = [UIImage imageNamed:@"XXTEMoreIconActivationConfig"];
    cell4.titleLabel.text = NSLocalizedString(@"Activation Config", nil);
    
    XXTEMoreLinkCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell5.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell5.imageView.image = [UIImage imageNamed:@"XXTEMoreIconRecordingConfig"];
    cell5.titleLabel.text = NSLocalizedString(@"Recording Config", nil);
    
    XXTEMoreLinkCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell6.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell6.imageView.image = [UIImage imageNamed:@"XXTEMoreIconBootConfig"];
    cell6.titleLabel.text = NSLocalizedString(@"Boot Config", nil);
    
    XXTEMoreLinkCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell7.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell7.imageView.image = [UIImage imageNamed:@"XXTEMoreIconUserDefaults"];
    cell7.titleLabel.text = NSLocalizedString(@"User Defaults", nil);
    
    XXTEMoreLinkCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell8.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell8.imageView.image = [UIImage imageNamed:@"XXTEMoreIconApplicationList"];
    cell8.titleLabel.text = NSLocalizedString(@"Application List", nil);
    
    XXTEMoreLinkCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell9.accessoryType = UITableViewCellAccessoryNone;
    cell9.imageView.image = [UIImage imageNamed:@"XXTEMoreIconCleanGPSCaches"];
    cell9.titleLabel.text = NSLocalizedString(@"Clean GPS Caches", nil);
    
    XXTEMoreLinkCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell10.accessoryType = UITableViewCellAccessoryNone;
    cell10.imageView.image = [UIImage imageNamed:@"XXTEMoreIconCleanUICaches"];
    cell10.titleLabel.text = NSLocalizedString(@"Clean UI Caches", nil);
    
    XXTEMoreLinkCell *cell11 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell11.accessoryType = UITableViewCellAccessoryNone;
    cell11.imageView.image = [UIImage imageNamed:@"XXTEMoreIconCleanAll"];
    cell11.titleLabel.text = NSLocalizedString(@"Clean All", nil);
    
    XXTEMoreLinkCell *cell12 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell12.accessoryType = UITableViewCellAccessoryNone;
    cell12.imageView.image = [UIImage imageNamed:@"XXTEMoreIconRespringDevice"];
    cell12.titleLabel.text = NSLocalizedString(@"Respring Device", nil);
    
    XXTEMoreLinkCell *cell13 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell13.accessoryType = UITableViewCellAccessoryNone;
    cell13.imageView.image = [UIImage imageNamed:@"XXTEMoreIconRestartDevice"];
    cell13.titleLabel.text = NSLocalizedString(@"Restart Device", nil);
    
    XXTEMoreLinkCell *cell14 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell14.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell14.imageView.image = [UIImage imageNamed:@"XXTEMoreIconDocumentsOnline"];
    cell14.titleLabel.text = NSLocalizedString(@"Documents (Online)", nil);
    
    XXTEMoreLinkCell *cell15 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell15.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell15.imageView.image = [UIImage imageNamed:@"XXTEMoreIconAbout"];
    cell15.titleLabel.text = NSLocalizedString(@"About", nil);
    
    XXTEMoreRemoteAddressCell *cellAddress1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteAddressCell class]) owner:nil options:nil] lastObject];
    cellAddress1.addressLabel.text = webServerUrl ? webServerUrl : @"N/A";
    
    XXTEMoreRemoteAddressCell *cellAddress2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteAddressCell class]) owner:nil options:nil] lastObject];
    cellAddress2.addressLabel.text = bonjourWebServerUrl ? bonjourWebServerUrl : @"N/A";
    
    if (webServerUrl && bonjourWebServerUrl) {
        staticSectionRowNum = @[ @3, @1, @1, @4, @6, @2 ];
    } else {
        staticSectionRowNum = @[ @1, @1, @1, @4, @6, @2 ];
    }
    
    staticCells = @[
                    @[ cell1, cellAddress1, cellAddress2 ],
                    //
                    @[ cell2 ],
                    //
                    @[ cell3 ],
                    //
                    @[ cell4, cell5, cell6, cell7 ],
                    //
                    @[ cell8, cell9, cell10, cell11, cell12, cell13 ],
                    //
                    @[ cell14, cell15 ],
                    ];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return kXXTEMoreSectionIndexMax;
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
        if (indexPath.section == kXXTEMoreSectionIndexRemote) {
            if (indexPath.row == 0) {
                return 66.f;
            } else {
                return UITableViewAutomaticDimension;
            }
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreSectionIndexRemote) {
            if (indexPath.row > 0) {
                NSString *addressText = ((XXTEMoreRemoteAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
                if (addressText && addressText.length > 0) {
                    blockUserInteractions(self.navigationController.view, YES);
                    [PMKPromise promiseWithValue:@YES].then(^() {
                        [[UIPasteboard generalPasteboard] setString:addressText];
                    }).finally(^() {
                        showUserMessage(self.navigationController.view, NSLocalizedString(@"Remote address has been copied to the pasteboard.", nil));
                        blockUserInteractions(self.navigationController.view, NO);
                    });
                }
            }
        }
        else if (indexPath.section == kXXTEMoreSectionIndexSystem) {
            if (indexPath.row == 0) {
                XXTEMoreApplicationListController *applicationListController = [[XXTEMoreApplicationListController alloc] init];
                [self.navigationController pushViewController:applicationListController animated:YES];
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

#pragma mark - UIControl Actions

- (void)remoteAccessOptionSwitchChanged:(UISwitch *)sender {
    if (sender == self.remoteAccessSwitch) {
        BOOL changeToStatus = sender.on;
        NSString *changeToCommand = nil;
        if (changeToStatus)
            changeToCommand = @"open_remote_access";
        else
            changeToCommand = @"close_remote_access";
        blockUserInteractions(self.navigationController.view, YES);
        [NSURLConnection POST:uAppDaemonCommandUrl(changeToCommand) JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                if (changeToStatus == YES) {
                    webServerUrl = jsonDictionary[@"data"][@"webserver_url"];
                    bonjourWebServerUrl = jsonDictionary[@"data"][@"bonjour_webserver_url"];
                    if (webServerUrl.length == 0 || bonjourWebServerUrl.length == 0) {
                        @throw NSLocalizedString(@"Please connected to Wi-fi network and try again later.", nil);
                    }
                } else {
                    webServerUrl = nil;
                    bonjourWebServerUrl = nil;
                }
                [self reloadStaticTableViewData];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kXXTEMoreSectionIndexRemote] withRowAnimation:UITableViewRowAnimationAutomatic];
                self.remoteAccessSwitch.on = changeToStatus;
            }
        }).catch(^(NSError *serverError) {
            showUserMessage(self.navigationController.view, [serverError localizedDescription]);
            sender.on = !changeToStatus;
        }).finally(^() {
            blockUserInteractions(self.navigationController.view, NO);
        });
    }
}

@end
