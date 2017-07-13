//
//  XXTExplorerViewController.h
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTExplorerToolbar, XXTExplorerFooterView;

@interface XXTExplorerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, copy, readonly) NSString *entryPath;

@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *entryList;
@property (nonatomic, copy, readonly) NSArray <NSDictionary *> *homeEntryList;

@property (nonatomic, strong, readonly) XXTExplorerToolbar *toolbar;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) XXTExplorerFooterView *footerView;

+ (NSString *)initialPath;
+ (NSString *)rootPath;
+ (NSFileManager *)explorerFileManager;
+ (NSString *)selectedScriptPath;
+ (BOOL)isFetchingSelectedScript;
+ (void)setFetchingSelectedScript:(BOOL)fetching;

- (instancetype)initWithEntryPath:(NSString *)path;

@end
