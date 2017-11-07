//
//  XXTEMoreViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreViewController.h"
#import "XXTEMoreLinkCell.h"
#import "UIView+XXTEToast.h"
#import "XXTEMoreUserDefaultsController.h"
#import "XXTEUIViewController.h"

#ifndef APPSTORE
    #import <objc/runtime.h>
    #import <objc/message.h>
    #import "XXTEMoreRemoteSwitchCell.h"
    #import "XXTEMoreAddressCell.h"
    #import <LGAlertView/LGAlertView.h>
    #import <PromiseKit/PromiseKit.h>
    #import <PromiseKit/NSURLConnection+PromiseKit.h>
    #import "XXTENetworkDefines.h"
    #import "XXTEMoreApplicationListController.h"
    #import "XXTEMoreLicenseController.h"
    #import "XXTEMoreActivationController.h"
    #import "XXTEMoreRecordingController.h"
    #import "XXTENotificationCenterDefines.h"
    #import "XXTEMoreBootScriptController.h"
#endif

#ifndef APPSTORE

    typedef enum : NSUInteger {
        kXXTEMoreSectionIndexRemote = 0,
        kXXTEMoreSectionIndexDaemon,
        kXXTEMoreSectionIndexLicense,
        kXXTEMoreSectionIndexSettings,
        kXXTEMoreSectionIndexSystem,
        kXXTEMoreSectionIndexHelp,
        kXXTEMoreSectionIndexMax
    } kXXTEMoreSectionIndex;

    typedef enum : NSUInteger {
        kXXTEMoreSectionSettingsRowIndexActivationConfig = 0,
        kXXTEMoreSectionSettingsRowIndexRecordingConfig,
        kXXTEMoreSectionSettingsRowIndexBootScript,
        kXXTEMoreSectionSettingsRowIndexUserDefaults,
    } kXXTEMoreSectionSettingsRowIndex;

    typedef enum : NSUInteger {
        kXXTEMoreSectionHelpRowIndexDocuments = 0,
        kXXTEMoreSectionHelpRowIndexAbout,
    } kXXTEMoreSectionHelpRowIndex;

#else

    typedef enum : NSUInteger {
        kXXTEMoreSectionIndexSettings = 0,
        kXXTEMoreSectionIndexHelp,
        kXXTEMoreSectionIndexMax
    } kXXTEMoreSectionIndex;

    typedef enum : NSUInteger {
        kXXTEMoreSectionSettingsRowIndexUserDefaults = 0,
    } kXXTEMoreSectionSettingsRowIndex;

    typedef enum : NSUInteger {
        kXXTEMoreSectionHelpRowIndexAbout = 0,
    } kXXTEMoreSectionHelpRowIndex;

#endif

#ifndef APPSTORE
@interface XXTEMoreViewController () <LGAlertViewDelegate>
@property (weak, nonatomic) UISwitch *remoteAccessSwitch;
@property (weak, nonatomic) UIActivityIndicatorView *remoteAccessIndicator;

@end
#endif

@implementation XXTEMoreViewController {
    BOOL isFirstTimeLoaded;
    NSArray <NSMutableArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
    NSString *webServerUrl;
    NSString *bonjourWebServerUrl;
    BOOL isFetchingRemoteStatus;
}

#pragma mark - Initializers

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"More", nil);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }
    
    [self reloadStaticTableViewData];
    
#ifndef APPSTORE
    [self reloadDynamicTableViewData];
#endif
    
}

#ifndef APPSTORE
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (isFirstTimeLoaded) {
        [self reloadDynamicTableViewData];
    }
    isFirstTimeLoaded = YES;
}
#endif

#ifndef APPSTORE
- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
    [super viewWillAppear:animated];
}
#endif

#ifndef APPSTORE
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}
#endif

#ifndef APPSTORE
- (void)updateRemoteAccessAddressDisplay {
    XXTEMoreRemoteSwitchCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteSwitchCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Remote Access", nil);
    cell1.selectionStyle = UITableViewCellSelectionStyleNone;
    cell1.imageView.image = [UIImage imageNamed:@"XXTEMoreIconRemoteAccess"];
    [cell1.optionSwitch addTarget:self action:@selector(remoteAccessOptionSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.remoteAccessSwitch = cell1.optionSwitch;
    self.remoteAccessIndicator = cell1.optionIndicator;
    
    XXTEMoreAddressCell *cellAddress1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    XXTEMoreAddressCell *cellAddress2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    if (webServerUrl.length != 0) {
        cellAddress1.addressLabel.textColor = [UIColor blackColor];
        cellAddress1.addressLabel.text = webServerUrl;
    } else {
        cellAddress1.addressLabel.textColor = XXTE_COLOR_DANGER;
        cellAddress1.addressLabel.text = NSLocalizedString(@"Connect to Wi-fi network.", nil);
    }
    cellAddress2.addressLabel.text = bonjourWebServerUrl ? bonjourWebServerUrl : NSLocalizedString(@"N/A", nil);
    
    staticCells[0][0] = cell1;
    staticCells[0][1] = cellAddress1;
    staticCells[0][2] = cellAddress2;
    
    if (webServerUrl && bonjourWebServerUrl) {
        staticSectionRowNum = @[ @3, @1, @1, @4, @6, @2 ];
    } else {
        staticSectionRowNum = @[ @1, @1, @1, @4, @6, @2 ];
    }
}
#endif

#ifndef APPSTORE
- (void)reloadDynamicTableViewData {
    if (!isFetchingRemoteStatus) {
        isFetchingRemoteStatus = YES;
        [self.remoteAccessSwitch setHidden:YES];
        [self.remoteAccessIndicator startAnimating];
        [NSURLConnection POST:uAppDaemonCommandUrl(@"is_remote_access_opened") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                BOOL remoteAccessStatus = [jsonDictionary[@"data"][@"opened"] boolValue];
                if (remoteAccessStatus) {
                    webServerUrl = jsonDictionary[@"data"][@"webserver_url"];
                    bonjourWebServerUrl = jsonDictionary[@"data"][@"bonjour_webserver_url"];
                } else {
                    webServerUrl = nil;
                    bonjourWebServerUrl = nil;
                }
                [self updateRemoteAccessAddressDisplay];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kXXTEMoreSectionIndexRemote] withRowAnimation:UITableViewRowAnimationAutomatic];
                if (self.remoteAccessSwitch.isOn != remoteAccessStatus) {
                    [self.remoteAccessSwitch setOn:remoteAccessStatus];
                }
            }
        }).catch(^(NSError *serverError) {
            if (serverError.code == -1004) {
                toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                toastMessage(self, [serverError localizedDescription]);
            }
        }).finally(^() {
            [self.remoteAccessIndicator stopAnimating];
            [self.remoteAccessSwitch setHidden:NO];
            isFetchingRemoteStatus = NO;
        });
    }
}
#endif

- (void)reloadStaticTableViewData {
#ifndef APPSTORE
    
    staticSectionTitles = @[ NSLocalizedString(@"Remote", nil),
                             NSLocalizedString(@"Daemon", nil),
                             NSLocalizedString(@"License", nil),
                             NSLocalizedString(@"Settings", nil),
                             NSLocalizedString(@"System", nil),
                             NSLocalizedString(@"Help", nil)];
    staticSectionFooters = @[ NSLocalizedString(@"Turn on the switch: \n- Access the Web Client. \n- Access the WebDAV server.", nil), @"", @"", @"", @"", @"" ];
    staticSectionRowNum = @[ @1, @1, @1, @4, @6, @2 ];
    
#else
    
    staticSectionTitles = @[ @"", @"" ];
    staticSectionFooters = @[ @"", @"" ];
    staticSectionRowNum = @[ @1, @1 ];
    
#endif
    
#ifndef APPSTORE
    
    XXTEMoreRemoteSwitchCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteSwitchCell class]) owner:nil options:nil] lastObject];
    
    XXTEMoreLinkCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryNone;
    cell2.imageView.image = [UIImage imageNamed:@"XXTEMoreIconRestartDaemon"];
    cell2.titleLabel.text = NSLocalizedString(@"Restart Daemon", nil);
    
    XXTEMoreLinkCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.imageView.image = [UIImage imageNamed:@"XXTEMoreIconLicense"];
    cell3.titleLabel.text = NSLocalizedString(@"My License", nil);
    
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
    cell6.imageView.image = [UIImage imageNamed:@"XXTEMoreIconBootScript"];
    cell6.titleLabel.text = NSLocalizedString(@"Boot Script", nil);
    
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
    cell13.imageView.image = [UIImage imageNamed:@"XXTEMoreIconRebootDevice"];
    cell13.titleLabel.text = NSLocalizedString(@"Restart Device", nil);
    
    XXTEMoreLinkCell *cell14 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell14.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell14.imageView.image = [UIImage imageNamed:@"XXTEMoreIconDocumentsOnline"];
    cell14.titleLabel.text = NSLocalizedString(@"Online Documents", nil);
    
    XXTEMoreLinkCell *cell15 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell15.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell15.imageView.image = [UIImage imageNamed:@"XXTEMoreIconAbout"];
    cell15.titleLabel.text = NSLocalizedString(@"About", nil);
    
    XXTEMoreAddressCell *cellAddress1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    
    XXTEMoreAddressCell *cellAddress2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    
#else
    
    XXTEMoreLinkCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell7.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell7.imageView.image = [UIImage imageNamed:@"XXTEMoreIconUserDefaults"];
    cell7.titleLabel.text = NSLocalizedString(@"User Defaults", nil);
    
    XXTEMoreLinkCell *cell15 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell15.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell15.imageView.image = [UIImage imageNamed:@"XXTEMoreIconAbout"];
    cell15.titleLabel.text = NSLocalizedString(@"About", nil);
    
#endif
    
#ifndef APPSTORE
    
    staticCells = @[
                    [@[ cell1, cellAddress1, cellAddress2 ] mutableCopy],
                    //
                    [@[ cell2 ] mutableCopy],
                    //
                    [@[ cell3 ] mutableCopy],
                    //
                    [@[ cell4, cell5, cell6, cell7 ] mutableCopy],
                    //
                    [@[ cell8, cell9, cell10, cell11, cell12, cell13 ] mutableCopy],
                    //
                    [@[ cell14, cell15 ] mutableCopy],
                    ];
    
#else
    
    staticCells = @[
                    //
                    [@[ cell7 ] mutableCopy],
                    //
                    [@[ cell15 ] mutableCopy],
                    ];
    
#endif
    
#ifndef APPSTORE
    [self updateRemoteAccessAddressDisplay];
#endif
    
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

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
#ifndef APPSTORE
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreSectionIndexRemote) {
            if (indexPath.row == 0) {
                return 66.f;
            }
        }
    }
#endif
    return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
#ifndef APPSTORE
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreSectionIndexRemote) {
            if (indexPath.row == 0) {
                return 66.f;
            } else {
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
            }
        }
    }
#endif
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
#ifndef APPSTORE
    
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreSectionIndexRemote) {
            if (indexPath.row > 0) {
                NSString *addressText = @"";
                if (indexPath.row == 1) {
                    addressText = webServerUrl;
                } else if (indexPath.row == 2) {
                    addressText = bonjourWebServerUrl;
                }
                if (addressText && addressText.length > 0) {
                    blockInteractions(self, YES);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:addressText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        toastMessage(self, NSLocalizedString(@"Remote address has been copied to the pasteboard.", nil));
                        blockInteractions(self, NO);
                    });
                }
            }
        }
        else
        if (indexPath.section == kXXTEMoreSectionIndexDaemon) {
            if (indexPath.row == 0) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Restart Daemon", nil)
                                                                    message:NSLocalizedString(@"This operation will restart daemon, and wait until it launched.", nil)
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Restart Now", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:restartDaemon:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
            }
        }
        else
        if (indexPath.section == kXXTEMoreSectionIndexLicense) {
            if (indexPath.row == 0) {
                XXTEMoreLicenseController *licenseController = [[XXTEMoreLicenseController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:licenseController animated:YES];
            }
        }
        else
        if (indexPath.section == kXXTEMoreSectionIndexSettings) {
            if (indexPath.row == kXXTEMoreSectionSettingsRowIndexActivationConfig) {
                XXTEMoreActivationController *activationController = [[XXTEMoreActivationController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:activationController animated:YES];
            } else if (indexPath.row == kXXTEMoreSectionSettingsRowIndexRecordingConfig) {
                XXTEMoreRecordingController *recordingController = [[XXTEMoreRecordingController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:recordingController animated:YES];
            } else if (indexPath.row == kXXTEMoreSectionSettingsRowIndexBootScript) {
                XXTEMoreBootScriptController *bootController = [[XXTEMoreBootScriptController alloc] initWithStyle:UITableViewStyleGrouped];
                [self.navigationController pushViewController:bootController animated:YES];
            } else if (indexPath.row == kXXTEMoreSectionSettingsRowIndexUserDefaults) {
                XXTEMoreUserDefaultsController *userDefaultsController = [[XXTEMoreUserDefaultsController alloc] initWithStyle:UITableViewStylePlain];
                [self.navigationController pushViewController:userDefaultsController animated:YES];
            }
        }
        else
        if (indexPath.section == kXXTEMoreSectionIndexSystem) {
            if (indexPath.row == 0) {
                XXTEMoreApplicationListController *applicationListController = [[XXTEMoreApplicationListController alloc] init];
                [self.navigationController pushViewController:applicationListController animated:YES];
            }
            else if (indexPath.row == 1) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clean GPS Caches", nil)
                                                                    message:NSLocalizedString(@"This operation will reset system location caches.", nil)
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clean Now", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:cleanGPSCaches:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
            }
            else if (indexPath.row == 2) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clean UI Caches", nil)
                                                                    message:NSLocalizedString(@"This operation will kill all applications and reset icon caches, which may cause icons to disappear.", nil)
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clean Now", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:cleanUICaches:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
            }
            else if (indexPath.row == 3) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clean All", nil)
                                                                    message:NSLocalizedString(@"This operation will kill all user applications, and remove all the documents and caches of them.", nil)
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clean Now", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:cleanAll:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
            }
            else if (indexPath.row == 4) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Respring Device", nil)
                                                                    message:NSLocalizedString(@"This operation will kill SpringBoard and all user applications.", nil)
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Respring Now", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:respringDevice:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
            }
            else if (indexPath.row == 5) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Reboot Device", nil)
                                                                    message:NSLocalizedString(@"This operation will shut down the device and launch it again.", nil)
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Reboot Now", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:rebootDevice:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
            }
        }
        else
        if (indexPath.section == kXXTEMoreSectionIndexHelp) {
#ifndef APPSTORE
            NSString *settingsBundlePath = [[[NSBundle bundleForClass:[self classForCoder]] resourcePath] stringByAppendingPathComponent:@"Settings.Pro.bundle"];
#else
            NSString *settingsBundlePath = [[[NSBundle bundleForClass:[self classForCoder]] resourcePath] stringByAppendingPathComponent:@"Settings.bundle"];
#endif
            if (indexPath.row == kXXTEMoreSectionHelpRowIndexDocuments) {
                NSString *settingsUIPath = [settingsBundlePath stringByAppendingPathComponent:@"Documents.plist"];
                XXTEUIViewController *xuiController = [[XXTEUIViewController alloc] initWithPath:settingsUIPath withBundlePath:settingsBundlePath];
                xuiController.hidesBottomBarWhenPushed = NO;
                [self.navigationController pushViewController:xuiController animated:YES];
            }
            else if (indexPath.row == kXXTEMoreSectionHelpRowIndexAbout) {
                NSString *settingsUIPath = [settingsBundlePath stringByAppendingPathComponent:@"About.plist"];
                XXTEUIViewController *xuiController = [[XXTEUIViewController alloc] initWithPath:settingsUIPath withBundlePath:settingsBundlePath];
                xuiController.hidesBottomBarWhenPushed = NO;
                [self.navigationController pushViewController:xuiController animated:YES];
            }
        }
    }
    
#else
    
    if (indexPath.section == kXXTEMoreSectionIndexSettings) {
        if (indexPath.row == kXXTEMoreSectionSettingsRowIndexUserDefaults) {
            XXTEMoreUserDefaultsController *userDefaultsController = [[XXTEMoreUserDefaultsController alloc] initWithStyle:UITableViewStylePlain];
            [self.navigationController pushViewController:userDefaultsController animated:YES];
        }
    }
    else
    if (indexPath.section == kXXTEMoreSectionIndexHelp) {
#ifndef APPSTORE
        NSString *settingsBundlePath = [[[NSBundle bundleForClass:[self classForCoder]] resourcePath] stringByAppendingPathComponent:@"Settings.Pro.bundle"];
#else
        NSString *settingsBundlePath = [[[NSBundle bundleForClass:[self classForCoder]] resourcePath] stringByAppendingPathComponent:@"Settings.bundle"];
#endif
        if (indexPath.row == kXXTEMoreSectionHelpRowIndexAbout) {
            NSString *settingsUIPath = [settingsBundlePath stringByAppendingPathComponent:@"About.plist"];
            XXTEUIViewController *xuiController = [[XXTEUIViewController alloc] initWithPath:settingsUIPath withBundlePath:settingsBundlePath];
            xuiController.hidesBottomBarWhenPushed = NO;
            [self.navigationController pushViewController:xuiController animated:YES];
        }
    }
    
#endif
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

#ifndef APPSTORE
- (void)remoteAccessOptionSwitchChanged:(UISwitch *)sender {
    if (sender == self.remoteAccessSwitch) {
        BOOL changeToStatus = sender.on;
        NSString *changeToCommand = nil;
        if (changeToStatus)
            changeToCommand = @"open_remote_access";
        else
            changeToCommand = @"close_remote_access";
        blockInteractions(self, YES);
        [self.remoteAccessSwitch setHidden:YES];
        [self.remoteAccessIndicator startAnimating];
        [NSURLConnection POST:uAppDaemonCommandUrl(changeToCommand) JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                if (changeToStatus == YES) {
                    webServerUrl = jsonDictionary[@"data"][@"webserver_url"];
                    bonjourWebServerUrl = jsonDictionary[@"data"][@"bonjour_webserver_url"];
                } else {
                    webServerUrl = nil;
                    bonjourWebServerUrl = nil;
                }
                [self updateRemoteAccessAddressDisplay];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kXXTEMoreSectionIndexRemote] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.remoteAccessSwitch setOn:changeToStatus animated:YES];
            }
        }).catch(^(NSError *serverError) {
            if (serverError.code == -1004) {
                toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                toastMessage(self, [serverError localizedDescription]);
            }
            [self.remoteAccessSwitch setOn:!changeToStatus animated:YES];
        }).finally(^() {
            [self.remoteAccessIndicator stopAnimating];
            [self.remoteAccessSwitch setHidden:NO];
            blockInteractions(self, NO);
        });
    }
}
#endif

#pragma mark - LGAlertViewDelegate

#ifndef APPSTORE
- (void)alertViewDestructed:(LGAlertView *)alertView {
    SEL selectors[] = {
        @selector(alertView:restartDaemon:),
        @selector(alertView:cleanGPSCaches:),
        @selector(alertView:cleanUICaches:),
        @selector(alertView:cleanAll:),
        @selector(alertView:respringDevice:),
        @selector(alertView:rebootDevice:)
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    for (int i = 0; i < sizeof(selectors) / sizeof(SEL); i++) {
        SEL selector = selectors[i];
        id obj = objc_getAssociatedObject(alertView, selector);
        if (obj) {
            objc_setAssociatedObject(alertView, selector, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [self performSelector:selector withObject:alertView withObject:obj];
            break;
        }
    }
    objc_removeAssociatedObjects(alertView);
#pragma clang diagnostic pop
}
#endif

#ifndef APPSTORE
- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
}
#endif

#pragma mark - LGAlertView Actions

#ifndef APPSTORE
- (void)alertView:(LGAlertView *)alertView cleanGPSCaches:(id)obj {
    [alertView dismissAnimated];
    blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"clear_gps") formURLEncodedParameters:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        } else {
            toastMessage(self, jsonDictionary[@"message"]);
        }
    }).catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    }).finally(^() {
        blockInteractions(self, NO);
    });
}
#endif

#ifndef APPSTORE
- (void)alertView:(LGAlertView *)alertView cleanUICaches:(id)obj {
    [alertView dismissAnimated];
    blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"uicache") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        }
    }).catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    }).finally(^() {
        blockInteractions(self, NO);
    });
}
#endif

#ifndef APPSTORE
- (void)alertView:(LGAlertView *)alertView cleanAll:(id)obj {
    [alertView dismissAnimated];
    blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"clear_all") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        }
    }).catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    }).finally(^() {
        blockInteractions(self, NO);
    });
}
#endif

#ifndef APPSTORE
- (void)alertView:(LGAlertView *)alertView respringDevice:(id)obj {
    [alertView dismissAnimated];
    blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"respring") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        }
    }).catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    }).finally(^() {
        blockInteractions(self, NO);
    });
}
#endif

#ifndef APPSTORE
- (void)alertView:(LGAlertView *)alertView rebootDevice:(id)obj {
    [alertView dismissAnimated];
    blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"reboot2") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        }
    }).catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    }).finally(^() {
        blockInteractions(self, NO);
    });
}
#endif

#ifndef APPSTORE
- (void)alertView:(LGAlertView *)alertView restartDaemon:(id)obj {
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Restart Daemon", nil)
                                                                             message:NSLocalizedString(@"Restart daemon, please wait...", nil)
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:nil
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:nil
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    [NSURLConnection POST:uAppDaemonCommandUrl(@"restart") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            [self performSelector:@selector(alertViewRestartDaemonCheckLaunched:) withObject:alertView1 afterDelay:1.f];
        }
    }).catch(^(NSError *serverError) {
        LGAlertView *alertView2 = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Failed", nil)
                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Could not connect to the daemon: %@", nil), [serverError localizedDescription]]
                                                               style:LGAlertViewStyleActionSheet
                                                        buttonTitles:@[  ]
                                                   cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                              destructiveButtonTitle:nil
                                                            delegate:self];
        if (alertView1 && alertView1.isShowing) {
            [alertView1 transitionToAlertView:alertView2 completionHandler:nil];
        }
    }).finally(^() {
        
    });
}
#endif

#ifndef APPSTORE
- (void)alertViewRestartDaemonCheckLaunched:(LGAlertView *)alertView {
    [NSURLConnection POST:uAppDaemonCommandUrl(@"get_selected_script_file") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            LGAlertView *alertView1 = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Daemon Restarted", nil)
                                                                 message:NSLocalizedString(@"The daemon has been restarted.", nil)
                                                                   style:LGAlertViewStyleActionSheet
                                                            buttonTitles:@[  ]
                                                       cancelButtonTitle:NSLocalizedString(@"Done", nil)
                                                  destructiveButtonTitle:nil
                                                                delegate:self];
            if (alertView && alertView.isShowing) {
                [alertView transitionToAlertView:alertView1 completionHandler:nil];
            }
        }
    }).catch(^(NSError *serverError) {
        if (serverError.code == -1004 || serverError.code == -1005) {
            [self performSelector:@selector(alertViewRestartDaemonCheckLaunched:) withObject:alertView afterDelay:3.f];
        } else {
            LGAlertView *alertView2 = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Failed", nil)
                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"Cannot restart daemon: %@", nil), [serverError localizedDescription]]
                                                                   style:LGAlertViewStyleActionSheet
                                                            buttonTitles:@[  ]
                                                       cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                                  destructiveButtonTitle:nil
                                                                delegate:self];
            if (alertView && alertView.isShowing) {
                [alertView transitionToAlertView:alertView2 completionHandler:nil];
            }
        }
    }).finally(^() {
        
    });
}
#endif

#pragma mark - Notifications

#ifndef APPSTORE
- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidBecomeActive]) {
        [self reloadDynamicTableViewData];
    }
}
#endif

@end
