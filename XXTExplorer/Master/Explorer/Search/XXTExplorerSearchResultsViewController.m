//
//  XXTExplorerSearchResultsViewController.m
//  XXTouch
//
//  Created by Darwin on 8/21/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTExplorerSearchResultsViewController.h"
#import "XXTExplorerViewCell.h"
#import "XXTExplorerEntry.h"
#import "XXTExplorerViewController+SharedInstance.h"


@interface XXTExplorerSearchResultsViewController ()

@end

@implementation XXTExplorerSearchResultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITableView *tableView = self.tableView;
    tableView.dataSource = self;
    tableView.backgroundColor = XXTColorPlainBackground();
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTExplorerViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTExplorerViewCellReuseIdentifier];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredEntryList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        XXTExplorerEntry *entryDetail = self.filteredEntryList[indexPath.row];
        XXTExplorerViewCell *entryCell = [tableView dequeueReusableCellWithIdentifier:XXTExplorerViewCellReuseIdentifier];
        if (!entryCell) {
            entryCell = [[XXTExplorerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:XXTExplorerViewCellReuseIdentifier];
        }
        [self configureCell:entryCell withEntry:entryDetail];
        return entryCell;
    }
    return [UITableViewCell new];
}

- (void)configureCell:(XXTExplorerViewCell *)entryCell withEntry:(XXTExplorerEntry *)entry {
    entryCell.delegate = nil;  // no cell delegate
    entryCell.entryTitleLabel.textColor = XXTColorPlainTitleText();
    entryCell.entrySubtitleLabel.textColor = XXTColorPlainSubtitleText();
    if (entry.isBrokenSymlink) {
        // broken symlink
        entryCell.entryTitleLabel.textColor = XXTColorDanger();
        entryCell.entrySubtitleLabel.textColor = XXTColorDanger();
        entryCell.flagType = XXTExplorerViewCellFlagTypeBroken;
    } else if (entry.isSymlink) {
        // symlink
        entryCell.entryTitleLabel.textColor = XXTColorForeground();
        entryCell.entrySubtitleLabel.textColor = XXTColorForeground();
        entryCell.flagType = XXTExplorerViewCellFlagTypeNone;
    } else {
        entryCell.entryTitleLabel.textColor = XXTColorPlainTitleText();
        entryCell.entrySubtitleLabel.textColor = XXTColorPlainSubtitleText();
        entryCell.flagType = XXTExplorerViewCellFlagTypeNone;
    }
    if (!entry.isMaskedDirectory &&
        [[XXTExplorerViewController selectedScriptPath] isEqualToString:entry.entryPath]) {
        // selected script itself
        entryCell.entryTitleLabel.textColor = XXTColorSuccess();
        entryCell.entrySubtitleLabel.textColor = XXTColorSuccess();
        entryCell.flagType = XXTExplorerViewCellFlagTypeSelected;
    } else if ((entry.isMaskedDirectory ||
                entry.isBundle) &&
               [[XXTExplorerViewController selectedScriptPath] hasPrefix:entry.entryPath] &&
               [[[XXTExplorerViewController selectedScriptPath] substringFromIndex:entry.entryPath.length] rangeOfString:@"/"].location != NSNotFound) {
        // selected script in directory / bundle
        entryCell.entryTitleLabel.textColor = XXTColorSuccess();
        entryCell.entrySubtitleLabel.textColor = XXTColorSuccess();
        entryCell.flagType = XXTExplorerViewCellFlagTypeSelectedInside;
    }
    NSString *fixedName = entry.localizedDisplayName;
    if (self.historyMode) {
        NSUInteger atLoc = [fixedName rangeOfString:@"@"].location + 1;
        if (atLoc != NSNotFound && atLoc < fixedName.length) {
            fixedName = [fixedName substringFromIndex:atLoc];
        }
    }
    entryCell.entryTitleLabel.text = fixedName;
    entryCell.entrySubtitleLabel.text = entry.localizedDescription;
    entryCell.entryIconImageView.image = entry.localizedDisplayIconImage;
    if (entryCell.accessoryType != UITableViewCellAccessoryNone)
    {
        entryCell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
