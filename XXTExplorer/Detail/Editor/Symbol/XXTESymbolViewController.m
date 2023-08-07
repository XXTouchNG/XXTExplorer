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
#import "XXTEEditorTheme.h"
#import "XXTEEditorLanguage.h"
#import "XXTEEditorController.h"
#import "XXTESearchController.h"
#import "XXTEEditorController+NavigationBar.h"

// Views
#import "XXTESymbolCell.h"
#import "XXTEEditorTextView.h"
#import "XXTEEditorMaskView.h"
#import "XXTESingleActionView.h"

// Helpers
#import "SKParser.h"
#import "UIColor+SKColor.h"


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
    self.view.backgroundColor = XXTColorPlainBackground();
    
    UISearchBar *searchBar = nil;
    XXTE_START_IGNORE_PARTIAL
    _searchController = ({
        UISearchController *searchController = [[XXTESearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController.hidesNavigationBarDuringPresentation = YES;
        searchController;
    });
    searchBar = self.searchController.searchBar;
    XXTE_END_IGNORE_PARTIAL
    
    {
        UITextField *textField = [searchBar performSelector:@selector(searchTextField)];
        textField.textColor = XXTColorPlainTitleText();
        textField.tintColor = XXTColorForeground();
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
        tableView.backgroundColor = XXTColorPlainBackground();
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.tableFooterView = [UIView new];
        XXTE_START_IGNORE_PARTIAL
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
        XXTE_END_IGNORE_PARTIAL
        [self.view addSubview:tableView];
        tableView;
    });
    
    self.navigationItem.hidesSearchBarWhenScrolling = YES;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
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
    
    UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 1.0);
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
        if (!self.searchController.active) {
            return self.symbolsTable.count;
        } else {
            return self.displaySymbolsTable.count;
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
        if (!self.searchController.active) {
            [self configureCell:cell forRowAtIndexPath:indexPath];
        } else {
            [self configureDisplayCell:cell fromTableView:tableView forRowAtIndexPath:indexPath];
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

- (void)configureDisplayCell:(XXTESymbolCell *)cell fromTableView:(UITableView *)tableView forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger idx = indexPath.row;
    if (idx < self.displaySymbolsTable.count) {
        NSDictionary *detail = self.displaySymbolsTable[idx];
        NSString *symbolTitle = detail[@"title"];
        BOOL isSearch = NO;
        NSString *searchContent = nil;
        isSearch = self.searchController.active;
        searchContent = self.searchController.searchBar.text;
        if (isSearch) {
            NSMutableAttributedString *attribuedTitle = [[NSMutableAttributedString alloc] initWithString:symbolTitle attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:16.0], NSForegroundColorAttributeName: XXTColorPlainTitleText() }];
            NSRange highlightRange = [symbolTitle rangeOfString:searchContent options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch range:NSMakeRange(0, symbolTitle.length)];
            if (highlightRange.location != NSNotFound) {
                [attribuedTitle addAttributes:@{ NSBackgroundColorAttributeName: XXTColorSearchHighlight() } range:highlightRange];
            }
            [cell.symbolLabel setAttributedText:attribuedTitle];
        } else {
            [cell.symbolLabel setText:symbolTitle];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSRange toRange = {0, 0};
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
    tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
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
    NSString *text = self.searchController.searchBar.text;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", text];
    if (predicate) {
        self.displaySymbolsTable = [[NSArray alloc] initWithArray:[self.symbolsTable filteredArrayUsingPredicate:predicate]];
    }
    [self.tableView reloadData];
}
XXTE_END_IGNORE_PARTIAL

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
