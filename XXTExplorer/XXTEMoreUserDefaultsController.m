//
//  XXTEMoreUserDefaultsController.m
//  XXTExplorer
//
//  Created by Zheng on 08/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreUserDefaultsController.h"
#import "XXTEMoreTitleDescriptionValueCell.h"
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import "UIView+XXTEToast.h"
#import "XXTENetworkDefines.h"
#import "XXTEMoreUserDefaultsOperationController.h"
#import "XXTEAppDefines.h"

enum {
    kXXTEMoreUserDefaultsSearchTypeTitle = 0,
    kXXTEMoreUserDefaultsSearchTypeDescription
};

@interface XXTEMoreUserDefaultsController () <UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate, XXTEMoreUserDefaultsOperationControllerDelegate>
@property (nonatomic, strong) NSArray <NSDictionary *> *defaultsSectionMeta;
@property (nonatomic, strong) NSDictionary *defaultsMeta;
@property (nonatomic, strong) NSDictionary *displayDefaultsMeta;
@property (nonatomic, strong) NSMutableDictionary *userDefaults;
@property (nonatomic, strong, readonly) UISearchController *searchController;

@end

@implementation XXTEMoreUserDefaultsController {
    BOOL isFirstTimeLoaded;
}

//+ (NSUserDefaults *)localDefaults {
//    static NSUserDefaults *localDefaults = nil;
//    if (!localDefaults) {
//        localDefaults = ({
//            [NSUserDefaults standardUserDefaults];
//        });
//    }
//    return localDefaults;
//}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.userDefaults = [[NSMutableDictionary alloc] init];
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.searchController.active) {
        return UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleLightContent;
}

- (BOOL)xxte_prefersNavigationBarHidden {
    if (self.searchController.active) {
        return YES;
    }
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.definesPresentationContext = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    
    self.title = NSLocalizedString(@"User Defaults", nil);
    
    _searchController = ({
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController;
    });
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreTitleDescriptionValueCellReuseIdentifier];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        [self.searchController loadViewIfNeeded];
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.tableView.tableHeaderView = ({
        UISearchBar *searchBar = self.searchController.searchBar;
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        searchBar.placeholder = NSLocalizedString(@"Search User Defaults", nil);
        searchBar.scopeButtonTitles = @[
                                        NSLocalizedString(@"Title", nil),
                                        NSLocalizedString(@"Description", nil)
                                        ];
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
        searchBar.backgroundColor = [UIColor whiteColor];
        searchBar.barTintColor = [UIColor whiteColor];
        searchBar.tintColor = XXTE_COLOR;
        searchBar.delegate = self;
        searchBar;
    });
    
    [self loadStaticUserDefaults];
    [self loadDynamicUserDefaults];
}

- (void)loadStaticUserDefaults {
    
    NSArray <NSDictionary *> *sectionMetas = XXTEBuiltInDefaultsObject(@"SECTION_META");
    self.defaultsSectionMeta = sectionMetas;
    
    NSMutableArray <NSString *> *availableSectionKeys = [[NSMutableArray alloc] initWithCapacity:sectionMetas.count];
    for (NSDictionary *sectionMeta in sectionMetas) {
        [availableSectionKeys addObject:sectionMeta[@"key"]];
    }
    
    NSMutableDictionary *defaultsMutableMeta = [[NSMutableDictionary alloc] init];
    [availableSectionKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull sectionKey, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray <NSDictionary *> *entryArray = XXTEBuiltInDefaultsObject(sectionKey);
        NSMutableArray <NSDictionary *> *entryMutableArray = [[NSMutableArray alloc] initWithCapacity:entryArray.count];
        [entryArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull entryDetail, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([entryDetail[@"enabled"] boolValue]) {
                self.userDefaults[entryDetail[@"key"]] = entryDetail[@"default"];
                [entryMutableArray addObject:entryDetail];
            }
        }];
        defaultsMutableMeta[sectionKey] = [[NSArray alloc] initWithArray:entryMutableArray copyItems:YES];
    }];
    
    self.defaultsMeta = [[NSDictionary alloc] initWithDictionary:defaultsMutableMeta];
}

- (void)loadDynamicUserDefaults {
    blockUserInteractions(self, YES, 2.0);
    PMKPromise *localDefaultsPromise = [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        [self.defaultsMeta enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
        }];
        [((NSArray *)self.defaultsMeta[@"EXPLORER_USER_DEFAULTS"]) enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
            id key = entry[@"key"];
            id value = XXTEDefaultsObject(key, nil);
            if (value) {
                self.userDefaults[key] = value;
            }
        }];
        fulfill(nil);
    }];
    PMKPromise *remoteDefaultsPromise = [NSURLConnection POST:uAppDaemonCommandUrl(@"get_user_conf") JSON:@{}];
    localDefaultsPromise.then(^() {
        return remoteDefaultsPromise;
    })
    .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        return jsonDictionary[@"data"];
    })
    .then(^(NSDictionary *dataDictionary) {
        [dataDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            self.userDefaults[key] = obj;
        }];
    })
    .catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            showUserMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockUserInteractions(self, NO, 2.0);
        [self.tableView reloadData];
    });
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return self.defaultsSectionMeta.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active == NO) {
        return ((NSArray *)self.defaultsMeta[self.defaultsSectionMeta[(NSUInteger) section][@"key"]]).count;
    } else {
        return ((NSArray *)self.displayDefaultsMeta[self.defaultsSectionMeta[(NSUInteger) section][@"key"]]).count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return 66.f;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *sectionKey = self.defaultsSectionMeta[(NSUInteger) indexPath.section][@"key"];
    NSDictionary *rowDetail = nil;
    if (self.searchController.active == NO) {
        rowDetail = self.defaultsMeta[sectionKey][(NSUInteger) indexPath.row];
    } else {
        rowDetail = self.displayDefaultsMeta[sectionKey][(NSUInteger) indexPath.row];
    }
    XXTEMoreUserDefaultsOperationController *operationController = [[XXTEMoreUserDefaultsOperationController alloc] initWithStyle:UITableViewStyleGrouped];
    operationController.delegate = self;
    operationController.userDefaultsEntry = rowDetail;
    NSNumber *defaultsValue = self.userDefaults[rowDetail[@"key"]];
    NSInteger optionIndex = [defaultsValue integerValue];
    operationController.selectedOperation = (NSUInteger) optionIndex;
    [self.navigationController pushViewController:operationController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionKey = self.defaultsSectionMeta[(NSUInteger) indexPath.section][@"key"];
    NSDictionary *rowDetail = nil;
    if (self.searchController.active == NO) {
        rowDetail = self.defaultsMeta[sectionKey][(NSUInteger) indexPath.row];
    } else {
        rowDetail = self.displayDefaultsMeta[sectionKey][(NSUInteger) indexPath.row];
    }
    XXTEMoreTitleDescriptionValueCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEMoreTitleDescriptionValueCellReuseIdentifier];
    cell.titleLabel.text = rowDetail[@"title"];
    cell.descriptionLabel.text = rowDetail[@"description"];
    NSNumber *defaultsValue = self.userDefaults[rowDetail[@"key"]];
    NSInteger optionIndex = [defaultsValue integerValue];
    NSString *optionTitle = rowDetail[@"options"][(NSUInteger) optionIndex];
    cell.valueLabel.text = optionTitle;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return ((NSString *)self.defaultsSectionMeta[(NSUInteger) section][@"title"]);
    }
    return @"";
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    //    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    //    self.navigationController.xxte_fullscreenPopGestureRecognizer.enabled = NO;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    //    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    //    self.navigationController.xxte_fullscreenPopGestureRecognizer.enabled = YES;
}

#pragma mark - UISearchResultsUpdating

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearchByContent:searchText andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self reloadSearchByContent:searchBar.text andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:NO];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadSearchByContent:searchController.searchBar.text andCategory:searchController.searchBar.selectedScopeButtonIndex];
}

- (void)reloadSearchByContent:(NSString *)searchText andCategory:(NSUInteger)category {
    NSPredicate *predicate = nil;
    if (category == kXXTEMoreUserDefaultsSearchTypeTitle) {
        predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", searchText];
    } else if (category == kXXTEMoreUserDefaultsSearchTypeDescription) {
        predicate = [NSPredicate predicateWithFormat:@"description CONTAINS[cd] %@", searchText];
    }
    if (predicate) {
        NSMutableDictionary *displayDefaultsMeta = [[NSMutableDictionary alloc] initWithCapacity:self.defaultsMeta.count];
        [self.defaultsMeta enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSArray *  _Nonnull obj, BOOL * _Nonnull stop) {
            displayDefaultsMeta[key] = [[NSArray alloc] initWithArray:[obj filteredArrayUsingPredicate:predicate]];
        }];
        self.displayDefaultsMeta = displayDefaultsMeta;
    }
    [self.tableView reloadData];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.searchBar.text.length == 0) {
        [self.searchController setActive:NO];
    } else {
        [self.searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - XXTEMoreUserDefaultsOperationControllerDelegate

- (void)userDefaultsOperationController:(XXTEMoreUserDefaultsOperationController *)controller operationSelectedWithIndex:(NSUInteger)index completion:(void (^)(BOOL))block {
    NSString *modifyKey = controller.userDefaultsEntry[@"key"];
    NSMutableDictionary *editedUserDefaults = [[NSMutableDictionary alloc] initWithDictionary:self.userDefaults copyItems:YES];
//    editedUserDefaults[modifyKey] = (index != 0) ? @YES : @NO;
    editedUserDefaults[modifyKey] = @(index);
    blockUserInteractions(self, YES, 2.0);
    NSDictionary *sendUserDefaults = [[NSDictionary alloc] initWithDictionary:editedUserDefaults];
    [NSURLConnection POST:uAppDaemonCommandUrl(@"set_user_conf") JSON:sendUserDefaults]
    .then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
            block(YES);
            self.userDefaults[modifyKey] = @(index);
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot set user defaults: %@", nil), jsonDictionary[@"message"]];
        }
        return [PMKPromise promiseWithValue:editedUserDefaults];
    }).then(^ (NSDictionary *saveDictionary) {
        [saveDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            XXTEDefaultsSetObject(key, obj);
        }];
    }).catch(^(NSError *serverError) {
        block(NO);
        if (serverError.code == -1004) {
            showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            showUserMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockUserInteractions(self, NO, 2.0);
        [self.tableView reloadData];
    });
}

#pragma mark - Memory

- (void)dealloc {
    [self.searchController.view removeFromSuperview];
#ifdef DEBUG
    NSLog(@"[XXTEMoreUserDefaultsController dealloc]");
#endif
}

@end
