//
//  XUIListViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUI.h"
#import "XUIListViewController.h"
#import "XUICellFactory.h"
#import "XUIListHeaderView.h"
#import "XUIGroupCell.h"
#import <Masonry/Masonry.h>
#import "XUILinkCell.h"
#import "XUIOptionCell.h"
#import "XUIMultipleOptionCell.h"
#import "XUIOrderedOptionCell.h"
#import "XUITitleValueCell.h"
#import "XUIButtonCell.h"
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"
#import "XUIOptionViewController.h"
#import "XUIMultipleOptionViewController.h"
#import "XUIOrderedOptionViewController.h"
#import "XXTECommonWebViewController.h"
#import "XXTEObjectViewController.h"

@interface XUIListViewController () <XUICellFactoryDelegate, XUIOptionViewControllerDelegate, XUIMultipleOptionViewControllerDelegate, XUIOrderedOptionViewControllerDelegate>

@property (nonatomic, strong, readonly) XUICellFactory *parser;
@property (nonatomic, strong) XUIListHeaderView *headerView;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation XUIListViewController

@synthesize entryPath = _entryPath;

+ (XXTExplorerEntryParser *)entryParser {
    static XXTExplorerEntryParser *entryParser = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!entryParser) {
            entryParser = [[XXTExplorerEntryParser alloc] init];
        }
    });
    return entryParser;
}

+ (XXTExplorerEntryService *)entryService {
    static XXTExplorerEntryService *entryService = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!entryService) {
            entryService = [XXTExplorerEntryService sharedInstance];
        }
    });
    return entryService;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super initWithPath:path]) {
        if (!path)
            return nil;
        _entryPath = path;
        [self setup];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path withBundlePath:(NSString *)bundlePath {
    if (self = [super initWithPath:path]) {
        if (!path || !bundlePath)
            return nil;
        _entryPath = path;
        _bundle = [NSBundle bundleWithPath:bundlePath];
        [self setup];
    }
    return self;
}

- (void)setup {
    {
        NSDictionary *rootEntry = nil;
        if (!rootEntry) {
            rootEntry = [[NSDictionary alloc] initWithContentsOfFile:self.entryPath];
        }
        if (!rootEntry) {
            NSData *jsonEntryData = [[NSData alloc] initWithContentsOfFile:self.entryPath];
            if (jsonEntryData) {
                rootEntry = [NSJSONSerialization JSONObjectWithData:jsonEntryData options:0 error:nil];
            }
        }
        if (!rootEntry) {
            return;
        }
        
        XUICellFactory *parser = [[XUICellFactory alloc] initWithRootEntry:rootEntry withBundle:self.bundle];
        if (!parser) {
            return;
        }
        parser.delegate = self;
        _parser = parser;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    NSDictionary <NSString *, id> *rootEntry = self.parser.rootEntry;
    
    NSString *listTitle = rootEntry[@"title"];
    if (listTitle) {
        self.title = listTitle;
    }
    
    {
        [self.parser parse];
    }
    
    NSString *listHeader = rootEntry[@"header"];
    NSString *listSubheader = rootEntry[@"subheader"];
    
    if (listHeader && listSubheader) {
        self.headerView.headerLabel.text = listHeader;
        self.headerView.subheaderLabel.text = listSubheader;
    }
    
    [self setupSubviews];
    [self makeConstraints];

    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
}

- (void)setupSubviews {
    [self.view addSubview:self.tableView];
    if (self.headerView.headerLabel.text.length > 0 &&
        self.headerView.subheaderLabel.text.length > 0) {
        [self.tableView setTableHeaderView:self.headerView];
    }
}

- (void)makeConstraints {
    if (self.headerView.headerLabel.text.length > 0 &&
        self.headerView.subheaderLabel.text.length > 0) {
        [self.headerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.headerView.superview);
            make.width.equalTo(self.tableView);
        }];
    }
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - UIView Getters

- (XUIListHeaderView *)headerView {
    if (!_headerView) {
        XUIListHeaderView *headerView = [[XUIListHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 140.f)];
        _headerView = headerView;
    }
    return _headerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
        XUI_START_IGNORE_PARTIAL
        if (XUI_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XUI_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return self.parser.sectionCells.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.parser.otherCells[(NSUInteger) section].count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return [self tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        XUIBaseCell *cell = self.parser.otherCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        CGFloat cellHeight = [cell.xui_height floatValue];
        return (cellHeight > 0) ? cellHeight : UITableViewAutomaticDimension;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.parser.sectionCells[(NSUInteger) section].xui_label;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.parser.sectionCells[(NSUInteger) section].xui_footerText;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XUIBaseCell *cell = self.parser.otherCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
    if ([cell isKindOfClass:[XUIOptionCell class]]) {
        [self updateLinkListCell:(XUIOptionCell *)cell];
    }
    else if ([cell isKindOfClass:[XUIMultipleOptionCell class]]) {
        [self updateLinkMultipleListCell:(XUIMultipleOptionCell *)cell];
    }
    else if ([cell isKindOfClass:[XUIOrderedOptionCell class]]) {
        [self updateLinkOrderedListCell:(XUIOrderedOptionCell *)cell];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        XUIBaseCell *cell = (XUIBaseCell *)[tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[XUILinkCell class]]) {
            [self tableView:tableView performLinkCell:cell];
        } else if ([cell isKindOfClass:[XUIOptionCell class]]) {
            [self tableView:tableView performLinkListCell:cell];
        } else if ([cell isKindOfClass:[XUIMultipleOptionCell class]]) {
            [self tableView:tableView performLinkMultipleListCell:cell];
        } else if ([cell isKindOfClass:[XUIOrderedOptionCell class]]) {
            [self tableView:tableView performLinkOrderedListCell:cell];
        } else if ([cell isKindOfClass:[XUITitleValueCell class]]) {
            [self tableView:tableView performTitleValueCell:cell];
        } else if ([cell isKindOfClass:[XUIButtonCell class]]) {
            [self tableView:tableView performButtonCell:cell];
        }
    }
}

- (void)tableView:(UITableView *)tableView performButtonCell:(UITableViewCell *)cell {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    XUIButtonCell *buttonCell = (XUIButtonCell *)cell;
    if (buttonCell.xui_action) {
        NSString *selectorName = buttonCell.xui_action;
        SEL actionSelector = NSSelectorFromString(selectorName);
        if (actionSelector && [self respondsToSelector:actionSelector]) {
            [self performSelector:actionSelector withObject:cell];
        }
    }
#pragma clang diagnostic pop
}

- (void)tableView:(UITableView *)tableView performTitleValueCell:(UITableViewCell *)cell {
    XUITitleValueCell *titleValueCell = (XUITitleValueCell *)cell;
    if (titleValueCell.xui_value) {
        id extendedValue = titleValueCell.xui_value;
        XXTEObjectViewController *objectViewController = [[XXTEObjectViewController alloc] initWithRootObject:extendedValue];
        objectViewController.title = titleValueCell.textLabel.text;
        objectViewController.entryBundle = self.bundle;
        [self.navigationController pushViewController:objectViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView performLinkOrderedListCell:(UITableViewCell *)cell {
    XUIOrderedOptionCell *linkListCell = (XUIOrderedOptionCell *)cell;
    if (linkListCell.xui_validTitles && linkListCell.xui_validValues)
    {
        XUIOrderedOptionViewController *optionViewController = [[XUIOrderedOptionViewController alloc] initWithCell:linkListCell];
        optionViewController.delegate = self;
        optionViewController.title = linkListCell.xui_label;
        [self.navigationController pushViewController:optionViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView performLinkMultipleListCell:(UITableViewCell *)cell {
    XUIMultipleOptionCell *linkListCell = (XUIMultipleOptionCell *)cell;
    if (linkListCell.xui_validTitles && linkListCell.xui_validValues)
    {
        XUIMultipleOptionViewController *optionViewController = [[XUIMultipleOptionViewController alloc] initWithCell:linkListCell];
        optionViewController.delegate = self;
        optionViewController.title = linkListCell.xui_label;
        [self.navigationController pushViewController:optionViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView performLinkListCell:(UITableViewCell *)cell {
    XUIOptionCell *linkListCell = (XUIOptionCell *)cell;
    if (linkListCell.xui_validTitles && linkListCell.xui_validValues)
    {
        XUIOptionViewController *optionViewController = [[XUIOptionViewController alloc] initWithCell:linkListCell];
        optionViewController.delegate = self;
        optionViewController.title = linkListCell.xui_label;
        [self.navigationController pushViewController:optionViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView performLinkCell:(UITableViewCell *)cell {
    XUILinkCell *linkCell = (XUILinkCell *)cell;
    NSString *detailPathName = linkCell.xui_path;
    UIViewController *detailController = nil;
    NSURL *detailPathURL = [NSURL URLWithString:detailPathName];
    if ([detailPathURL scheme]) {
        XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:detailPathURL];
        detailController = webController;
    } else {
        NSString *detailPathNameNoExt = [detailPathName stringByDeletingPathExtension];
        NSString *detailPathNameExt = [detailPathName pathExtension];
        NSString *detailPath = [self.bundle pathForResource:detailPathNameNoExt ofType:detailPathNameExt];
        if ([[self.class suggestedExtensions] containsObject:detailPathNameExt]) {
            if (!detailPath)
                detailPath = [self.bundle pathForResource:detailPathNameNoExt ofType:@"plist"];
            if (!detailPath)
                detailPath = [self.bundle pathForResource:detailPathNameNoExt ofType:@"json"];
            if (!detailPath)
                detailPath = [self.bundle pathForResource:detailPathNameNoExt ofType:@"xui"];
            detailController = [[[self class] alloc] initWithPath:detailPath withBundlePath:[self.bundle bundlePath]];
        }
        else {
            NSError *entryError = nil;
            NSDictionary *entryAttributes = [self.class.entryParser entryOfPath:detailPath withError:&entryError];
            if (!entryError && [self.class.entryService hasViewerForEntry:entryAttributes]) {
                UIViewController <XXTEViewer> *viewer = [self.class.entryService viewerForEntry:entryAttributes];
                detailController = viewer;
            }
        }
    }
    if (detailController) {
        detailController.title = linkCell.xui_label;
        [self.navigationController pushViewController:detailController animated:YES];
    }
}

#pragma mark - XUICellFactoryDelegate

- (void)cellFactoryDidFinishParsing:(XUICellFactory *)parser {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)cellFactory:(XUICellFactory *)parser didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *entryName = [self.entryPath lastPathComponent];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"XUI Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n%@", nil), entryName, error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    });
}

#pragma mark - XUIOptionViewControllerDelegate

- (void)optionViewController:(XUIOptionViewController *)controller didSelectOption:(NSInteger)optionIndex {
    [self updateLinkListCell:controller.cell];
    [controller.cell.defaultsService saveDefaultsFromCell:controller.cell];
}

- (void)updateLinkListCell:(XUIOptionCell *)cell {
    NSArray <NSString *> *shortTitles = cell.xui_shortTitles;
    NSUInteger optionIndex = 0;
    id rawValue = cell.xui_value;
    if (rawValue) {
        NSUInteger rawIndex = [cell.xui_validValues indexOfObject:rawValue];
        if ((rawIndex) != NSNotFound) {
            optionIndex = rawIndex;
        }
    }
    if (shortTitles && optionIndex < shortTitles.count) {
        NSString *shortTitle = shortTitles[optionIndex];
        cell.detailTextLabel.text = shortTitle;
    }
}

#pragma mark - XUIMultipleOptionViewControllerDelegate

- (void)multipleOptionViewController:(XUIMultipleOptionViewController *)controller didSelectOption:(NSArray <NSNumber *> *)optionIndexes {
    [self updateLinkMultipleListCell:controller.cell];
    [controller.cell.defaultsService saveDefaultsFromCell:controller.cell];
}

- (void)updateLinkMultipleListCell:(XUIMultipleOptionCell *)cell {
    NSArray *optionValues = cell.xui_value;
    NSString *shortTitle = [NSString stringWithFormat:NSLocalizedString(@"%lu Selected", nil), optionValues.count];
    cell.detailTextLabel.text = shortTitle;
}

#pragma mark - XUIOrderedOptionViewControllerDelegate

- (void)orderedOptionViewController:(XUIOrderedOptionViewController *)controller didSelectOption:(NSArray<NSNumber *> *)optionIndexes {
    [self updateLinkOrderedListCell:controller.cell];
    [controller.cell.defaultsService saveDefaultsFromCell:controller.cell];
}

- (void)updateLinkOrderedListCell:(XUIOrderedOptionCell *)cell {
    NSArray *optionValues = cell.xui_value;
    NSString *shortTitle = [NSString stringWithFormat:NSLocalizedString(@"%lu Selected", nil), optionValues.count];
    cell.detailTextLabel.text = shortTitle;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XUIListViewController dealloc]");
#endif
}

@end
