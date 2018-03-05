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

@interface RMCloudViewController ()
@property (nonatomic, strong) UIBarButtonItem *searchItem;

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
    
    if (@available(iOS 8.0, *)) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 39.f, 44.f)]];
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
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)searchItem {
    if (!_searchItem) {
        UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"RMSearchIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(searchItemTapped:)];
        _searchItem = searchItem;
    }
    return _searchItem;
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
