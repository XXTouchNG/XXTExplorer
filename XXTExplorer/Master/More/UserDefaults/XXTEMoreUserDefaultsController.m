//
//  XXTEMoreUserDefaultsController.m
//  XXTExplorer
//
//  Created by Zheng on 08/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreUserDefaultsController.h"
#import "XXTEMoreTitleDescriptionCell.h"

#import "UIView+XXTEToast.h"
#import "XXTEMoreUserDefaultsOperationController.h"

#ifndef APPSTORE
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#endif

enum {
    kXXTEMoreUserDefaultsSearchTypeTitle = 0,
    kXXTEMoreUserDefaultsSearchTypeDescription
};

@interface XXTEMoreUserDefaultsController ()
<
UISearchBarDelegate,
UISearchResultsUpdating,
XXTEMoreUserDefaultsOperationControllerDelegate
>

@property (nonatomic, strong) NSArray <NSDictionary *> *defaultsSectionMeta;
@property (nonatomic, strong) NSDictionary *defaultsMeta;
@property (nonatomic, strong) NSDictionary *displayDefaultsMeta;
@property (nonatomic, strong) NSMutableDictionary *userDefaults;

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong, readonly) UISearchController *searchController;
XXTE_END_IGNORE_PARTIAL

@end

@implementation XXTEMoreUserDefaultsController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.definesPresentationContext = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"User Defaults", nil);
    
    XXTE_START_IGNORE_PARTIAL
    _searchController = ({
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController.hidesNavigationBarDuringPresentation = YES;
        searchController;
    });
    XXTE_END_IGNORE_PARTIAL
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTEMoreTitleDescriptionCellReuseIdentifier];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        [self.searchController loadViewIfNeeded];
    }
    XXTE_END_IGNORE_PARTIAL
    
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.placeholder = NSLocalizedString(@"Search User Defaults", nil);
    searchBar.scopeButtonTitles = @[
                                    NSLocalizedString(@"Title", nil),
                                    NSLocalizedString(@"Description", nil)
                                    ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.delegate = self;
    
    if (@available(iOS 11.0, *)) {
        UITextField *textField = nil;
        if (@available(iOS 12.0, *)) {
            textField = searchBar.searchTextField;
        } else {
            textField = [searchBar valueForKey:@"searchField"];
        }
        textField.textColor = [UIColor blackColor];
        textField.tintColor = XXTColorDefault();
        searchBar.barTintColor = [UIColor whiteColor];
        searchBar.tintColor = [UIColor whiteColor];
        if (@available(iOS 12.0, *)) {
            self.navigationItem.hidesSearchBarWhenScrolling = NO;
        } else {
            UIView *backgroundView = [textField.subviews firstObject];
            backgroundView.backgroundColor = [UIColor whiteColor];
            backgroundView.layer.cornerRadius = 10.0;
            backgroundView.clipsToBounds = YES;
        }
        self.navigationItem.searchController = self.searchController;
    }
    else {
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        searchBar.backgroundColor = [UIColor whiteColor];
        searchBar.barTintColor = [UIColor whiteColor];
        searchBar.tintColor = XXTColorDefault();
        self.tableView.tableHeaderView = searchBar;
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
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
#ifndef APPSTORE
    
    UIViewController *blockVC = blockInteractions(self, YES);
    PMKPromise *localDefaultsPromise = [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        for (NSString *metaKey in self.defaultsMeta) {
            NSArray <NSDictionary *> *metaArray = self.defaultsMeta[metaKey];
            if ([metaArray isKindOfClass:[NSArray class]]) {
                [metaArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
                    id key = entry[@"key"];
                    id value = XXTEDefaultsObject(key, nil);
                    if (value) {
                        self.userDefaults[key] = value;
                    }
                }];
            }
        }
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
        toastDaemonError(self, serverError);
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
        [self.tableView reloadData];
    });
    
#else
    
    for (NSString *metaKey in self.defaultsMeta) {
        NSArray <NSDictionary *> *metaArray = self.defaultsMeta[metaKey];
        if ([metaArray isKindOfClass:[NSArray class]]) {
            [metaArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
                id key = entry[@"key"];
                id value = XXTEDefaultsObject(key, nil);
                if (value) {
                    self.userDefaults[key] = value;
                }
            }];
        }
    }
    [self.tableView reloadData];
    
#endif
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
    return 66.f;
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
    XXTEMoreTitleDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:XXTEMoreTitleDescriptionCellReuseIdentifier];
    cell.titleLabel.text = rowDetail[@"title"];
    cell.descriptionLabel.text = rowDetail[@"description"];
    NSNumber *defaultsValue = self.userDefaults[rowDetail[@"key"]];
    NSInteger optionIndex = [defaultsValue integerValue];
    NSString *optionTitle = rowDetail[@"options"][(NSUInteger) optionIndex];
    cell.valueLabel.text = optionTitle;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.font = [UIFont systemFontOfSize:14.0];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(nonnull UIView *)view forSection:(NSInteger)section {
    if (tableView.style == UITableViewStylePlain) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.font = [UIFont systemFontOfSize:12.0];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return ((NSString *)self.defaultsSectionMeta[(NSUInteger) section][@"title"]);
    }
    return @"";
}

#pragma mark - UISearchResultsUpdating

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearchByContent:searchText andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self reloadSearchByContent:searchBar.text andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if (@available(iOS 12.0, *)) {
        
    } else {
        [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:NO];
    }
}

XXTE_START_IGNORE_PARTIAL
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadSearchByContent:searchController.searchBar.text andCategory:searchController.searchBar.selectedScopeButtonIndex];
}
XXTE_END_IGNORE_PARTIAL

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
    editedUserDefaults[modifyKey] = @(index);
    
#ifndef APPSTORE
    
    UIViewController *blockVC = blockInteractions(self, YES);
    NSDictionary *sendUserDefaults = [[NSDictionary alloc] initWithDictionary:editedUserDefaults];
    [NSURLConnection POST:uAppDaemonCommandUrl(@"set_user_conf") JSON:sendUserDefaults]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDictionary) {
        if ([jsonDictionary[@"code"] isEqualToNumber:@(0)]) {
            block(YES);
            self.userDefaults[modifyKey] = @(index);
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot save changes: %@", nil), jsonDictionary[@"message"]];
        }
        return [PMKPromise promiseWithValue:editedUserDefaults];
    })
    .then(^(NSDictionary *saveDictionary) {
        [saveDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            XXTEDefaultsSetObject(key, obj);
        }];
    })
    .catch(^(NSError *serverError) {
        block(NO);
        toastDaemonError(self, serverError);
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
        [self.tableView reloadData];
    });
    
#else
    
    block(YES);
    self.userDefaults[modifyKey] = @(index);
    [editedUserDefaults enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        XXTEDefaultsSetObject(key, obj);
    }];
    [self.tableView reloadData];
    
#endif
    
}

#pragma mark - Memory

- (void)dealloc {
    [self.searchController.view removeFromSuperview];
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
