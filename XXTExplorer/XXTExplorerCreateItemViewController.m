//
//  XXTExplorerCreateItemViewController.m
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerCreateItemViewController.h"

@interface XXTExplorerCreateItemViewController ()

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;

@end

@implementation XXTExplorerCreateItemViewController

- (instancetype)initWithEntryPath:(NSString *)entryPath {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _entryPath = entryPath;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Create Item", nil);
    
    self.navigationItem.leftBarButtonItem = self.closeButtonItem;
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeButtonItem {
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissViewController:)];
        closeButtonItem.tintColor = [UIColor whiteColor];
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

#pragma mark - UIControl Actions

- (void)dismissViewController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
