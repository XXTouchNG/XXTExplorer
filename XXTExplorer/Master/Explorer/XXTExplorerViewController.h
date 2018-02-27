//
//  XXTExplorerViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTExplorerDefaults.h"

typedef enum : NSUInteger {
    XXTExplorerViewSectionIndexHome = 0,
    XXTExplorerViewSectionIndexList,
    XXTExplorerViewSectionIndexMax
} XXTExplorerViewSectionIndex;

@class XXTExplorerToolbar, XXTExplorerFooterView, XXTExplorerViewController;

@protocol XXTExplorerDirectoryPreviewDelegate <NSObject>

@end

@protocol XXTExplorerDirectoryPreviewActionDelegate <NSObject>

XXTE_START_IGNORE_PARTIAL
- (NSArray <UIPreviewAction *> *)directoryPreviewController:(XXTExplorerViewController *)controller previewActionsForEntry:(NSDictionary *)entry;
XXTE_END_IGNORE_PARTIAL

@end

@interface XXTExplorerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, copy, readonly) NSDictionary *entry;

@property (nonatomic, copy, readonly) NSMutableArray <NSDictionary *> *entryList;
@property (nonatomic, copy, readonly) NSMutableArray <NSDictionary *> *homeEntryList;

@property (nonatomic, assign) XXTExplorerViewEntryListSortField explorerSortField;
@property (nonatomic, assign) XXTExplorerViewEntryListSortOrder explorerSortOrder;

@property (nonatomic, assign) BOOL historyMode;
@property (nonatomic, assign) XXTExplorerViewEntryListSortField internalSortField;
@property (nonatomic, assign) XXTExplorerViewEntryListSortOrder internalSortOrder;

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) XXTExplorerFooterView *footerView;

#pragma mark - toolbar

@property (nonatomic, strong) XXTExplorerToolbar *toolbar;

#pragma mark - status

@property (nonatomic, assign) BOOL busyOperationProgressFlag;

#pragma mark - init

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithEntryPath:(NSString *)path;

#pragma mark - reload

- (void)loadEntryListData;
- (void)reloadEntryListView;
- (void)refreshControlTriggered:(UIRefreshControl *)refreshControl;
- (void)reconfigureCellAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForEntryAtPath:(NSString *)entryPath;
- (void)reloadFooterView;
- (void)updateFooterView;

#pragma mark - picker

- (BOOL)showsHomeSeries;
- (BOOL)shouldDisplayEntry:(NSDictionary *)entryDetail;

#pragma mark - fast open

- (void)performDictionaryActionForEntry:(NSDictionary *)entryDetail;
- (void)performHistoryActionForEntry:(NSDictionary *)entryDetail;
- (void)performViewerActionForEntry:(NSDictionary *)entryDetail;

#pragma mark - previewing

@property (nonatomic, weak) id <XXTExplorerDirectoryPreviewDelegate> previewDelegate;
@property (nonatomic, weak) id <XXTExplorerDirectoryPreviewActionDelegate> previewActionDelegate;
@property (nonatomic, weak) id previewActionSender;
@property (nonatomic, assign, readonly) BOOL isPreviewed; // previewActionDelegate != nil

@end
