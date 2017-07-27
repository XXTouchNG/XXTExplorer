//
//  XUIListViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUI.h"
#import "XUIListViewController.h"
#import "XUIConfigurationParser.h"
#import "XUIListHeaderView.h"
#import <Masonry/Masonry.h>

@interface XUIListViewController ()

@property (nonatomic, strong, readonly) XUIConfigurationParser *parser;
@property (nonatomic, strong) XUIListHeaderView *headerView;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation XUIListViewController

@synthesize entryPath = _entryPath;

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super initWithPath:path]) {
        if (!path) {
            return nil;
        }
        {
            NSDictionary *rootEntry = nil;
            if (!rootEntry) {
                rootEntry = [[NSDictionary alloc] initWithContentsOfFile:path];
            }
            if (!rootEntry) {
                NSData *jsonEntryData = [[NSData alloc] initWithContentsOfFile:path];
                if (jsonEntryData) {
                    rootEntry = [NSJSONSerialization JSONObjectWithData:jsonEntryData options:0 error:nil];
                }
            }
            if (!rootEntry) {
                return nil;
            }
            
            XUIConfigurationParser *parser = [[XUIConfigurationParser alloc] initWithRootEntry:rootEntry];
            if (!parser) {
                return nil;
            }
            _parser = parser;
        }
        _entryPath = path;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.entryPath lastPathComponent];
    
    [self setupSubviews];
    [self makeConstraints];
    
    {
        NSString *entryName = [self.entryPath lastPathComponent];
        NSDictionary <NSString *, id> *rootEntry = self.parser.rootEntry;
        
        NSString *listTitle = rootEntry[@"title"];
        if (listTitle) {
            self.title = listTitle;
        }
        
        NSString *listHeader = rootEntry[@"header"];
        if (listHeader) {
            self.headerView.headerLabel.text = listHeader;
        }
        
        NSString *listSubheader = rootEntry[@"subheader"];
        if (listSubheader) {
            self.headerView.subheaderLabel.text = listSubheader;
        }
        
        if (self.parser.error) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"XUI Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n[Parse Error]\n%@", nil), entryName, self.parser.error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (XXTE_COLLAPSED) {
        self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    }
}

- (void)setupSubviews {
    [self.view addSubview:self.tableView];
    [self.tableView setTableHeaderView:self.headerView];
}

- (void)makeConstraints {
    [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.headerView.superview);
        make.width.equalTo(self.tableView);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - UIView Getters

- (XUIListHeaderView *)headerView {
    if (!_headerView) {
        XUIListHeaderView *headerView = [[XUIListHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 140.f)];
        _headerView = headerView;
    }
    return _headerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
        XUI_START_IGNORE_PARTIAL
        if (XUI_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XUI_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UITableViewCell new];
}

@end
