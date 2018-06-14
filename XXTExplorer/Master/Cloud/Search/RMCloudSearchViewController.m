//
//  RMCloudSearchViewController.m
//  XXTExplorer
//
//  Created by Zheng on 20/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudSearchViewController.h"

#import "RMHotWord.h"
#import "RMCloudTrendsCell.h"

#import "RMCloudLoadingView.h"
#import "XXTESingleActionView.h"

#import "RMCloudProjectViewController.h"

#import "RMCloudListViewController.h"

static NSUInteger const RMCloudSearchTrendsMaximumCount = 24;

typedef enum : NSUInteger {
    RMCloudSearchSectionTrends = 0,
    RMCloudSearchSectionMax,
} RMCloudSearchSection;

@interface RMCloudSearchViewController () <UITableViewDelegate, UITableViewDataSource, RMCloudTrendsCellDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UIScrollViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) RMCloudTrendsCell *trendsCell;
@property (nonatomic, strong) RMCloudLoadingView *pawAnimation;
@property (nonatomic, strong) XXTESingleActionView *comingSoonView;

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong, readonly) UISearchController *searchController;
XXTE_END_IGNORE_PARTIAL

@end

@implementation RMCloudSearchViewController {
    BOOL _isRequesting;
    BOOL _firstLoaded;
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.searchController.active) {
        return UIStatusBarStyleDefault;
    }
    return [super preferredStatusBarStyle];
}

- (BOOL)xxte_prefersNavigationBarHidden {
    if (self.searchController.active) {
        return YES;
    }
    return NO;
}

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _isRequesting = NO;
    _firstLoaded = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.definesPresentationContext = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    self.title = NSLocalizedString(@"Search", nil);
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    XXTE_START_IGNORE_PARTIAL
    _searchController = ({
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController;
    });
    XXTE_END_IGNORE_PARTIAL
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        [self.searchController loadViewIfNeeded];
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.tableView.tableHeaderView = ({
        UISearchBar *searchBar = self.searchController.searchBar;
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        searchBar.placeholder = NSLocalizedString(@"Search RuanMao Cloud", nil);
        searchBar.scopeButtonTitles = @[ ];
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
        searchBar.backgroundColor = [UIColor whiteColor];
        searchBar.barTintColor = [UIColor whiteColor];
        searchBar.tintColor = XXTColorDefault();
        searchBar.delegate = self;
        searchBar;
    });
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.pawAnimation];
    [self.view addSubview:self.comingSoonView];
    
    [self loadHotTrends];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent == nil) {
        [PMKOperationQueue() cancelAllOperations];
    }
}

#pragma mark - Request

- (void)retryInitialLoading:(UIGestureRecognizer *)sender {
    [self.comingSoonView setHidden:YES];
    [self.tableView setHidden:NO];
    [self.pawAnimation setHidden:NO];
    [self loadHotTrends];
}

- (void)loadHotTrends {
    if (_isRequesting) {
        return;
    }
    _isRequesting = YES;
    UIViewController *blockController = blockInteractionsWithToast(self, YES, NO);
    [RMHotWord hotTrendsWithAmount:RMCloudSearchTrendsMaximumCount]
    .then(^ (NSArray <RMHotWord *> *hotWords) {
        if (hotWords.count > 0) {
            [self.trendsCell setHotWords:hotWords];
            [self.tableView reloadData];
            _firstLoaded = YES;
        }
    })
    .catch(^ (NSError *error) {
        toastError(self, error);
        if (error.code != RMApiErrorCode) {
            UITableView *tableView = self.tableView;
            XXTESingleActionView *comingSoonView = self.comingSoonView;
            comingSoonView.titleLabel.text =
            [NSString stringWithFormat:NSLocalizedString(@"Error", nil)];
            comingSoonView.descriptionLabel.text =
            [NSString stringWithFormat:@"%@ (%ld)", [error localizedDescription], (long)[error code]];
            tableView.hidden = YES;
            comingSoonView.hidden = NO;
        }
    })
    .finally(^ () {
        _isRequesting = NO;
        [self.pawAnimation setHidden:YES];
        blockInteractions(blockController, NO);
    });
}

#pragma mark - UIView Getters

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.backgroundColor = [UIColor whiteColor];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.delegate = self;
        tableView.dataSource = self;
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

- (RMCloudLoadingView *)pawAnimation {
    if (!_pawAnimation) {
        RMCloudLoadingView *pawAnimation = [[RMCloudLoadingView alloc] initWithFrame:CGRectMake(0, 0, 41.0, 45.0)];
        pawAnimation.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0);
        pawAnimation.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _pawAnimation = pawAnimation;
    }
    return _pawAnimation;
}

- (XXTESingleActionView *)comingSoonView {
    if (!_comingSoonView) {
        XXTESingleActionView *comingSoonView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTESingleActionView class]) owner:nil options:nil] lastObject];
        comingSoonView.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0);
        comingSoonView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        comingSoonView.hidden = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(retryInitialLoading:)];
        [comingSoonView addGestureRecognizer:tapGesture];
        _comingSoonView = comingSoonView;
    }
    return _comingSoonView;
}

- (RMCloudTrendsCell *)trendsCell {
    if (!_trendsCell) {
        RMCloudTrendsCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([RMCloudTrendsCell class]) owner:nil options:nil] lastObject];
        cell.delegate = self;
        _trendsCell = cell;
    }
    return _trendsCell;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return RMCloudSearchSectionMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section == RMCloudSearchSectionTrends) {
            return 1;
        }
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (@available(iOS 8.0, *)) {
        if (indexPath.section == RMCloudSearchSectionTrends) {
            return 120.f;
        }
    } else {
        return [self tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (@available(iOS 8.0, *)) {
            return UITableViewAutomaticDimension;
        }
        else {
            if (indexPath.section == RMCloudSearchSectionTrends) {
                return [self tableView:tableView heightForAutoResizingCell:self.trendsCell];
            }
        }
    }
    return 0;
}

// work around for iOS 7
- (CGFloat)tableView:(UITableView *)tableView heightForAutoResizingCell:(UITableViewCell *)cell {
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    // UITextViews cannot autosize well with systemLayoutSizeFittingSize: on iOS 7...
    BOOL textViewInside = NO;
    CGFloat additionalUITextViewsHeight = 0.f;
    UIEdgeInsets textViewContainerInsets = UIEdgeInsetsZero;
    for (UIView *subview in cell.contentView.subviews) {
        if ([subview isKindOfClass:[UITextView class]]) {
            textViewInside = YES;
            UITextView *subTextView = (UITextView *)subview;
            CGSize textViewSize = [subTextView sizeThatFits:CGSizeMake(CGRectGetWidth(subTextView.bounds), CGFLOAT_MAX)];
            textViewContainerInsets = subTextView.textContainerInset;
            additionalUITextViewsHeight = textViewSize.height;
            break;
        }
    }
    
    if (textViewInside) {
        return
        additionalUITextViewsHeight +
        textViewContainerInsets.top +
        textViewContainerInsets.bottom +
        1.f;
    }
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    CGFloat fixedHeight = (height > 0) ? (height + 1.f) : 44.f;
    return fixedHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == RMCloudSearchSectionTrends) {
        return self.trendsCell;
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
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(nonnull UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    footer.textLabel.font = [UIFont systemFontOfSize:12.0];
    footer.textLabel.textColor = [UIColor lightGrayColor];
    UIView *bgView = [[UIView alloc] init];
    footer.backgroundView = bgView;
    bgView.backgroundColor = [UIColor clearColor];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (_firstLoaded) {
        if (tableView == self.tableView) {
            if (section == RMCloudSearchSectionTrends) {
                return NSLocalizedString(@"The information on this page is provided by RuanMao Cloud.", nil);
            }
        }
    }
    return nil;
}

#pragma mark - RMCloudTrendsCellDelegate

- (void)trendsCell:(RMCloudTrendsCell *)cell didSelectHotWord:(RMHotWord *)word {
    UISearchBar *searchBar = self.searchController.searchBar;
    [searchBar setText:word.word];
    [self searchBarSearchButtonClicked:searchBar];
}

#pragma mark - UISearchResultsUpdating

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    RMCloudListViewController *controller = [[RMCloudListViewController alloc] init];
    controller.sortBy = RMApiActionSortByCreatedAtDesc;
    controller.searchWord = searchBar.text;
    [self.navigationController pushViewController:controller animated:YES];
}

XXTE_START_IGNORE_PARTIAL
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.searchBar.text.length == 0) {
        [self.searchController setActive:NO];
    } else {
        [self.searchController.searchBar resignFirstResponder];
    }
}

- (void)dealloc {
    [self.searchController.view removeFromSuperview];
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
