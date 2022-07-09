//
//  XXTEMoreViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreViewController.h"
#import "XXTEMoreUserDefaultsController.h"
#import "XXTEDetailViewController.h"
#import "XXTENavigationController.h"

#import "XXTExplorerViewController+SharedInstance.h"
#import "XXTExplorerEntryService.h"
#import "UIDevice+IPAddress.h"

#import <LGAlertView/LGAlertView.h>
#import "UIView+XXTEToast.h"
#import "XXTEMoreRemoteSwitchCell.h"
#import "XXTEMoreAddressCell.h"
#import "XXTEMoreLinkCell.h"

#import <objc/runtime.h>
#import <objc/message.h>

#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import "XXTEMoreApplicationListController.h"
#import "XXTEMoreLicenseController.h"
#import "XXTEMoreActivationController.h"
#import "XXTEMoreBootScriptController.h"
#import "XXTEConfirmTextInputObject.h"
#import "XXTERespringAgent.h"

typedef enum : NSUInteger {
    kXXTEMoreSectionIndexRemote = 0,
    kXXTEMoreSectionIndexDaemon,
    kXXTEMoreSectionIndexLicense,
    kXXTEMoreSectionIndexSettings,
    kXXTEMoreSectionIndexSystem,
    kXXTEMoreSectionIndexLog,
    kXXTEMoreSectionIndexHelp,
    kXXTEMoreSectionIndexMax
} kXXTEMoreSectionIndex;

typedef enum : NSUInteger {
    kXXTEMoreSectionSystemRowIndexApplicationList = 0,
    kXXTEMoreSectionSystemRowIndexCleanGPSCaches,
    kXXTEMoreSectionSystemRowIndexCleanUICaches,
    kXXTEMoreSectionSystemRowIndexCleanAll,
    kXXTEMoreSectionSystemRowIndexRespringDevice,
    kXXTEMoreSectionSystemRowIndexRestartDevice
} kXXTEMoreSectionSystemRowIndex;

typedef enum : NSUInteger {
    kXXTEMoreSectionSettingsRowIndexActivationConfig = 0,
    kXXTEMoreSectionSettingsRowIndexBootScript,
    kXXTEMoreSectionSettingsRowIndexUserDefaults,
} kXXTEMoreSectionSettingsRowIndex;

static NSString * const kXXTEDaemonLogViewerName = @"DAEMON_LOG_VIEWER";
static NSString * const kXXTEDaemonLogPath = @"DAEMON_LOG_PATH";
static NSString * const kXXTEDaemonErrorLogPath = @"DAEMON_ERROR_LOG_PATH";

typedef enum : NSUInteger {
    kXXTEMoreSectionLogRowIndexLog = 0,
    kXXTEMoreSectionLogRowIndexErrorLog,
} kXXTEMoreSectionLogRowIndex;

typedef enum : NSUInteger {
    kXXTEMoreSectionHelpRowIndexDocuments = 0,
    kXXTEMoreSectionHelpRowIndexAbout,
} kXXTEMoreSectionHelpRowIndex;

@interface XXTEMoreViewController () <LGAlertViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *closeItem;
@property (weak, nonatomic) UISwitch *remoteAccessSwitch;
@property (weak, nonatomic) UIActivityIndicatorView *remoteAccessIndicator;

@end

@implementation XXTEMoreViewController {
    BOOL isFirstTimeLoaded;
    NSArray <NSMutableArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
    NSString *_webServerUrl;
    NSString *_bonjourWebServerUrl;
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
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    
    self.title = NSLocalizedString(@"More", nil);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view.backgroundColor = XXTColorGroupedBackground();
    
    XXTE_START_IGNORE_PARTIAL
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    [self reloadStaticTableViewData];
    [self reloadDynamicTableViewData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (isFirstTimeLoaded) {
        [self reloadDynamicTableViewData];
    }
    isFirstTimeLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)updateRemoteAccessAddressDisplay {
    XXTEMoreRemoteSwitchCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteSwitchCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Remote Access", nil);
    cell1.selectionStyle = UITableViewCellSelectionStyleNone;
    cell1.iconImageView.image = [[UIImage imageNamed:@"XXTEMoreIconRemoteAccess"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [cell1.optionSwitch addTarget:self action:@selector(remoteAccessOptionSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.remoteAccessSwitch = cell1.optionSwitch;
    self.remoteAccessIndicator = cell1.optionIndicator;
    
    XXTEMoreAddressCell *cellAddress1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    XXTEMoreAddressCell *cellAddress2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    if (_webServerUrl.length > 0) {
        cellAddress1.addressLabel.textColor = XXTColorPlainTitleText();
        cellAddress1.addressLabel.text = _webServerUrl;
    } else {
        cellAddress1.addressLabel.textColor = XXTColorPlainSubtitleText();
        cellAddress1.addressLabel.text = NSLocalizedString(@"Connect to Wi-fi network.", nil);
    }
    cellAddress2.addressLabel.text = _bonjourWebServerUrl.length > 0 ? _bonjourWebServerUrl : NSLocalizedString(@"N/A", nil);
    
    staticCells[0][0] = cell1;
    staticCells[0][1] = cellAddress1;
    staticCells[0][2] = cellAddress2;
    
    if (_webServerUrl.length > 0 || _bonjourWebServerUrl.length > 0)
    {
        staticSectionRowNum = @[ @3, @1, @1, @3, @6, @2, @2 ];
    } else {
        staticSectionRowNum = @[ @1, @1, @1, @3, @6, @2, @2 ];
    }
}

- (void)reloadDynamicTableViewData {
    if (!isFetchingRemoteStatus) {
        isFetchingRemoteStatus = YES;
        [self.remoteAccessSwitch setHidden:YES];
        [self.remoteAccessIndicator startAnimating];
        [NSURLConnection POST:uAppDaemonCommandUrl(@"is_remote_access_opened") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                BOOL remoteAccessStatus = [jsonDictionary[@"data"][@"opened"] boolValue];
                if (remoteAccessStatus) {
                    self->_webServerUrl = jsonDictionary[@"data"][@"webserver_url"];
                    self->_bonjourWebServerUrl = jsonDictionary[@"data"][@"bonjour_webserver_url"];
                    if (self->_webServerUrl.length == 0)
                        self->_webServerUrl = [[self class] otherInterfaceIPAddresses];
                } else {
                    self->_webServerUrl = nil;
                    self->_bonjourWebServerUrl = nil;
                }
                [self updateRemoteAccessAddressDisplay];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kXXTEMoreSectionIndexRemote] withRowAnimation:UITableViewRowAnimationAutomatic];
                if (self.remoteAccessSwitch.isOn != remoteAccessStatus) {
                    [self.remoteAccessSwitch setOn:remoteAccessStatus];
                }
            }
        }).catch(^(NSError *serverError) {
            toastDaemonError(self, serverError);
        }).finally(^() {
            [self.remoteAccessIndicator stopAnimating];
            [self.remoteAccessSwitch setHidden:NO];
            self->isFetchingRemoteStatus = NO;
        });
    }
}

- (void)reloadStaticTableViewData {
    static NSString *binaryModificationDateString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyyMMddHHmm";
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:XXTE_STANDARD_LOCALE]];
        NSDate *_binaryModificationDate = nil;
        [[[NSBundle mainBundle] executableURL] getResourceValue:&_binaryModificationDate forKey:NSURLContentModificationDateKey error:nil];
        if (_binaryModificationDate) {
            binaryModificationDateString = [dateFormatter stringFromDate:_binaryModificationDate];
        }
    });
    
    staticSectionTitles = @[ NSLocalizedString(@"Remote", nil),
                             NSLocalizedString(@"Daemon", nil),
                             NSLocalizedString(@"License", nil),
                             NSLocalizedString(@"Settings", nil),
                             NSLocalizedString(@"System", nil),
                             NSLocalizedString(@"Log", nil),
                             NSLocalizedString(@"Help", nil)];
    staticSectionFooters = @[
        NSLocalizedString(@"Turn on the switch: \n- Access the Web/WebDAV Server. \n- Upload file(s) to device via Wi-Fi.", nil),
        @"", @"", @"", @"", @"",
        [NSString stringWithFormat:NSLocalizedString(@"Version %@ (Build %@)", nil), uAppDefine(kXXTDaemonVersionKey), binaryModificationDateString],
    ];
    staticSectionRowNum = @[ @1, @1, @1, @3, @6, @2, @2 ];
    
    XXTEMoreRemoteSwitchCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteSwitchCell class]) owner:nil options:nil] lastObject];
    
    XXTEMoreLinkCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryNone;
    cell2.iconImage = [UIImage imageNamed:@"XXTEMoreIconRestartDaemon"];
    cell2.titleLabel.text = NSLocalizedString(@"Restart Daemon", nil);
    
    XXTEMoreLinkCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.iconImage = [UIImage imageNamed:@"XXTEMoreIconLicense"];
    cell3.titleLabel.text = NSLocalizedString(@"License & Device", nil);
    
    XXTEMoreLinkCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell4.iconImage = [UIImage imageNamed:@"XXTEMoreIconActivationConfig"];
    cell4.titleLabel.text = NSLocalizedString(@"Shortcut Config", nil);
    
    XXTEMoreLinkCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell6.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell6.iconImage = [UIImage imageNamed:@"XXTEMoreIconBootScript"];
    cell6.titleLabel.text = NSLocalizedString(@"Boot Script", nil);
    
    XXTEMoreLinkCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell7.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell7.iconImage = [UIImage imageNamed:@"XXTEMoreIconUserDefaults"];
    cell7.titleLabel.text = NSLocalizedString(@"User Defaults", nil);
    
    XXTEMoreLinkCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell8.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell8.iconImage = [UIImage imageNamed:@"XXTEMoreIconApplicationList"];
    cell8.titleLabel.text = NSLocalizedString(@"Application List", nil);
    
    XXTEMoreLinkCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell9.accessoryType = UITableViewCellAccessoryNone;
    cell9.iconImage = [UIImage imageNamed:@"XXTEMoreIconCleanGPSCaches"];
    cell9.titleLabel.text = NSLocalizedString(@"Clean GPS Caches", nil);
    
    XXTEMoreLinkCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell10.accessoryType = UITableViewCellAccessoryNone;
    cell10.iconImage = [UIImage imageNamed:@"XXTEMoreIconCleanUICaches"];
    cell10.titleLabel.text = NSLocalizedString(@"Clean UI Caches", nil);
    
    XXTEMoreLinkCell *cell11 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell11.accessoryType = UITableViewCellAccessoryNone;
    cell11.iconImage = [UIImage imageNamed:@"XXTEMoreIconCleanAll"];
    cell11.titleLabel.text = NSLocalizedString(@"Clean All", nil);
    
    XXTEMoreLinkCell *cell12 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell12.accessoryType = UITableViewCellAccessoryNone;
    cell12.iconImage = [UIImage imageNamed:@"XXTEMoreIconRespringDevice"];
    cell12.titleLabel.text = NSLocalizedString(@"Respring Device", nil);
    
    XXTEMoreLinkCell *cell13 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell13.accessoryType = UITableViewCellAccessoryNone;
    cell13.iconImage = [UIImage imageNamed:@"XXTEMoreIconRebootDevice"];
    cell13.titleLabel.text = NSLocalizedString(@"Restart Device", nil);
    
    XXTEMoreLinkCell *cellLog = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cellLog.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cellLog.iconImage = [UIImage imageNamed:@"XXTEMoreIconLog"];
    cellLog.titleLabel.text = NSLocalizedString(@"Script Log", nil);
    
    XXTEMoreLinkCell *cellErrorLog = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cellErrorLog.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cellErrorLog.iconImage = [UIImage imageNamed:@"XXTEMoreIconErrorLog"];
    cellErrorLog.titleLabel.text = NSLocalizedString(@"Error Log", nil);
    
    XXTEMoreLinkCell *cell14 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell14.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell14.iconImage = [UIImage imageNamed:@"XXTEMoreIconDocumentsOnline"];
    cell14.titleLabel.text = NSLocalizedString(@"Online Documents", nil);
    
    XXTEMoreLinkCell *cell15 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    cell15.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell15.iconImage = [UIImage imageNamed:@"XXTEMoreIconAbout"];
    cell15.titleLabel.text = NSLocalizedString(@"About", nil);
    
    XXTEMoreAddressCell *cellAddress1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    
    XXTEMoreAddressCell *cellAddress2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    
    staticCells = @[
                    [@[ cell1, cellAddress1, cellAddress2 ] mutableCopy],
                    //
                    [@[ cell2 ] mutableCopy],
                    //
                    [@[ cell3 ] mutableCopy],
                    //
                    [@[ cell4, cell6, cell7 ] mutableCopy],
                    //
                    [@[ cell8, cell9, cell10, cell11, cell12, cell13 ] mutableCopy],
                    //
                    [@[ cellLog, cellErrorLog ] mutableCopy],
                    //
                    [@[ cell14, cell15 ] mutableCopy],
                    ];
    [self updateRemoteAccessAddressDisplay];
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
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreSectionIndexRemote) {
            if (indexPath.row == 0) {
                return 66.f;
            }
        }
    }
    return 44.f;
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
                NSString *addressText = @"";
                if (indexPath.row == 1) {
                    addressText = _webServerUrl;
                } else if (indexPath.row == 2) {
                    addressText = _bonjourWebServerUrl;
                }
                if (addressText && addressText.length > 0) {
                    UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 1.0);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:addressText];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        toastMessage(self, NSLocalizedString(@"Remote address has been copied to the pasteboard.", nil));
                        blockInteractions(blockVC, NO);
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
            if (indexPath.row == kXXTEMoreSectionSystemRowIndexApplicationList) {
                XXTEMoreApplicationListController *applicationListController = [[XXTEMoreApplicationListController alloc] init];
                [self.navigationController pushViewController:applicationListController animated:YES];
            }
            else if (indexPath.row == kXXTEMoreSectionSystemRowIndexCleanGPSCaches) {
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
            else if (indexPath.row == kXXTEMoreSectionSystemRowIndexCleanUICaches) {
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
            else if (indexPath.row == kXXTEMoreSectionSystemRowIndexCleanAll) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTextFieldsAndTitle:NSLocalizedString(@"Clean All", nil)
                                                                                 message:NSLocalizedString(@"This operation will kill all user applications, and remove all the documents and caches of them.\nPlease enter \"CLEAR\" to continue.", nil)
                                                                      numberOfTextFields:1
                                                                  textFieldsSetupHandler:^(UITextField * _Nonnull textField, NSUInteger index) {
                                                                      if (index == 0) {
                                                                          textField.tintColor = XXTColorForeground();
                                                                          textField.autocorrectionType = UITextAutocorrectionTypeNo;
                                                                          textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
                                                                          textField.spellCheckingType = UITextSpellCheckingTypeNo;
                                                                          textField.enablesReturnKeyAutomatically = YES;
                                                                          textField.clearButtonMode = UITextFieldViewModeNever;
                                                                          textField.textAlignment = NSTextAlignmentCenter;
                                                                          textField.placeholder = NSLocalizedString(@"Please enter \"CLEAR\".", nil);
                                                                      }
                                                                  } buttonTitles:@[ ]
                                                                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                                  destructiveButtonTitle:NSLocalizedString(@"Clean Now", nil)
                                                                                delegate:self];
                [alertView setDestructiveButtonEnabled:NO];
                objc_setAssociatedObject(alertView, @selector(alertView:cleanAll:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
                // Change default delegate of TextField
                XXTEConfirmTextInputObject *confirmDelegate = [[XXTEConfirmTextInputObject alloc] init];
                [confirmDelegate setConfirmString:@"CLEAR"];
                [confirmDelegate setTextInput:[alertView.textFieldsArray firstObject]];
                [confirmDelegate setConfirmHandler:^(UITextField *textInput) {
                    [alertView setDestructiveButtonEnabled:YES];
                }];
                objc_setAssociatedObject(alertView, NSStringFromClass([XXTEConfirmTextInputObject class]).UTF8String, confirmDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            else if (indexPath.row == kXXTEMoreSectionSystemRowIndexRespringDevice) {
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
            else if (indexPath.row == kXXTEMoreSectionSystemRowIndexRestartDevice) {
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
        if (indexPath.section == kXXTEMoreSectionIndexLog) {
            XXTEMoreLinkCell *linkCell = [tableView cellForRowAtIndexPath:indexPath];
            if ([linkCell isKindOfClass:[XXTEMoreLinkCell class]]) {
                NSString *linkTitle = linkCell.titleLabel.text;
                NSString *logViewerName = uAppDefine(kXXTEDaemonLogViewerName);
                if ([logViewerName isKindOfClass:[NSString class]]) {
                    NSString *logPath = nil;
                    if (indexPath.row == kXXTEMoreSectionLogRowIndexLog) {
                        logPath = uAppDefine(kXXTEDaemonLogPath);
                    } else if (indexPath.row == kXXTEMoreSectionLogRowIndexErrorLog) {
                        logPath = uAppDefine(kXXTEDaemonErrorLogPath);
                    }
                    if (logPath) {
                        NSString *logEntirePath = [XXTERootPath() stringByAppendingPathComponent:logPath];
                        UIViewController *detailController = [[XXTExplorerViewController explorerEntryService] viewerWithName:logViewerName forEntryPath:logEntirePath];
                        detailController.title = linkTitle;
                        [self tableView:tableView showDetailController:detailController];
                    }
                }
            }
        }
        else
        if (indexPath.section == kXXTEMoreSectionIndexHelp) {
            NSAssert(NO, @"Not implemented");
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

- (void)remoteAccessOptionSwitchChanged:(UISwitch *)sender {
    if (sender == self.remoteAccessSwitch) {
        BOOL changeToStatus = sender.on;
        NSString *changeToCommand = nil;
        if (changeToStatus)
            changeToCommand = @"open_remote_access";
        else
            changeToCommand = @"close_remote_access";
        UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 2.0);
        [self.remoteAccessSwitch setHidden:YES];
        [self.remoteAccessIndicator startAnimating];
        [NSURLConnection POST:uAppDaemonCommandUrl(changeToCommand) JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                if (changeToStatus == YES) {
                    self->_webServerUrl = jsonDictionary[@"data"][@"webserver_url"];
                    self->_bonjourWebServerUrl = jsonDictionary[@"data"][@"bonjour_webserver_url"];
                    if (self->_webServerUrl.length == 0)
                        self->_webServerUrl = [[self class] otherInterfaceIPAddresses];
                } else {
                    self->_webServerUrl = nil;
                    self->_bonjourWebServerUrl = nil;
                }
                [self updateRemoteAccessAddressDisplay];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kXXTEMoreSectionIndexRemote] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.remoteAccessSwitch setOn:changeToStatus animated:YES];
            }
        }).catch(^(NSError *serverError) {
            toastDaemonError(self, serverError);
            [self.remoteAccessSwitch setOn:!changeToStatus animated:YES];
        }).finally(^() {
            [self.remoteAccessIndicator stopAnimating];
            [self.remoteAccessSwitch setHidden:NO];
            blockInteractions(blockVC, NO);
        });
    }
}

#pragma mark - Get other addresses

+ (NSString *)otherInterfaceIPAddresses {
    NSString *firstEthernetAddress = nil;
    NSArray <NSDictionary *> *boxedList = [[UIDevice currentDevice] getIPAddresses];
    for (NSDictionary *boxedDict in boxedList) {
        NSString *boxedName = boxedDict[@"name"];
        NSString *boxedType = boxedDict[@"type"];
        NSString *boxedAddress = boxedDict[@"address"];
        if ([boxedType isEqualToString:@"ipv4"] &&
            [boxedName hasPrefix:@"en"] &&
            ![boxedAddress hasPrefix:@"169.254."])
        {
            firstEthernetAddress = boxedAddress;
        }
    }
    if (firstEthernetAddress.length) {
        NSString *localPort = uAppDefine(@"LOCAL_PORT");
        return [NSString stringWithFormat:@"http://%@:%@/", firstEthernetAddress, localPort];
    }
    return nil;
}

#pragma mark - LGAlertViewDelegate

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

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
    objc_removeAssociatedObjects(alertView);
}

#pragma mark - LGAlertView Actions

- (void)alertView:(LGAlertView *)alertView cleanGPSCaches:(id)obj {
    [alertView dismissAnimated];
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"clear_gps") formURLEncodedParameters:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        } else {
            toastMessage(self, jsonDictionary[@"message"]);
        }
    }).catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    }).finally(^() {
        blockInteractions(blockVC, NO);
    });
}

- (void)alertView:(LGAlertView *)alertView cleanUICaches:(id)obj {
    [alertView dismissAnimated];
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"uicache") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        }
    }).catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    }).finally(^() {
        blockInteractions(blockVC, NO);
    });
}

- (void)alertView:(LGAlertView *)alertView cleanAll:(id)obj {
    [alertView dismissAnimated];
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"clear_all") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        }
    }).catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    }).finally(^() {
        blockInteractions(blockVC, NO);
    });
}

- (void)alertView:(LGAlertView *)alertView respringDevice:(id)obj {
    [alertView dismissAnimated];
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"respring") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        }
    }).catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
        if (serverError) {
            [XXTERespringAgent performRespring];
        }
    }).finally(^() {
        blockInteractions(blockVC, NO);
    });
}

- (void)alertView:(LGAlertView *)alertView rebootDevice:(id)obj {
    [alertView dismissAnimated];
    UIViewController *blockVC = blockInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"reboot2") JSON:@{  }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            toastMessage(self, ([NSString stringWithFormat:@"Operation succeed: %@", jsonDictionary[@"message"]]));
        }
    }).catch(^(NSError *serverError) {
        toastDaemonError(self, serverError);
    }).finally(^() {
        blockInteractions(blockVC, NO);
    });
}

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

#pragma mark - Notifications

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidBecomeActive]) {
        [self reloadDynamicTableViewData];
    }
}

#pragma mark - Log Viewer

- (void)tableView:(UITableView *)tableView showDetailController:(UIViewController *)controller {
    if ([controller isKindOfClass:[UIViewController class]] &&
        [controller conformsToProtocol:@protocol(XXTEDetailViewController)]) {
        UIViewController <XXTEDetailViewController> *viewer = (UIViewController <XXTEDetailViewController> *)controller;
        if (XXTE_COLLAPSED) {
            XXTE_START_IGNORE_PARTIAL
            XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:viewer];
            [self.splitViewController showDetailViewController:navigationController sender:self];
            XXTE_END_IGNORE_PARTIAL
        } else {
            [self.navigationController pushViewController:viewer animated:YES];
        }
    }
}

#pragma mark - Dismissal (Override)

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (!XXTE_IS_FULLSCREEN(self)) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [super dismissViewControllerAnimated:flag completion:completion];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
