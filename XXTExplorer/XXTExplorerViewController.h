//
//  XXTExplorerViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    XXTExplorerViewSectionIndexHome = 0,
    XXTExplorerViewSectionIndexList,
    XXTExplorerViewSectionIndexMax
} XXTExplorerViewSectionIndex;

@class XXTExplorerToolbar, XXTExplorerFooterView;

@interface XXTExplorerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, copy, readonly) NSString *entryPath;

@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *entryList;
@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *homeEntryList;

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) XXTExplorerFooterView *footerView;

#pragma mark - toolbar

@property (nonatomic, strong) XXTExplorerToolbar *toolbar;

#pragma mark - status

@property (nonatomic, assign) BOOL busyOperationProgressFlag;

#pragma mark - init

- (instancetype)initWithEntryPath:(NSString *)path;

#pragma mark - reload

- (void)loadEntryListData;
- (void)refreshEntryListView:(UIRefreshControl *)refreshControl;

#pragma mark - home series

- (BOOL)showsHomeSeries;

@end
