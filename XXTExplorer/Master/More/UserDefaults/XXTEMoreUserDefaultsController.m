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
#import "XXTESearchController.h"
#import "XXTEMoreUserDefaultsOperationController.h"

#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

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
    self.definesPresentationContext = YES;
    self.userDefaults = [[NSMutableDictionary alloc] init];
}

#pragma mark - Default Style

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    XXTE_START_IGNORE_PARTIAL
    self.automaticallyAdjustsScrollViewInsets = YES;
    XXTE_END_IGNORE_PARTIAL
    
    if (self.tableView.style == UITableViewStylePlain) {
        self.view.backgroundColor = XXTColorPlainBackground();
    } else {
        self.view.backgroundColor = XXTColorGroupedBackground();
    }
    
    XXTE_START_IGNORE_PARTIAL
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"User Defaults", nil);
    
    XXTE_START_IGNORE_PARTIAL
    _searchController = ({
        UISearchController *searchController = [[XXTESearchController alloc] initWithSearchResultsController:nil];
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
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    XXTE_END_IGNORE_PARTIAL
    
    XXTE_START_IGNORE_PARTIAL
    [self.searchController loadViewIfNeeded];
    XXTE_END_IGNORE_PARTIAL
    
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.placeholder = NSLocalizedString(@"Search User Defaults", nil);
    searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Search User Defaults", nil) attributes:@{ NSForegroundColorAttributeName: [XXTColorBarText() colorWithAlphaComponent:0.5] }];
    if ([searchBar.searchTextField.leftView isKindOfClass:[UIImageView class]])
        [(UIImageView *)searchBar.searchTextField.leftView setTintColor:XXTColorTint()];
    {
        UIButton *clearButton = [searchBar.searchTextField valueForKey:@"_clearButton"];
        UIImage *clearImage = [clearButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [clearButton setImage:clearImage forState:UIControlStateNormal];
        [clearButton setTintColor:[XXTColorTint() colorWithAlphaComponent:0.5]];
    }
    searchBar.scopeButtonTitles = @[ NSLocalizedString(@"Title", nil),
                                     NSLocalizedString(@"Description", nil)
                                     ];
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.delegate = self;
    
    UITextField *textField = [searchBar performSelector:@selector(searchTextField)];
    textField.textColor = XXTColorPlainTitleText();
    textField.tintColor = XXTColorForeground();
    searchBar.barTintColor = XXTColorBarTint();
    searchBar.tintColor = XXTColorTint();

    self.navigationItem.hidesSearchBarWhenScrolling = YES;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    // Only after the assignment it works
    searchBar.searchTextField.textColor = XXTColorBarText();
    
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
    XXTEMoreUserDefaultsOperationController *operationController = [[XXTEMoreUserDefaultsOperationController alloc] initWithStyle:UITableViewStyleInsetGrouped];
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
    [self configureCell:cell withRowDetail:rowDetail];
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

- (void)configureCell:(XXTEMoreTitleDescriptionCell *)cell withRowDetail:(NSDictionary *)rowDetail {
    NSString *rowTitle = rowDetail[@"title"];
    NSString *rowDescription = rowDetail[@"description"];
    if (self.searchController.active) {
        NSString *searchContent = self.searchController.searchBar.text;
        NSUInteger category = self.searchController.searchBar.selectedScopeButtonIndex;
        if (category == kXXTEMoreUserDefaultsSearchTypeTitle) {
            NSMutableAttributedString *attribuedTitle = [[NSMutableAttributedString alloc] initWithString:rowTitle attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:16.0], NSForegroundColorAttributeName: XXTColorPlainTitleText() }];
            NSRange highlightTitleRange = [rowTitle rangeOfString:searchContent options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch range:NSMakeRange(0, rowTitle.length)];
            if (highlightTitleRange.location != NSNotFound) {
                [attribuedTitle addAttributes:@{ NSBackgroundColorAttributeName: XXTColorSearchHighlight() } range:highlightTitleRange];
            }
            [cell.titleLabel setAttributedText:attribuedTitle];
            [cell.descriptionLabel setText:rowDescription];
        } else if (category == kXXTEMoreUserDefaultsSearchTypeDescription) {
            NSMutableAttributedString *attribuedSubtitle = [[NSMutableAttributedString alloc] initWithString:rowDescription attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName: XXTColorForeground() }];
            NSRange highlightSubtitleRange = [rowDescription rangeOfString:searchContent options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch range:NSMakeRange(0, rowDescription.length)];
            if (highlightSubtitleRange.location != NSNotFound) {
                [attribuedSubtitle addAttributes:@{ NSBackgroundColorAttributeName: XXTColorSearchHighlight() } range:highlightSubtitleRange];
            }
            [cell.titleLabel setText:rowTitle];
            [cell.descriptionLabel setAttributedText:attribuedSubtitle];
        }
    } else {
        cell.titleLabel.text = rowTitle;
        cell.descriptionLabel.text = rowDescription;
    }
    
    NSNumber *defaultsValue = self.userDefaults[rowDetail[@"key"]];
    NSInteger optionIndex = [defaultsValue integerValue];
    NSString *optionTitle = rowDetail[@"options"][(NSUInteger) optionIndex];
    cell.valueLabel.text = optionTitle;
}

#pragma mark - UISearchResultsUpdating

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearchByContent:searchText andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    [self reloadSearchByContent:searchBar.text andCategory:searchBar.selectedScopeButtonIndex];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
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
}

#pragma mark - Memory

- (void)dealloc {
    [self.searchController.view removeFromSuperview];
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
