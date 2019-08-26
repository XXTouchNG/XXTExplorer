//
//  XXTExplorerSearchResultsViewController.h
//  XXTouch
//
//  Created by Darwin on 8/21/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XXTExplorerEntry, XXTExplorerHeaderView, XXTExplorerViewController;

@interface XXTExplorerSearchResultsViewController : UITableViewController

@property (nonatomic, weak) XXTExplorerViewController *explorer;
@property (nonatomic, strong) XXTExplorerHeaderView *searchHeaderView;
@property (nonatomic, strong) NSMutableArray <XXTExplorerEntry *> *filteredEntryList;
@property (nonatomic, assign) BOOL historyMode;
@property (nonatomic, assign) BOOL recursively;
@property (nonatomic, assign) BOOL isUpdating;

@end

NS_ASSUME_NONNULL_END
