//
//  XXTEMoreViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreViewController.h"
#import "XXTEMoreCell.h"

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

@end

@implementation XXTEMoreViewController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"More", nil);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTEMoreRemoteSwitchCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreRemoteSwitchCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Remote Access", nil);
    [cell1.optionSwitch addTarget:self action:@selector(remoteAccessOptionSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    
    staticCells = @[
                    @[ cell1 ],
                     //
                    @[  ],
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
        if (section == kXXTEMoreSectionIndexRemote) {
            return 1;
        }
        else if (section == kXXTEMoreSectionIndexService) {
            return 1;
        }
        else if (section == kXXTEMoreSectionIndexAuthentication) {
            return 1;
        }
        else if (section == kXXTEMoreSectionIndexSettings) {
            return 4;
        }
        else if (section == kXXTEMoreSectionIndexSystem) {
            return 6;
        }
        else if (section == kXXTEMoreSectionIndexHelp) {
            return 2;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreSectionIndexRemote && indexPath.row == 0) {
            return 66.f;
        }
        return 44.f;
    }
    return 0;
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == kXXTEMoreSectionIndexRemote) {
            return NSLocalizedString(@"Remote", nil);
        }
        else if (section == kXXTEMoreSectionIndexService) {
            return NSLocalizedString(@"Daemon", nil);
        }
        else if (section == kXXTEMoreSectionIndexAuthentication) {
            return NSLocalizedString(@"Authentication", nil);
        }
        else if (section == kXXTEMoreSectionIndexSettings) {
            return NSLocalizedString(@"Settings", nil);
        }
        else if (section == kXXTEMoreSectionIndexSystem) {
            return NSLocalizedString(@"System", nil);
        }
        else if (section == kXXTEMoreSectionIndexHelp) {
            return NSLocalizedString(@"Help", nil);
        }
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreSectionIndexRemote) {
            return staticCells[indexPath.section][indexPath.row];
        }
    }
    return [UITableViewCell new];
}

#pragma mark - UIControl Actions

- (void)remoteAccessOptionSwitchChanged:(UISwitch *)sender {
    
}

@end
