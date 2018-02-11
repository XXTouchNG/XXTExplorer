//
//  RMCloudViewController.m
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudViewController.h"
#import "RMCloudListViewController.h"
#import "RMCloudSearchViewController.h"

#import "RMCloudBroadcastView.h"

@interface RMCloudViewController ()
@property (nonatomic, strong) UIBarButtonItem *searchItem;
@property (nonatomic, strong) RMCloudBroadcastView *broadcastView;

@end

@implementation RMCloudViewController

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.lazyload = YES;
    self.title = NSLocalizedString(@"RuanMao Cloud", nil);
    
    if (XXTE_IS_IPHONE_6_BELOW) {
        self.segmentedControl.segmentMargin = 12.0;
    } else if (XXTE_IS_IPHONE_6P_ABOVE) {
        self.segmentedControl.segmentMargin = 24.0;
    } else {
        self.segmentedControl.segmentMargin = 18.0;
    }
    
    RMCloudListViewController *controller1 = [[RMCloudListViewController alloc] init];
    controller1.title = NSLocalizedString(@"Latest", nil);
    controller1.sortBy = RMApiActionSortByCreatedAtDesc;
    RMCloudListViewController *controller2 = [[RMCloudListViewController alloc] init];
    controller2.title = NSLocalizedString(@"Popular", nil);
    controller2.sortBy = RMApiActionSortByDownloadTimesDesc;
    [self setViewControllers:@[ controller1, controller2 ]];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 39.f, 44.f)]];
    
    if (@available(iOS 8.0, *)) {
        self.navigationItem.rightBarButtonItem = self.searchItem;
    }
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self.view addSubview:self.broadcastView];
    [self configureConstraints];
}

- (void)configureConstraints {
    self.pageScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.broadcastView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray <NSLayoutConstraint *> *constraints =
  @[
    [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTopMargin multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.pageScrollView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:22.0],
    [NSLayoutConstraint constraintWithItem:self.pageScrollView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.pageScrollView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0],
    [NSLayoutConstraint constraintWithItem:self.pageScrollView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:0.0],
    ];
    [self.view addConstraints:constraints];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)searchItem {
    if (!_searchItem) {
        UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"RMSearchIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(searchItemTapped:)];
        _searchItem = searchItem;
    }
    return _searchItem;
}

- (RMCloudBroadcastView *)broadcastView {
    if (!_broadcastView) {
        _broadcastView = [[RMCloudBroadcastView alloc] init];
        _broadcastView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _broadcastView;
}

- (void)searchItemTapped:(UIBarButtonItem *)sender {
    RMCloudSearchViewController *searchController = [[RMCloudSearchViewController alloc] init];
    [self.navigationController pushViewController:searchController animated:YES];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [RMCloudViewController dealloc]");
#endif
}

@end
