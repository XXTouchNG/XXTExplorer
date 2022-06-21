//
//  XXTExplorerViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTExplorerEntry.h"

typedef enum : NSUInteger {
    XXTExplorerViewSectionIndexHome = 0,
    XXTExplorerViewSectionIndexList,
    XXTExplorerViewSectionIndexMax
} XXTExplorerViewSectionIndex;

@class XXTExplorerViewCell, XXTExplorerViewHomeCell, XXTExplorerToolbar, XXTExplorerHeaderView, XXTExplorerFooterView, XXTExplorerViewController;

@protocol XXTExplorerDirectoryPreviewDelegate <NSObject>

@end

@protocol XXTExplorerDirectoryPreviewActionDelegate <NSObject>

XXTE_START_IGNORE_PARTIAL
- (NSArray <UIPreviewAction *> *)directoryPreviewController:(XXTExplorerViewController *)controller previewActionsForEntry:(XXTExplorerEntry *)entry;
XXTE_END_IGNORE_PARTIAL

@end

@interface XXTExplorerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, copy, readonly) XXTExplorerEntry *entry;

@property (nonatomic, copy, readonly) NSMutableArray <XXTExplorerEntry *> *entryList;
@property (nonatomic, copy, readonly) NSMutableArray <NSDictionary *> *homeEntryList;

@property (nonatomic, assign) XXTExplorerViewEntryListSortField explorerSortField;
@property (nonatomic, assign) XXTExplorerViewEntryListSortOrder explorerSortOrder;

// must inherit manually
@property (nonatomic, assign) BOOL displayCurrentPath;
@property (nonatomic, assign) XXTExplorerViewEntryListSortField internalSortField;
@property (nonatomic, assign) XXTExplorerViewEntryListSortOrder internalSortOrder;

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) XXTExplorerFooterView *footerView;
@property (nonatomic, strong, readonly) XXTExplorerHeaderView *sectionHeaderView;

#pragma mark - toolbar

@property (nonatomic, strong) XXTExplorerToolbar *toolbar;
@property (nonatomic, strong) UIView *toolbarCover;

#pragma mark - status

@property (nonatomic, assign) BOOL busyOperationProgressFlag;

#pragma mark - init

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithEntryPath:(NSString *)path;

#pragma mark - configure

- (void)configureCell:(XXTExplorerViewCell *)entryCell fromTableView:(UITableView *)tableView withEntry:(XXTExplorerEntry *)entry;
- (void)configureHomeCell:(XXTExplorerViewHomeCell *)entryCell fromTableView:(UITableView *)tableView withEntry:(NSDictionary *)entryDetail;

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
- (BOOL)allowsPreviewing;
- (BOOL)allowDragAndDrop;
- (BOOL)shouldDisplayEntry:(XXTExplorerEntry *)entryDetail;

#pragma mark - fast open

- (void)performDictionaryActionForEntry:(XXTExplorerEntry *)entryDetail;
- (void)performHistoryActionForEntry:(XXTExplorerEntry *)entryDetail;
- (void)performViewerActionForEntry:(XXTExplorerEntry *)entryDetail;
- (void)performViewerActionForEntry:(XXTExplorerEntry *)entryDetail animated:(BOOL)animated;

- (void)performViewerExecutableActionForEntry:(XXTExplorerEntry *)entry;
- (void)performViewerExecutableActionForEntryAtPath:(NSString *)entryPath;

#pragma mark - previewing

@property (nonatomic, weak) id <XXTExplorerDirectoryPreviewDelegate> previewDelegate;
@property (nonatomic, weak) id <XXTExplorerDirectoryPreviewActionDelegate> previewActionDelegate;
@property (nonatomic, weak) id previewActionSender;
@property (nonatomic, assign, readonly) BOOL isPreviewed; // previewActionDelegate != nil

#pragma mark - cell selection

- (void)scrollToCellEntryAtPath:(NSString *)entryPath animated:(BOOL)animated;
- (void)selectCellEntryAtPath:(NSString *)entryPath animated:(BOOL)animated;
- (void)selectCellEntriesAtPaths:(NSArray <NSString *> *)entryPaths animated:(BOOL)animated;

@end
