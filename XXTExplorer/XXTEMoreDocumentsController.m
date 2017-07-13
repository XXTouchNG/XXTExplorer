//
//  XXTEMoreDocumentsController.m
//  XXTExplorer
//
//  Created by Zheng on 06/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreDocumentsController.h"
#import "XXTEMoreLinkNoIconCell.h"
#import "XXTECommonWebViewController.h"
#import "XXTECommonNavigationController.h"
#import "XXTEAppDefines.h"

@interface XXTEMoreDocumentsController ()

@end

@implementation XXTEMoreDocumentsController {
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
    self.title = NSLocalizedString(@"Documents", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    [self reloadStaticTableViewData];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"" ];
    staticSectionFooters = @[ @"" ];
    
    XXTEMoreLinkNoIconCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell1.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell1.titleLabel.text = NSLocalizedString(@"User's Guide", nil);
    
    XXTEMoreLinkNoIconCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell2.titleLabel.text = NSLocalizedString(@"Update Logs", nil);
    
    XXTEMoreLinkNoIconCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell3.titleLabel.text = NSLocalizedString(@"Developer Reference", nil);
    
    XXTEMoreLinkNoIconCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell4.titleLabel.text = NSLocalizedString(@"Open API Reference", nil);
    
    XXTEMoreLinkNoIconCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell5.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell5.titleLabel.text = NSLocalizedString(@"Code Snippet Reference", nil);
    
    XXTEMoreLinkNoIconCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell6.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell6.titleLabel.text = NSLocalizedString(@"DynamicXUI (XUI) Reference", nil);
    
    staticCells = @[
                    @[ cell1, cell2, cell3, cell4, cell5, cell6 ]
                    ];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return staticSectionTitles.count;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            XXTEMoreLinkNoIconCell *cell = (XXTEMoreLinkNoIconCell *)staticCells[indexPath.section][indexPath.row];
            NSString *titleString = cell.titleLabel.text;
            NSURL *titleUrl = nil;
            if (indexPath.row == 0) {
                titleUrl = [NSURL URLWithString:uAppDefine(@"DOCUMENT_USERS_GUIDE")];
            }
            else if (indexPath.row == 1) {
                titleUrl = [NSURL URLWithString:uAppDefine(@"DOCUMENT_UPDATE_LOGS")];
            }
            else if (indexPath.row == 2) {
                titleUrl = [NSURL URLWithString:uAppDefine(@"DOCUMENT_DEVELOPER_REFERENCE")];
            }
            else if (indexPath.row == 3) {
                titleUrl = [NSURL URLWithString:uAppDefine(@"DOCUMENT_OPEN_API_REFERENCE")];
            }
            else if (indexPath.row == 4) {
                titleUrl = [NSURL URLWithString:uAppDefine(@"DOCUMENT_CODE_SNIPPETS_REFERENCE")];
            }
            else if (indexPath.row == 5) {
                titleUrl = [NSURL URLWithString:uAppDefine(@"DOCUMENT_DYNAMIC_XUI_REFERENCE")];
            }
            XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:titleUrl];
            webController.title = titleString;
            if (XXTE_PAD) {
                XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:webController];
                [self.splitViewController showDetailViewController:navigationController sender:self];
            } else {
                [self.navigationController pushViewController:webController animated:YES];
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

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreDocumentsController dealloc]");
#endif
}

@end
