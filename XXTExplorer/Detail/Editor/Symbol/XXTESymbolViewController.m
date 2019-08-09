//
//  XXTESymbolViewController.m
//  XXTExplorer
//
//  Created by Zheng on 05/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESymbolViewController.h"

#import "XXTEEditorDefaults.h"

// Parent
#import "XXTEEditorController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTEEditorTheme.h"
#import "XXTEEditorLanguage.h"
#import "UIColor+SKColor.h"

// Views
#import "XXTESymbolCell.h"
#import "XXTEEditorTextView.h"
#import "XXTEEditorMaskView.h"
#import "XXTESingleActionView.h"

// Helpers
#import "SKParser.h"


@interface XXTESymbolViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
UISearchDisplayDelegate,
UISearchResultsUpdating
>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) XXTESingleActionView *actionView;

@property (nonatomic, strong) NSArray <NSDictionary *> *symbolsTable;
@property (nonatomic, strong) NSArray <NSDictionary *> *displaySymbolsTable;

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;
XXTE_END_IGNORE_PARTIAL

XXTE_START_IGNORE_PARTIAL
@property (nonatomic, strong) UISearchController *searchController;
XXTE_END_IGNORE_PARTIAL

@end

@implementation XXTESymbolViewController

+ (BOOL)hasSymbolPatternsForLanguage:(XXTEEditorLanguage *)language {
    return language.hasSymbol;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    XXTE_START_IGNORE_PARTIAL
    if (self.searchDisplayController.active) {
        return UIStatusBarStyleDefault;
    }
    XXTE_END_IGNORE_PARTIAL
    return UIStatusBarStyleLightContent;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _symbolsTable = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Symbols", nil);
    
    UISearchBar *searchBar = nil;
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 13.0, *)) {
        _searchController = ({
            UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
            searchController.searchResultsUpdater = self;
            searchController.dimsBackgroundDuringPresentation = NO;
            searchController.hidesNavigationBarDuringPresentation = YES;
            searchController;
        });
        searchBar = self.searchController.searchBar;
    } else {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
        _searchDisplayController = ({
            UISearchDisplayController *searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
            searchDisplayController.searchResultsDelegate = self;
            searchDisplayController.searchResultsDataSource = self;
            searchDisplayController.delegate = self;
            searchDisplayController;
        });
    }
    XXTE_END_IGNORE_PARTIAL
    
    {
        if (@available(iOS 13.0, *)) {
            UITextField *textField = [searchBar performSelector:@selector(searchTextField)];
            textField.textColor = [UIColor blackColor];
            textField.tintColor = XXTColorDefault();
        } else {
            searchBar.backgroundColor = [UIColor whiteColor];
            searchBar.barTintColor = [UIColor whiteColor];
            searchBar.tintColor = XXTColorDefault();
        }
        searchBar.placeholder = NSLocalizedString(@"Search Symbol", nil);
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    }
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTESymbolCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTESymbolCellReuseIdentifier];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (@available(iOS 13.0, *)) {
            
        } else {
            tableView.tableHeaderView = searchBar;
        }
        tableView.tableFooterView = [UIView new];
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        [self.view addSubview:tableView];
        tableView;
    });
    if (@available(iOS 13.0, *)) {
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
        self.navigationItem.searchController = self.searchController;
    }
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self.actionView setHidden:YES];
    [self.view addSubview:self.actionView];
    
    NSError *error = nil;
    BOOL result = [self loadFileSymbolsWithError:&error];
    if (!result) {
        toastError(self, error);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.editor renderNavigationBarTheme:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self.editor renderNavigationBarTheme:NO];
    } else {
        [self.editor renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

- (BOOL)loadFileSymbolsWithError:(NSError **)error {
    self.symbolsTable = @[];
    
    BOOL hasSymbol = self.editor.language.hasSymbol;
    if (!hasSymbol) {
        return NO;
    }
    NSString *string = self.editor.textView.text;
    if (!string) {
        return NO;
    }
    SKLanguage *language = self.editor.language.skLanguage;
    if (!language) {
        return NO;
    }
    SKParser *parser = [[SKParser alloc] initWithLanguage:language];
    if (!parser) {
        return NO;
    }
    
    UIViewController *blockVC = blockInteractions(self, YES);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray *symbolsTable = [[NSMutableArray alloc] init];
        [parser parseString:string matchCallback:^(NSString *scopeName, NSRange range) {
            NSArray <NSString *> *scopes = [scopeName componentsSeparatedByString:@"."];
            if ([scopes containsObject:@"entity"]) {
                NSString *title = [string substringWithRange:range];
                NSString *trimmedTitle = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSRange trimmedRange = [title rangeOfString:trimmedTitle];
                if (trimmedRange.location != NSNotFound) {
                    range.location += trimmedRange.location;
                    range.length = trimmedRange.length;
                    NSValue *rangeVal = [NSValue valueWithRange:range];
                    if (rangeVal && trimmedTitle && scopeName) {
                        NSDictionary *cache =
                        @{
                          @"range": rangeVal,
                          @"title": trimmedTitle,
                          @"scopeName": scopeName,
                          };
                        [symbolsTable addObject:cache];
                    }
                }
            }
        }];
        dispatch_async_on_main_queue(^{
            self.symbolsTable = symbolsTable;
            blockInteractions(blockVC, NO);
            [self reloadState];
        });
    });
    return YES;
}

#pragma mark - Reload

- (void)reloadState {
    XXTESingleActionView *actionView = self.actionView;
    if ([[self symbolsTable] count] == 0) {
        [actionView.iconImageView setImage:[UIImage imageNamed:@"XXTENotFound"]];
        [actionView.titleLabel setText:NSLocalizedString(@"404 Not Found", nil)];
        [actionView.descriptionLabel setText:NSLocalizedString(@"No symbol found, would you like to write something exciting?", nil)];
        [actionView setHidden:NO];
    } else {
        [actionView setHidden:YES];
    }
    [self.tableView reloadData];
}

#pragma mark - UIView Getters

- (XXTESingleActionView *)actionView {
    if (!_actionView) {
        XXTESingleActionView *actionView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTESingleActionView class]) owner:nil options:nil] lastObject];
        actionView.frame = self.view.bounds;
        actionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _actionView = actionView;
    }
    return _actionView;
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (0 == section) {
        if (@available(iOS 13.0, *)) {
            if (!self.searchController.active) {
                return self.symbolsTable.count;
            } else {
                return self.displaySymbolsTable.count;
            }
        } else {
            if (tableView == self.tableView) {
                return self.symbolsTable.count;
            } else {
                return self.displaySymbolsTable.count;
            }
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
    {
        XXTESymbolCell *cell =
        [tableView dequeueReusableCellWithIdentifier:XXTESymbolCellReuseIdentifier];
        if (nil == cell)
        {
            cell = [[XXTESymbolCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:XXTESymbolCellReuseIdentifier];
        }
        if (@available(iOS 13.0, *)) {
            if (!self.searchController.active) {
                [self configureCell:cell forRowAtIndexPath:indexPath];
            } else {
                [self configureDisplayCell:cell forRowAtIndexPath:indexPath];
            }
        } else {
            if (tableView == self.tableView) {
                [self configureCell:cell forRowAtIndexPath:indexPath];
            } else {
                [self configureDisplayCell:cell forRowAtIndexPath:indexPath];
            }
        }
        
        return cell;
    }
    return [UITableViewCell new];
}

- (void)configureCell:(XXTESymbolCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger idx = indexPath.row;
    if (idx < self.symbolsTable.count) {
        NSDictionary *detail = self.symbolsTable[idx];
        cell.symbolLabel.text = detail[@"title"];
    }
}

- (void)configureDisplayCell:(XXTESymbolCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger idx = indexPath.row;
    if (idx < self.displaySymbolsTable.count) {
        NSDictionary *detail = self.displaySymbolsTable[idx];
        cell.symbolLabel.text = detail[@"title"];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSRange toRange = {0, 0};
    if (@available(iOS 13.0, *)) {
        if (!self.searchController.active) {
            NSUInteger idx = indexPath.row;
            if (idx < self.symbolsTable.count) {
                NSDictionary *detail = self.symbolsTable[idx];
                toRange = [detail[@"range"] rangeValue];
            }
        } else {
            NSUInteger idx = indexPath.row;
            if (idx < self.displaySymbolsTable.count) {
                NSDictionary *detail = self.displaySymbolsTable[idx];
                toRange = [detail[@"range"] rangeValue];
            }
        }
    } else {
        if (tableView == self.tableView) {
            NSUInteger idx = indexPath.row;
            if (idx < self.symbolsTable.count) {
                NSDictionary *detail = self.symbolsTable[idx];
                toRange = [detail[@"range"] rangeValue];
            }
        } else {
            NSUInteger idx = indexPath.row;
            if (idx < self.displaySymbolsTable.count) {
                NSDictionary *detail = self.displaySymbolsTable[idx];
                toRange = [detail[@"range"] rangeValue];
            }
        }
    }
    [self.editor setNeedsHighlightRange:toRange];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchResultsUpdating (13.0+)

XXTE_START_IGNORE_PARTIAL
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self reloadSearch];
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - UISearchDisplayDelegate

XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTESymbolCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTESymbolCellReuseIdentifier];
    if (@available(iOS 11.0, *)) {
        tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView {
    [self _findAndHideSearchBarShadowInView:tableView];
}
- (void)_findAndHideSearchBarShadowInView:(UIView *)view {
    NSString *usc = @"_";
    NSString *sb = @"UISearchBar";
    NSString *sv = @"ShadowView";
    NSString *s = [[usc stringByAppendingString:sb] stringByAppendingString:sv];
    
    for (UIView *v in view.subviews)
    {
        if ([v isKindOfClass:NSClassFromString(s)]) {
            v.hidden = YES;
        }
        [self _findAndHideSearchBarShadowInView:v];
    }
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self reloadSearch];
    return YES;
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self reloadSearch];
    return YES;
}
XXTE_END_IGNORE_PARTIAL
XXTE_START_IGNORE_PARTIAL
- (void)reloadSearch {
    NSString *text = nil;
    if (@available(iOS 13.0, *)) {
        text = self.searchController.searchBar.text;
    } else {
        text = self.searchDisplayController.searchBar.text;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", text];
    if (predicate) {
        self.displaySymbolsTable = [[NSArray alloc] initWithArray:[self.symbolsTable filteredArrayUsingPredicate:predicate]];
    }
    if (@available(iOS 13.0, *)) {
        [self.tableView reloadData];
    }
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
