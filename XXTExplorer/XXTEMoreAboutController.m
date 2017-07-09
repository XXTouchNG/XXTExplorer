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
#import "XXTECommonNavigationController.h"
#import "XXTECommonWebViewController.h"
#import "XXTEAppDefines.h"
#import "UIView+XXTEToast.h"
#import <MessageUI/MessageUI.h>

typedef enum : NSUInteger {
    kXXTEMoreAboutSectionIndexWell = 0,
    kXXTEMoreAboutSectionIndexHomepage,
    kXXTEMoreAboutSectionIndexFeedback,
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
    //    self.hidesBottomBarWhenPushed = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = NSLocalizedString(@"About", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self reloadStaticTableViewData];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"", @"", @"Feedback" ];
    staticSectionFooters = @[ @"", @"", @"" ];
    
    XXTEMoreAboutCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAboutCell class]) owner:nil options:nil] lastObject];
    
    XXTEMoreLinkNoIconCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell2.titleLabel.text = NSLocalizedString(@"Official Site", nil);
    
    XXTEMoreLinkNoIconCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"User Agreement", nil);
    
    XXTEMoreLinkNoIconCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell4.titleLabel.text = NSLocalizedString(@"Third Party Credits", nil);
    
    XXTEMoreLinkNoIconCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell5.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell5.titleLabel.text = NSLocalizedString(@"Mail Feedback", nil);
    
    XXTEMoreLinkNoIconCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell6.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell6.titleLabel.text = NSLocalizedString(@"Online Update (Cydia)", nil);
    
    XXTEMoreLinkNoIconCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell7.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell7.titleLabel.text = NSLocalizedString(@"QQ Group (40898074)", nil);
    
    staticCells = @[
                    @[ cell1 ],
                    //
                    @[ cell2, cell3, cell4 ],
                    //
                    @[ cell5, cell6, cell7 ]
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
        return UITableViewAutomaticDimension;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreAboutSectionIndexHomepage) {
            XXTEMoreLinkNoIconCell *cell = (XXTEMoreLinkNoIconCell *)staticCells[indexPath.section][indexPath.row];
            NSString *titleString = cell.titleLabel.text;
            NSURL *titleUrl = nil;
            if (indexPath.row == 0) {
                titleUrl = [NSURL URLWithString:@"https://www.xxtouch.com"];
            }
            else if (indexPath.row == 1) {
                titleUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"XXTEMoreReferences.bundle/tos" ofType:@"html"]];
            }
            else if (indexPath.row == 2) {
                titleUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"XXTEMoreReferences.bundle/open" ofType:@"html"]];
            }
            XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:titleUrl];
            webController.title = titleString;
            XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:webController];
            [self.splitViewController showDetailViewController:navigationController sender:self];
        }
        else if (indexPath.section == kXXTEMoreAboutSectionIndexFeedback) {
            if (indexPath.row == 0) {
                if ([MFMailComposeViewController canSendMail]) {
                    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
                    if (!picker) return;
                    picker.view.tintColor = XXTE_COLOR;
                    picker.mailComposeDelegate = self;
                    [picker setSubject:[NSString stringWithFormat:@"[%@] %@\nV%@", NSLocalizedString(@"Feedback", nil), NSLocalizedString(@"XXTouch Pro", nil), uAppDefine(@"DAEMON_VERSION")]];
                    NSArray *toRecipients = [NSArray arrayWithObject:uAppDefine(@"SERVICE_EMAIL")];
                    [picker setToRecipients:toRecipients];
                    [self presentViewController:picker animated:YES completion:nil];
                } else {
                    [self.navigationController.view makeToast:NSLocalizedString(@"Please setup Mail client to send mail feedback directly.", nil)];
                }
            }
            else if (indexPath.row == 1) {
                NSString *cydiaStr = uAppDefine(@"CYDIA_URL");
                if (cydiaStr) {
                    NSURL *cydiaURL = [NSURL URLWithString:cydiaStr];
                    if ([[UIApplication sharedApplication] canOpenURL:cydiaURL]) {
                        [[UIApplication sharedApplication] openURL:cydiaURL];
                    } else {
                        [self.navigationController.view makeToast:NSLocalizedString(@"Cannot open Cydia.", nil)];
                    }
                }
            }
            else if (indexPath.row == 2) {
                NSString *contactStr = uAppDefine(@"CONTACT_URL");
                if (contactStr) {
                    NSURL *qqURL = [NSURL URLWithString:contactStr];
                    if ([[UIApplication sharedApplication] canOpenURL:qqURL]) {
                        [[UIApplication sharedApplication] openURL:qqURL];
                    } else {
                        [self.navigationController.view makeToast:NSLocalizedString(@"Cannot open Mobile QQ.", nil)];
                    }
                }
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return NSLocalizedString(staticSectionTitles[section], nil);
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return NSLocalizedString(staticSectionFooters[section], nil);
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return staticCells[indexPath.section][indexPath.row];
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

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreAboutController dealloc]");
#endif
}

@end