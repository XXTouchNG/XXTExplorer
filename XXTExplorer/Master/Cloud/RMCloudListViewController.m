//
//  RMCloudListViewController.m
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudListViewController.h"
#import "RMCloudProjectCell.h"
#import "RMCloudMoreCell.h"
#import "RMCloudProjectViewController.h"
#import "RMCloudLoadingView.h"
#import "RMCloudComingSoon.h"


typedef enum : NSUInteger {
    RMCloudListSectionProject = 0,
    RMCloudListSectionMore,
    RMCloudListSectionMax
} RMCloudListSection;

static NSUInteger const RMCloudListItemsPerPage = 20;

@interface RMCloudListViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UIViewControllerPreviewingDelegate, RMCloudProjectCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSMutableArray <RMProject *> *projects;
@property (nonatomic, strong) RMCloudLoadingView *pawAnimation;
@property (nonatomic, strong) RMCloudComingSoon *comingSoonView;
@property (nonatomic, strong) id<UIViewControllerPreviewing> previewingContext;

@end

@implementation RMCloudListViewController {
    BOOL _isRequesting;
    BOOL _firstLoaded;
    NSUInteger _currentPage;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _projects = [[NSMutableArray alloc] init];
    _isRequesting = NO;
    _currentPage = 0;
    _firstLoaded = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.searchWord.length > 0) {
        self.title = [NSString stringWithFormat:NSLocalizedString(@"Search \"%@\"", nil), self.searchWord];
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.comingSoonView];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    UITableView *tableView = self.tableView;
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RMCloudProjectCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:RMCloudProjectCellReuseIdentifier];
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RMCloudMoreCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:RMCloudMoreCellReuseIdentifier];
    [self.view addSubview:tableView];
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    [tableViewController setTableView:tableView];
    [tableViewController setRefreshControl:self.refreshControl];
    [self.tableView.backgroundView insertSubview:self.refreshControl atIndex:0];
    [self.view addSubview:self.pawAnimation];
    
    [self loadInitialProjects:self.refreshControl];
}

XXTE_START_IGNORE_PARTIAL
- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInset =
        self.tableView.scrollIndicatorInsets =
        self.view.safeAreaInsets;
    }
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
            // retain the context to avoid registering more than once
            if (!self.previewingContext) {
                self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
            }
        } else {
            [self unregisterForPreviewingWithContext:self.previewingContext];
            self.previewingContext = nil;
        }
    }
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Fetch Database

- (void)retryInitialLoading:(UIGestureRecognizer *)sender {
    [self.comingSoonView setHidden:YES];
    [self.tableView setHidden:NO];
    [self.pawAnimation setHidden:NO];
    [self loadInitialProjects:self.refreshControl];
}

- (void)loadInitialProjects:(UIRefreshControl *)refreshControl {
    if (_isRequesting) {
        if ([refreshControl isRefreshing]) {
            [refreshControl endRefreshing];
        }
        return;
    }
    _currentPage = 0;
    [self.projects removeAllObjects];
    [self loadMoreProjects:refreshControl];
}

- (void)loadMoreProjects:(UIRefreshControl *)refreshControl {
    if (_isRequesting) {
        if ([refreshControl isRefreshing]) {
            [refreshControl endRefreshing];
        }
        return;
    }
    _isRequesting = YES;
    PMKPromise *filterPromise = nil;
    if (self.searchWord.length > 0) {
        filterPromise = [RMProject filteredListWithKeyword:self.searchWord atPage:(_currentPage + 1) itemsPerPage:RMCloudListItemsPerPage];
    } else {
        filterPromise = [RMProject sortedList:self.sortBy atPage:(_currentPage + 1) itemsPerPage:RMCloudListItemsPerPage];
    }
    filterPromise
    .then(^ (NSArray <RMProject *> *models) {
        if (models.count > 0) {
            [self.projects addObjectsFromArray:models];
            [self.tableView reloadData];
            _currentPage = _currentPage + 1;
            _firstLoaded = YES;
        }
    })
    .catch(^ (NSError *error) {
        toastMessage(self, error.localizedDescription);
        if (error.code != RMApiErrorCode) {
            UITableView *tableView = self.tableView;
            RMCloudComingSoon *comingSoonView = self.comingSoonView;
            comingSoonView.titleLabel.text =
            [NSString stringWithFormat:NSLocalizedString(@"Error", nil)];
            comingSoonView.descriptionLabel.text =
            [NSString stringWithFormat:@"%@ (%ld)", [error localizedDescription], (long)[error code]];
            if (NO == _firstLoaded) {
                tableView.hidden = YES;
                comingSoonView.hidden = NO;
            }
        }
    })
    .finally(^ () {
        if ([refreshControl isRefreshing]) {
            [refreshControl endRefreshing];
        }
        _isRequesting = NO;
        [self.pawAnimation setHidden:YES];
    });
}

#pragma mark - UIView Getters

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        if (@available(iOS 11.0, *)) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        XXTE_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(loadInitialProjects:) forControlEvents:UIControlEventValueChanged];
        _refreshControl = refreshControl;
    }
    return _refreshControl;
}

- (RMCloudLoadingView *)pawAnimation {
    if (!_pawAnimation) {
        RMCloudLoadingView *pawAnimation = [[RMCloudLoadingView alloc] initWithFrame:CGRectMake(0, 0, 44.0, 44.0)];
        pawAnimation.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0);
        pawAnimation.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _pawAnimation = pawAnimation;
    }
    return _pawAnimation;
}

- (RMCloudComingSoon *)comingSoonView {
    if (!_comingSoonView) {
        RMCloudComingSoon *comingSoonView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([RMCloudComingSoon class]) owner:nil options:nil] lastObject];
        comingSoonView.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0);
        comingSoonView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        comingSoonView.hidden = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retryInitialLoading:)];
        [comingSoonView addGestureRecognizer:tapGesture];
        _comingSoonView = comingSoonView;
    }
    return _comingSoonView;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return RMCloudListSectionMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == RMCloudListSectionProject) {
        return self.projects.count;
    } else if (section == RMCloudListSectionMore) {
        if (self.projects.count == 0)
        {
            return 0;
        }
        else
        {
            return 1;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RMCloudListSectionProject) {
        return 68.f;
    } else if (indexPath.section == RMCloudListSectionMore) {
        return 68.f;
    }
    return 68.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RMCloudListSectionProject) {
        RMCloudProjectCell *cell = [tableView dequeueReusableCellWithIdentifier:RMCloudProjectCellReuseIdentifier];
        if (cell == nil) {
            cell = [[RMCloudProjectCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RMCloudProjectCellReuseIdentifier];
        }
        RMProject *project = nil;
        if (indexPath.row < self.projects.count) {
            project = self.projects[indexPath.row];
        }
        if (project) {
            [cell setProject:project];
            [cell setDelegate:self];
        }
        return cell;
    } else if (indexPath.section == RMCloudListSectionMore) {
        RMCloudMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:RMCloudMoreCellReuseIdentifier];
        if (cell == nil) {
            cell = [[RMCloudMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RMCloudMoreCellReuseIdentifier];
        }
        return cell;
    }
    return [UITableViewCell new];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UITableViewHeaderFooterView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == RMCloudListSectionProject) {
        RMProject *project = nil;
        if (indexPath.row < self.projects.count)
        {
            project = self.projects[indexPath.row];
        }
        UIViewController *controller = [self preparePushForProject:project];
        [self.navigationController pushViewController:controller animated:YES];
    } else if (indexPath.section == RMCloudListSectionMore) {
        [self loadMoreProjects:nil];
    }
}

- (UIViewController *)preparePushForProject:(RMProject *)project {
    if (!project) return nil;
    RMCloudProjectViewController *controller = [[RMCloudProjectViewController alloc] initWithProjectID:project.projectID];
    controller.title = project.projectName;
    return controller;
}

#pragma mark - RMCloudProjectCellDelegate

- (void)projectCell:(RMCloudProjectCell *)cell downloadButtonTapped:(UIButton *)button {
    RMProject *project = cell.project;
    if (!project) {
        return;
    }
    UIViewController *blockController = blockInteractions(self, YES);
    [project downloadURL]
    .then(^(id model) {
        NSString *downloadURL = nil;
        NSString *downloadPath = nil;
        if ([model isKindOfClass:[NSString class]]) {
            downloadURL = (NSString *)model;
        } else if ([model isKindOfClass:[RMProjectDownloadModel class]]) {
            RMProjectDownloadModel *downloadModel = (RMProjectDownloadModel *)model;
            downloadURL = downloadModel.url;
            downloadPath = downloadModel.path;
        }
        if (downloadURL) {
            NSURL *sourceURL = [NSURL URLWithString:downloadURL];
            NSString *scheme = sourceURL.scheme;
            if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])
            {
                NSMutableDictionary *internalArgs =
                [@{
                   @"url": downloadURL,
                   @"instantView": @"true"
                   } mutableCopy];
                if (downloadPath) {
                    internalArgs[@"path"] = downloadPath;
                }
                NSDictionary *userInfo =
                @{XXTENotificationShortcutInterface: @"download",
                  XXTENotificationShortcutUserData: [internalArgs copy]};
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationShortcut object:nil userInfo:userInfo]];
            }
        }
    })
    .catch(^ (NSError *error) {
        toastMessage(self, error.localizedDescription);
    })
    .finally(^() {
        blockInteractions(blockController, NO);
    });
}

#pragma mark - Gesture Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

#pragma mark - UIViewControllerPreviewingDelegate

XXTE_START_IGNORE_PARTIAL
- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    if ([viewControllerToCommit isKindOfClass:[RMCloudProjectViewController class]]) {
        [self.navigationController pushViewController:viewControllerToCommit animated:NO];
    }
}
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    UITableView *tableView = self.tableView;
    if ([tableView isEditing]) {
        return nil;
    }
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:location];
    if (!indexPath) return nil;
    if (@available(iOS 9.0, *)) {
        previewingContext.sourceRect = [tableView rectForRowAtIndexPath:indexPath];
    }
    if (indexPath.section == RMCloudListSectionProject) {
        RMProject *project = nil;
        if (indexPath.row < self.projects.count)
        {
            project = self.projects[indexPath.row];
        }
        UIViewController *controller = [self preparePushForProject:project];
        return controller;
    }
    return nil;
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [RMCloudListViewController dealloc]");
#endif
}

@end
