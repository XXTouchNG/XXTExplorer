//
//  XXTEMoreAboutController.m
//  XXTExplorer
//
//  Created by Zheng on 03/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreAboutController.h"
#import "XXTEMoreLinkNoIconCell.h"
#import "XXTEMoreAboutCell.h"
#import "XXTENavigationController.h"
#import "XXTECommonWebViewController.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEMailComposeViewController.h"
#import "XXTEMasterViewController.h"
#import "XXTEDispatchDefines.h"
#import "XXTESplitViewController.h"

#import <MessageUI/MessageUI.h>
#import <LGAlertView/LGAlertView.h>

#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENetworkDefines.h"
#import <PromiseKit/PromiseKit.h>
#import <NSURLConnection+PromiseKit.h>

typedef enum : NSUInteger {
    kXXTEMoreAboutSectionIndexWell = 0,
    kXXTEMoreAboutSectionIndexHomepage,
    kXXTEMoreAboutSectionIndexFeedback,
    kXXTEMoreAboutSectionIndexTool,
    kXXTEMoreAboutSectionIndexMax
} kXXTEMoreAboutSectionIndex;

@interface XXTEMoreAboutController () <MFMailComposeViewControllerDelegate>

@end

@implementation XXTEMoreAboutController {
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"About", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    [self reloadStaticTableViewData];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"", @"", @"", @"" ];
    staticSectionFooters = @[ @"", @"", @"", @"" ];
    
    XXTEMoreAboutCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAboutCell class]) owner:nil options:nil] lastObject];
    
    XXTEMoreLinkNoIconCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell2.titleLabel.text = NSLocalizedString(@"Official Site", nil);
    
    XXTEMoreLinkNoIconCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"Mail Feedback", nil);
    
    XXTEMoreLinkNoIconCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell4.titleLabel.text = NSLocalizedString(@"Official QQ Group", nil);
    
    XXTEMoreLinkNoIconCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell5.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell5.titleLabel.text = NSLocalizedString(@"Check Update", nil);
    
    XXTEMoreLinkNoIconCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell6.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell6.titleLabel.text = NSLocalizedString(@"Reset Defaults", nil);
    
    staticCells = @[
                    @[ cell1 ],
                    //
                    @[ cell2 ],
                    //
                    @[ cell3, cell4 ],
                    //
                    @[ cell5, cell6 ]
                    ];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return kXXTEMoreAboutSectionIndexMax;
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
        if (indexPath.section == kXXTEMoreAboutSectionIndexWell) {
            return 220.f;
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreAboutSectionIndexHomepage) {
            XXTEMoreLinkNoIconCell *cell = (XXTEMoreLinkNoIconCell *)staticCells[indexPath.section][indexPath.row];
            NSString *titleString = cell.titleLabel.text;
            NSURL *titleUrl = nil;
            if (indexPath.row == 0) {
                titleUrl = [NSURL URLWithString:uAppDefine(@"OFFICIAL_SITE")];
            }
            XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:titleUrl];
            webController.title = titleString;
            if (XXTE_COLLAPSED) {
                XXTE_START_IGNORE_PARTIAL
                if (@available(iOS 8.0, *)) {
                    XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:webController];
                    [self showDetailViewController:navigationController sender:self];
                }
                XXTE_END_IGNORE_PARTIAL
            } else {
                [self.navigationController pushViewController:webController animated:YES];
            }
        }
        else if (indexPath.section == kXXTEMoreAboutSectionIndexFeedback) {
            if (indexPath.row == 0) {
                if ([XXTEMailComposeViewController canSendMail]) {
                    XXTEMailComposeViewController *picker = [[XXTEMailComposeViewController alloc] init];
                    if (!picker) return;
                    picker.mailComposeDelegate = self;
                    [picker setSubject:[NSString stringWithFormat:@"[%@] %@\nV%@", NSLocalizedString(@"Feedback", nil), uAppDefine(@"PRODUCT_NAME"), uAppDefine(@"DAEMON_VERSION")]];
                    NSArray *toRecipients = @[uAppDefine(@"SERVICE_EMAIL")];
                    [picker setToRecipients:toRecipients];
                    picker.modalPresentationStyle = UIModalPresentationFormSheet;
                    [self presentViewController:picker animated:YES completion:nil];
                } else {
                    toastMessage(self, NSLocalizedString(@"Please setup \"Mail\" to send mail feedback directly.", nil));
                }
            }
            else if (indexPath.row == 1) {
                NSString *contactStr = uAppDefine(@"CONTACT_URL");
                if (contactStr) {
                    NSURL *qqURL = [NSURL URLWithString:contactStr];
                    if ([[UIApplication sharedApplication] canOpenURL:qqURL]) {
                        [[UIApplication sharedApplication] openURL:qqURL];
                    } else {
                        toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Cannot open \"%@\".", nil), contactStr]));
                    }
                }
            }
        }
        else if (indexPath.section == kXXTEMoreAboutSectionIndexTool) {
            if (indexPath.row == 0) {
                XXTEMasterViewController *tabbarController = (XXTEMasterViewController *) self.tabBarController;
                [tabbarController checkUpdate];
            }
            else if (indexPath.row == 1) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Reset Confirm", nil) message:NSLocalizedString(@"All user defaults will be removed, but your file will not be deleted.\nThis operation cannot be revoked.", nil) style:LGAlertViewStyleActionSheet buttonTitles:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Reset", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
                    [alertView dismissAnimated];
                } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
                    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
                    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
                    [alertView dismissAnimated];
                    [self performResetDefaultsAtRemote];
                }];
                [alertView showAnimated];
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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Reset Action

- (void)performResetDefaultsAtRemote {
    blockInteractions(self, YES);;
    [NSURLConnection POST:uAppDaemonCommandUrl(@"reset_defaults") JSON:@{}]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDirectory) {
        if (jsonDirectory[@"code"]) {
            // already been killed
            toastMessage(self, NSLocalizedString(@"Operation succeed.", nil));
        }
    })
    .catch(^(NSError *error) {
        if (error) {
            if (error.code == -1004) {
                toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                toastMessage(self, [error localizedDescription]);
            }
        }
    })
    .finally(^() {
        blockInteractions(self, NO);;
    });
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreAboutController dealloc]");
#endif
}

@end
