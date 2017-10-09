//
//  XUIListViewController.h
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIViewController.h"

@class XUIBaseCell, XUICellFactory, XUIListHeaderView, XUIListFooterView;

@interface XUIListViewController : XUIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) NSBundle *bundle;

// Views
@property (nonatomic, strong, readonly) XUIListHeaderView *headerView;
@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) XUIListFooterView *footerView;

- (instancetype)initWithPath:(NSString *)path withBundlePath:(NSString *)bundlePath;

// Store
- (void)storeCellWhenNeeded:(XUIBaseCell *)cell;
- (void)setNeedsStoreCells;
- (void)storeCellsIfNecessary;

// Error
- (void)presentErrorAlertController:(NSError *)error;

@end