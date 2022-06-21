//
// Created by Zheng on 02/05/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTEMoreApplicationListController : UIViewController

@property(nonatomic, strong, readonly) UITableView *tableView;
@property(nonatomic, strong, readonly) UIRefreshControl *refreshControl;

@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *allUserApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *allSystemApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *displayUserApplications;
@property(nonatomic, strong, readonly) NSMutableArray <NSDictionary *> *displaySystemApplications;

@end
