//
//  XXTEEditorSearchFindController.m
//  XXTExplorer
//
//  Created by Zheng on 11/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchFindController.h"
#import "XXTEEditorController.h"

#import "XXTEEditorSearchHeaderView.h"
#import "XXTEEditorSearchTextField.h"

@interface XXTEEditorSearchFindController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) XXTEEditorSearchHeaderView *headerView;
@property (nonatomic, strong) XXTEEditorSearchTextField *findTextField;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation XXTEEditorSearchFindController

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.title = NSLocalizedString(@"Find", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    self.view.layer.borderWidth = .5;
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.headerView];
    [self.headerView addSubview:self.findTextField];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.headerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 72.0);
    self.tableView.frame = CGRectMake(0, 72.0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 72.0);
}

#pragma mark - UIView Getters

- (XXTEEditorSearchHeaderView *)headerView {
    if (!_headerView) {
        XXTEEditorSearchHeaderView *headerView = [[XXTEEditorSearchHeaderView alloc] init];
        _headerView = headerView;
    }
    return _headerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        tableView.dataSource = self;
        tableView.delegate = self;
//        tableView.tableFooterView = [UIView new];
        _tableView = tableView;
    }
    return _tableView;
}

- (XXTEEditorSearchTextField *)findTextField {
    if (!_findTextField) {
        XXTEEditorSearchTextField *findTextField = [[XXTEEditorSearchTextField alloc] initWithFrame:self.headerView.bounds];
        findTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _findTextField = findTextField;
    }
    return _findTextField;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [UITableViewCell new];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

@end
