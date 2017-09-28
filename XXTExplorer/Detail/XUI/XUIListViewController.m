//
//  XUIListViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUI.h"
#import "XUIListViewController.h"

#import "XUIListHeaderView.h"
#import "XUIListFooterView.h"

#import "XUIGroupCell.h"
#import "XUILinkCell.h"
#import "XUIOptionCell.h"
#import "XUIMultipleOptionCell.h"
#import "XUIOrderedOptionCell.h"
#import "XUITitleValueCell.h"
#import "XUIButtonCell.h"
#import "XUITextareaCell.h"
#import "XUIFileCell.h"

#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"
#import "XXTENotificationCenterDefines.h"

#import "XUIOptionViewController.h"
#import "XUIMultipleOptionViewController.h"
#import "XUIOrderedOptionViewController.h"
#import "XXTECommonWebViewController.h"
#import "XXTEObjectViewController.h"
#import "XUITextareaViewController.h"

#import "XUICellFactory.h"
#import "XUILogger.h"
#import "XUITheme.h"
#import "XUIAdapter.h"

#import "XXTPickerSnippet.h"
#import "XXTPickerFactory.h"

#import "XXTExplorerItemPicker.h"

@interface XUIListViewController () <XUICellFactoryDelegate, XUIOptionViewControllerDelegate, XUIMultipleOptionViewControllerDelegate, XUIOrderedOptionViewControllerDelegate, XUITextareaViewControllerDelegate, XXTPickerFactoryDelegate, XXTExplorerItemPickerDelegate>

@property (nonatomic, strong) NSMutableArray <XUIBaseCell *> *cellsNeedStore;
@property (nonatomic, assign) BOOL shouldStoreCells;

@property (nonatomic, strong, readonly) XUICellFactory *cellFactory;
@property (nonatomic, strong, readonly) XXTPickerFactory *pickerFactory;

@property (nonatomic, strong) XUIListHeaderView *headerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) XUIListFooterView *footerView;

@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *aboutButtonItem;
@property (nonatomic, assign) UIEdgeInsets defaultContentInsets;

@end

@implementation XUIListViewController

@synthesize theme = _theme, adapter = _adapter;

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

#pragma mark - Initializers

- (instancetype)initWithPath:(NSString *)path {
    if (!path)
        return nil;
    _bundle = nil;
    if (self = [super initWithPath:path]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path withBundlePath:(NSString *)bundlePath {
    if (!path || !bundlePath)
        return nil;
    NSString *absolutePath = nil;
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if ([path isAbsolutePath]) {
        absolutePath = path;
    } else {
        absolutePath = [bundle pathForResource:path ofType:nil];
    }
    if (!absolutePath) {
        return nil;
    }
    _bundle = bundle;
    if (self = [super initWithPath:absolutePath]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    {
        _cellsNeedStore = [[NSMutableArray alloc] init];
        
        XXTPickerFactory *factory = [[XXTPickerFactory alloc] init];
        factory.delegate = self;
        _pickerFactory = factory;
        
        XUIAdapter *adapter = [[XUIAdapter alloc] initWithXUIPath:self.entryPath Bundle:self.bundle];
        if (!adapter) {
            return;
        }
        _adapter = adapter;
        
        NSError *xuiError = nil;
        XUICellFactory *cellFactory = [[XUICellFactory alloc] initWithAdapter:adapter Error:&xuiError];
        if (!xuiError) {
            cellFactory.delegate = self;
            _cellFactory = cellFactory;
            _theme = cellFactory.theme;
        } else {
            [self presentErrorAlertController:xuiError];
        }
        
    }
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    NSDictionary <NSString *, id> *rootEntry = self.cellFactory.rootEntry;
    
    NSString *listTitle = rootEntry[@"title"];
    if (listTitle) {
        self.title = listTitle;
    }
    
    {
        [self.cellFactory parse];
    }
    
    {
        NSString *listHeader = rootEntry[@"header"];
        NSString *listSubheader = rootEntry[@"subheader"];
        if ([listHeader isKindOfClass:[NSString class]] && [listSubheader isKindOfClass:[NSString class]]) {
            self.headerView.headerText = listHeader;
            self.headerView.subheaderText = listSubheader;
        }
    }
    
#ifdef DEBUG
    {
        NSString *listFooter = rootEntry[@"footer"];
        if ([listFooter isKindOfClass:[NSString class]]) {
            self.footerView.footerText = listFooter;
        }
    }
#else
    {
        self.footerView.footerText = NSLocalizedString(@"This page is provided by the script producer.", nil);
    }
#endif
    
    [self setupSubviews];

    if (self.awakeFromOutside == NO &&
        [self.navigationController.viewControllers firstObject] == self) {
        XXTE_START_IGNORE_PARTIAL
        if (XXTE_COLLAPSED) {
            [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
        } else {
            [self.navigationItem setLeftBarButtonItem:self.closeButtonItem];
        }
        XXTE_END_IGNORE_PARTIAL
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidAppear:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDisappear:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotifications:) name:XXTENotificationEvent object:nil];
    [super viewWillAppear:animated];
    [self storeCellsIfNecessary];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)setupSubviews {
    [self.view addSubview:self.tableView];
    
    self.tableView.contentInset =
    self.tableView.scrollIndicatorInsets = self.defaultContentInsets;
    [self.tableView setContentOffset:CGPointMake(0, -self.defaultContentInsets.top) animated:YES];
    
    if (@available(iOS 8.0, *)) {
        {
            CGFloat height = self.headerView.intrinsicContentSize.height;
            CGRect headerFrame = self.headerView.frame;
            headerFrame.size.height = height;
            self.headerView.frame = headerFrame;
            [self.tableView setTableHeaderView:self.headerView];
            self.headerView.theme = self.theme;
        }
        
        {
            CGFloat height = self.footerView.intrinsicContentSize.height;
            CGRect footerFrame = self.footerView.frame;
            footerFrame.size.height = height;
            self.footerView.frame = footerFrame;
            [self.tableView setTableFooterView:self.footerView];
            self.footerView.theme = self.theme;
        }
    } else {
        {
            [self.headerView setNeedsLayout];
            [self.headerView layoutIfNeeded];
            CGFloat height = [self.headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            CGRect headerFrame = self.headerView.frame;
            headerFrame.size.height = height;
            self.headerView.frame = headerFrame;
            [self.tableView setTableHeaderView:self.headerView];
            self.headerView.theme = self.theme;
        }
        
        {
            [self.footerView setNeedsLayout];
            [self.footerView layoutIfNeeded];
            CGFloat height = [self.footerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
            CGRect footerFrame = self.footerView.frame;
            footerFrame.size.height = height;
            self.footerView.frame = footerFrame;
            [self.tableView setTableFooterView:self.footerView];
            self.footerView.theme = self.theme;
        }
    }
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeButtonItem {
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonItemTapped:)];
        closeButtonItem.tintColor = [UIColor whiteColor];
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

- (XUIListHeaderView *)headerView {
    if (!_headerView) {
        XUIListHeaderView *headerView = [[XUIListHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0.f)];
        _headerView = headerView;
    }
    return _headerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.estimatedRowHeight = 44.f;
        XUI_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XUI_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

- (XUIListFooterView *)footerView {
    if (!_footerView) {
        XUIListFooterView *footerView = [[XUIListFooterView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0.f)];
        _footerView = footerView;
    }
    return _footerView;
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return self.cellFactory.sectionCells.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.cellFactory.otherCells[(NSUInteger) section].count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (@available(iOS 8.0, *)) {
        return 44.f;
    } else {
        return [self tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        XUIBaseCell *cell = self.cellFactory.otherCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        CGFloat cellHeight = [cell.xui_height floatValue];
        if (cellHeight > 0) {
            return cellHeight;
        } else {
            if ([[cell class] layoutUsesAutoResizing]) {
                [cell setNeedsUpdateConstraints];
                [cell updateConstraintsIfNeeded];
                
                cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
                [cell setNeedsLayout];
                [cell layoutIfNeeded];
                
                CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
                CGFloat fixedHeight = (height > 0) ? (height + 1.f) : 44.f;
                return fixedHeight;
            } else {
                return UITableViewAutomaticDimension;
            }
        }
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.cellFactory.sectionCells[(NSUInteger) section].xui_label;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.cellFactory.sectionCells[(NSUInteger) section].xui_footerText;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XUIBaseCell *cell = self.cellFactory.otherCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
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
        XUIBaseCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        BOOL readonly = [cell.xui_readonly boolValue];
        if (readonly) {
            return;
        }
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
        } else if ([cell isKindOfClass:[XUITextareaCell class]]) {
            [self tableView:tableView performTextareaCell:cell];
        } else if ([cell isKindOfClass:[XUIFileCell class]]) {
            [self tableView:tableView performFileCell:cell];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    XUIBaseCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    BOOL readonly = [cell.xui_readonly boolValue];
    if (readonly) {
        return;
    }
    if ([cell isKindOfClass:[XUITitleValueCell class]]) {
        XUITitleValueCell *titleValueCell = (XUITitleValueCell *)cell;
        if (titleValueCell.xui_snippet) {
            NSString *snippetPath = [self.bundle pathForResource:titleValueCell.xui_snippet ofType:nil];
            NSError *snippetError = nil;
            XXTPickerSnippet *snippet = [[XXTPickerSnippet alloc] initWithContentsOfFile:snippetPath Error:&snippetError];
            if (snippetError) {
                [self presentErrorAlertController:snippetError];
                return;
            }
            XXTPickerFactory *factory = self.pickerFactory;
            [factory executeTask:snippet fromViewController:self];
            self.pickerCell = titleValueCell;
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    XUIBaseCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    BOOL readonly = [cell.xui_readonly boolValue];
    if (readonly) {
        return NO;
    }
    if (cell.canDelete) {
        if (cell.xui_value) {
            return YES;
        }
    }
    return NO;
}

XXTE_START_IGNORE_PARTIAL
- (NSArray <UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    @weakify(self);
    UITableViewRowAction *button = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
        {
            @strongify(self);
            [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
        }];
    button.backgroundColor = self.theme.dangerColor;
    return @[button];
}
XXTE_END_IGNORE_PARTIAL

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    XUIBaseCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.canDelete) {
        cell.xui_value = nil;
        [self.adapter saveDefaultsFromCell:cell];
    }
    [cell setEditing:NO animated:YES];
}

- (void)tableView:(UITableView *)tableView performFileCell:(UITableViewCell *)cell {
    XUIFileCell *fileCell = (XUIFileCell *)cell;
    NSString *bundlePath = [self.bundle bundlePath];
    NSString *initialPath = fileCell.xui_initialPath;
    // NSString *filePath = fileCell.xui_value;
    if (initialPath) {
        if ([initialPath isAbsolutePath]) {
            
        } else {
            initialPath = [bundlePath stringByAppendingPathComponent:initialPath];
        }
    } else {
        initialPath = bundlePath;
    }
    self.pickerCell = fileCell;
    XXTExplorerItemPicker *itemPicker = [[XXTExplorerItemPicker alloc] initWithEntryPath:initialPath];
    itemPicker.delegate = self;
    itemPicker.allowedExtensions = fileCell.xui_allowedExtensions;
    [self.navigationController pushViewController:itemPicker animated:YES];
}

- (void)tableView:(UITableView *)tableView performButtonCell:(UITableViewCell *)cell {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    XUIButtonCell *buttonCell = (XUIButtonCell *)cell;
    BOOL readonly = [buttonCell.xui_readonly boolValue];
    if (readonly == NO && buttonCell.xui_action) {
        NSString *cellAction = buttonCell.xui_action;
        if (cellAction) {
            NSString *selectorName = [NSString stringWithFormat:@"xui_%@", cellAction];
            SEL actionSelector = NSSelectorFromString(selectorName);
            if (actionSelector && [self respondsToSelector:actionSelector]) {
                id performObject = [self performSelector:actionSelector withObject:cell];
                buttonCell.xui_value = performObject;
                [self.adapter saveDefaultsFromCell:buttonCell];
            } else {
                if (actionSelector) {
                    [self.cellFactory.logger logMessage:XUIParserErrorUndknownSelector(NSStringFromSelector(actionSelector))];
                }
            }
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
    if (linkListCell.xui_options)
    {
        XUIOrderedOptionViewController *optionViewController = [[XUIOrderedOptionViewController alloc] initWithCell:linkListCell];
        optionViewController.adapter = self.adapter;
        optionViewController.delegate = self;
        optionViewController.title = linkListCell.xui_label;
        optionViewController.theme = self.cellFactory.theme;
        [self.navigationController pushViewController:optionViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView performLinkMultipleListCell:(UITableViewCell *)cell {
    XUIMultipleOptionCell *linkListCell = (XUIMultipleOptionCell *)cell;
    if (linkListCell.xui_options)
    {
        XUIMultipleOptionViewController *optionViewController = [[XUIMultipleOptionViewController alloc] initWithCell:linkListCell];
        optionViewController.adapter = self.adapter;
        optionViewController.delegate = self;
        optionViewController.title = linkListCell.xui_label;
        optionViewController.theme = self.cellFactory.theme;
        [self.navigationController pushViewController:optionViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView performLinkListCell:(UITableViewCell *)cell {
    XUIOptionCell *linkListCell = (XUIOptionCell *)cell;
    if (linkListCell.xui_options)
    {
        XUIOptionViewController *optionViewController = [[XUIOptionViewController alloc] initWithCell:linkListCell];
        optionViewController.adapter = self.adapter;
        optionViewController.delegate = self;
        optionViewController.title = linkListCell.xui_label;
        optionViewController.theme = self.cellFactory.theme;
        [self.navigationController pushViewController:optionViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView performLinkCell:(UITableViewCell *)cell {
    XUILinkCell *linkCell = (XUILinkCell *)cell;
    NSString *detailUrl = linkCell.xui_url;
    UIViewController *detailController = nil;
    NSURL *detailPathURL = [NSURL URLWithString:detailUrl];
    if ([detailPathURL scheme]) {
        XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:detailPathURL];
        detailController = webController;
    } else {
        NSString *detailPathNameExt = [[detailUrl pathExtension] lowercaseString];
        NSString *detailPath = [self.bundle pathForResource:detailUrl ofType:nil];
        if ([[self.class suggestedExtensions] containsObject:detailPathNameExt]) {
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

- (void)tableView:(UITableView *)tableView performTextareaCell:(UITableViewCell *)cell {
    XUITextareaCell *textareaCell = (XUITextareaCell *)cell;
    XUITextareaViewController *textareaViewController = [[XUITextareaViewController alloc] initWithCell:textareaCell];
    textareaViewController.adapter = self.adapter;
    textareaViewController.delegate = self;
    textareaViewController.title = textareaCell.xui_label;
    [self.navigationController pushViewController:textareaViewController animated:YES];
}

#pragma mark - XUICellFactoryDelegate

- (void)cellFactoryDidFinishParsing:(XUICellFactory *)cellFactory {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)cellFactory:(XUICellFactory *)cellFactory didFailWithError:(NSError *)error {
    [self presentErrorAlertController:error];
}

- (void)presentErrorAlertController:(NSError *)error {
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        NSString *entryName = [self.entryPath lastPathComponent];
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 8.0, *)) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"XUI Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n%@: %@", nil), entryName, error.localizedDescription, error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"XUI Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n%@: %@", nil), entryName, error.localizedDescription, error.localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alertView show];
        }
        XXTE_END_IGNORE_PARTIAL
    });
}

#pragma mark - XUIOptionViewControllerDelegate

- (void)optionViewController:(XUIOptionViewController *)controller didSelectOption:(NSInteger)optionIndex {
    [self updateLinkListCell:controller.cell];
    [self.cellFactory.adapter saveDefaultsFromCell:controller.cell];
}

- (void)updateLinkListCell:(XUIOptionCell *)cell {
    NSUInteger optionIndex = 0;
    id rawValue = cell.xui_value;
    if (rawValue) {
        NSUInteger rawIndex = [cell.xui_options indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([rawValue isEqual:obj[XUIOptionCellValueKey]]) {
                return YES;
            }
            return NO;
        }];
        if ((rawIndex) != NSNotFound) {
            optionIndex = rawIndex;
        }
    }
    if (optionIndex < cell.xui_options.count) {
        NSString *shortTitle = cell.xui_options[optionIndex][XUIOptionCellShortTitleKey];
        cell.detailTextLabel.text = shortTitle;
    }
}

#pragma mark - XUIMultipleOptionViewControllerDelegate

- (void)multipleOptionViewController:(XUIMultipleOptionViewController *)controller didSelectOption:(NSArray <NSNumber *> *)optionIndexes {
    [self updateLinkMultipleListCell:controller.cell];
    [self.cellFactory.adapter saveDefaultsFromCell:controller.cell];
}

- (void)updateLinkMultipleListCell:(XUIMultipleOptionCell *)cell {
    NSArray *optionValues = cell.xui_value;
    NSString *shortTitle = [NSString stringWithFormat:NSLocalizedString(@"%lu Selected", nil), optionValues.count];
    cell.detailTextLabel.text = shortTitle;
}

#pragma mark - XUIOrderedOptionViewControllerDelegate

- (void)orderedOptionViewController:(XUIOrderedOptionViewController *)controller didSelectOption:(NSArray<NSNumber *> *)optionIndexes {
    [self updateLinkOrderedListCell:controller.cell];
    [self.cellFactory.adapter saveDefaultsFromCell:controller.cell];
}

- (void)updateLinkOrderedListCell:(XUIOrderedOptionCell *)cell {
    NSArray *optionValues = cell.xui_value;
    NSString *shortTitle = [NSString stringWithFormat:NSLocalizedString(@"%lu Selected", nil), optionValues.count];
    cell.detailTextLabel.text = shortTitle;
}

#pragma mark - XUITextareaViewControllerDelegate

- (void)textareaViewControllerTextDidChanged:(XUITextareaViewController *)controller {
    [self storeCellWhenNeeded:controller.cell];
}

#pragma mark - XXTPickerFactoryDelegate

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldEnterNextStep:(XXTPickerSnippet *)task {
    return YES;
}

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldFinished:(XXTPickerSnippet *)task {
    blockInteractionsWithDelay(self, YES, 0);
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @strongify(self);
        NSError *error = nil;
        id result = [task generateWithError:&error];
        dispatch_async_on_main_queue(^{
            blockInteractions(self, NO);
            if (result) {
                if ([self.pickerCell isKindOfClass:[XUITitleValueCell class]]) {
                    XUITitleValueCell *cell = (XUITitleValueCell *)self.pickerCell;
                    cell.xui_value = result;
                    [self storeCellWhenNeeded:cell];
                    [self storeCellsIfNecessary];
                }
            } else {
                [self presentErrorAlertController:error];
            }
        });
    });
    return YES;
}

#pragma mark - XXTExplorerItemPickerDelegate

- (void)itemPicker:(XXTExplorerItemPicker *)picker didSelectItemAtPath:(NSString *)path {
    XUIFileCell *cell = (XUIFileCell *)self.pickerCell;
    if ([cell isKindOfClass:[XUIFileCell class]]) {
        cell.xui_value = path;
        [self storeCellWhenNeeded:cell];
        [self storeCellsIfNecessary];
        [self.navigationController popToViewController:self animated:YES];
    }
}

#pragma mark - Store

- (void)storeCellWhenNeeded:(XUIBaseCell *)cell {
    if (![self.cellsNeedStore containsObject:cell]) {
        [self.cellsNeedStore addObject:cell];
    }
    [self setNeedsStoreCells];
}

- (void)setNeedsStoreCells {
    if (self.shouldStoreCells == NO) {
        self.shouldStoreCells = YES;
    }
}

- (void)storeCellsIfNecessary {
    if (self.shouldStoreCells) {
        self.shouldStoreCells = NO;
        for (XUIBaseCell *cell in self.cellsNeedStore) {
            [self.cellFactory.adapter saveDefaultsFromCell:cell];
        }
    }
}

#pragma mark - UIControl Actions

- (void)closeButtonItemTapped:(id)sender {
    [self dismissViewController:sender];
}

- (void)dismissViewController:(id)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Keyboard

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardDidAppear:(NSNotification *)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = [self defaultContentInsets];
    contentInsets.bottom = kbSize.height;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillDisappear:(NSNotification *)aNotification
{
    UITableView *tableView = self.tableView;
    UIEdgeInsets contentInsets = [self defaultContentInsets];
    contentInsets.bottom = XXTE_PAD ? 0.0 : self.tabBarController.tabBar.bounds.size.height;
    tableView.contentInset = contentInsets;
    tableView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - Banner

- (UIEdgeInsets)defaultContentInsets {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    return insets;
}

#pragma mark - Notifications

- (void)handleApplicationNotifications:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidEnterBackground])
    {
        if (self.awakeFromOutside) {
            [self dismissViewController:aNotification];
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XUIListViewController dealloc]");
#endif
}

@end
