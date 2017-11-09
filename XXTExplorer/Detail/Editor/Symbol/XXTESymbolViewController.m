//
//  XXTESymbolViewController.m
//  XXTExplorer
//
//  Created by Zheng on 05/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTESymbolViewController.h"

#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"
#import "XXTEEditorDefaults.h"

// Parent
#import "XXTEEditorController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTEEditorTheme.h"
#import "XXTEEditorLanguage.h"
#import "UIColor+SKColor.h"

#import "XXTESymbolCell.h"
#import "XXTEEditorTextView.h"
#import "SKParser.h"

#import "XXTEEditorMaskView.h"

@interface XXTESymbolViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
UISearchDisplayDelegate
>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray <NSDictionary *> *symbolsTable;
@property (nonatomic, strong) NSArray <NSDictionary *> *displaySymbolsTable;

@end

@implementation XXTESymbolViewController {
    UISearchDisplayController *_searchDisplayController;
}

+ (BOOL)hasSymbolPatternsForLanguage:(XXTEEditorLanguage *)language {
    return (language.symbolScopes.count > 0);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.searchDisplayController.active) {
        return UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleLightContent;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
//    NSString *fontName = XXTEDefaultsObject(XXTEEditorFontName, @"CourierNewPSMT");
//    _font = [UIFont fontWithName:fontName size:17.0];
    _symbolsTable = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Symbols", nil);
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
    searchBar.placeholder = NSLocalizedString(@"Search Symbol", nil);
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
    searchBar.backgroundColor = [UIColor whiteColor];
    searchBar.barTintColor = [UIColor whiteColor];
    searchBar.tintColor = XXTE_COLOR;
    
    UISearchDisplayController *searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.searchResultsDataSource = self;
    searchDisplayController.delegate = self;
    _searchDisplayController = searchDisplayController;
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTESymbolCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTESymbolCellReuseIdentifier];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.tableHeaderView = searchBar;
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        [self.view addSubview:tableView];
        tableView;
    });
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    NSError *error = nil;
    BOOL result = [self loadFileSymbolsWithError:&error];
    if (!result) {
        toastMessage(self, [error localizedDescription]);
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
    
    NSArray <NSString *> *symbols = self.editor.language.symbolScopes;
    if (!symbols) {
        return NO;
    }
    NSString *string = self.editor.textView.text;
    if (!string) {
        return NO;
    }
    SKLanguage *language = self.editor.language.rawLanguage;
    if (!language) {
        return NO;
    }
    SKParser *parser = [[SKParser alloc] initWithLanguage:language];
    if (!parser) {
        return NO;
    }
    
    blockInteractions(self, YES);
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
            blockInteractions(self, NO);
            [self.tableView reloadData];
        });
    });
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (0 == section) {
        if (tableView == self.tableView) {
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
        if (tableView == self.tableView) {
            [self configureCell:cell forRowAtIndexPath:indexPath];
        } else {
            [self configureDisplayCell:cell forRowAtIndexPath:indexPath];
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
    if (tableView == self.tableView) {
        NSUInteger idx = indexPath.row;
        if (idx < self.symbolsTable.count) {
            NSDictionary *detail = self.symbolsTable[idx];
            toRange = [detail[@"range"] rangeValue];
            // scroll to range if exists
        }
    } else {
        NSUInteger idx = indexPath.row;
        if (idx < self.displaySymbolsTable.count) {
            NSDictionary *detail = self.displaySymbolsTable[idx];
            toRange = [detail[@"range"] rangeValue];
            // scroll to range if exists
        }
    }
    [self.editor setNeedsHighlightRange:toRange];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass([XXTESymbolCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:XXTESymbolCellReuseIdentifier];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self reloadSearch];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self reloadSearch];
    return YES;
}

- (void)reloadSearch {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", self.searchDisplayController.searchBar.text];
    if (predicate) {
        self.displaySymbolsTable = [[NSArray alloc] initWithArray:[self.symbolsTable filteredArrayUsingPredicate:predicate]];
    }
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTESymbolViewController dealloc]");
#endif
}

@end
