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

typedef enum : NSUInteger {
    kXXTEMoreAboutSectionIndexWell = 0,
    kXXTEMoreAboutSectionIndexHomepage,
    kXXTEMoreAboutSectionIndexFeedback,
    kXXTEMoreAboutSectionIndexMax
} kXXTEMoreAboutSectionIndex;

@interface XXTEMoreAboutController ()

@end

@implementation XXTEMoreAboutController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
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
    
    staticSectionRowNum = @[ @1, @3, @3 ];
    
    staticCells = @[
                    @[ cell1 ],
                    //
                    @[ cell2, cell3, cell4 ],
                    //
                    @[ cell5, cell6, cell7 ]
                    ];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return kXXTEMoreAboutSectionIndexMax;
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
        return UITableViewAutomaticDimension;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreAboutSectionIndexHomepage) {
            if (indexPath.row == 0) {
                XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURLString:@"https://www.xxtouch.com"];
                webController.title = NSLocalizedString(@"Official Site", nil);
                //    XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:webController];
                [self.navigationController pushViewController:webController animated:YES];
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

@end
