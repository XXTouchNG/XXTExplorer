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
#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"

@interface XUIListViewController () <XUICellFactoryDelegate>

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong, readonly) XUICellFactory *parser;
@property (nonatomic, strong) XUIListHeaderView *headerView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation XUIListViewController

@synthesize entryPath = _entryPath;

+ (XXTExplorerEntryParser *)entryParser {
    static XXTExplorerEntryParser *entryParser = nil;
    if (!entryParser) {
        entryParser = [[XXTExplorerEntryParser alloc] init];
    }
    return entryParser;
}

+ (XXTExplorerEntryService *)entryService {
    static XXTExplorerEntryService *entryService = nil;
    if (!entryService) {
        entryService = [XXTExplorerEntryService sharedInstance];
    }
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
        
        XUICellFactory *parser = [[XUICellFactory alloc] initWithRootEntry:rootEntry];
        if (!parser) {
            return;
        }
        parser.delegate = self;
        parser.bundle = self.bundle;
        _parser = parser;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.entryPath lastPathComponent];
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
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (XXTE_COLLAPSED) {
        self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
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
        return [self.parser.otherCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row].xui_height floatValue];
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
    return self.parser.otherCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        XUIBaseCell *cell = (XUIBaseCell *)[tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[XUILinkCell class]]) {
            [self tableView:tableView performLinkCell:cell];
        }
    }
}

- (void)tableView:(UITableView *)tableView performLinkCell:(UITableViewCell *)cell {
    XUILinkCell *linkCell = (XUILinkCell *)cell;
    NSString *detailPathName = linkCell.xui_path;
    NSString *detailPathNameNoExt = [detailPathName stringByDeletingPathExtension];
    NSString *detailPathNameExt = [detailPathName pathExtension];
    NSString *detailPath = [self.bundle pathForResource:detailPathNameNoExt ofType:detailPathNameExt];
    UIViewController *detailController = nil;
    if ([[self.class suggestedExtensions] containsObject:detailPathNameExt]) {
        if (!detailPath)
            detailPath = [self.bundle pathForResource:detailPathNameNoExt ofType:@"plist"];
        if (!detailPath)
            detailPath = [self.bundle pathForResource:detailPathNameNoExt ofType:@"json"];
        if (!detailPath)
            detailPath = [self.bundle pathForResource:detailPathNameNoExt ofType:@"xui"];
        detailController = [[[self class] alloc] initWithPath:detailPath withBundlePath:[self.bundle bundlePath]];
    } else {
        NSError *entryError = nil;
        NSDictionary *entryAttributes = [self.class.entryParser entryOfPath:detailPath withError:&entryError];
        if (!entryError && [self.class.entryService hasViewerForEntry:entryAttributes]) {
            UIViewController <XXTEViewer> *viewer = [self.class.entryService viewerForEntry:entryAttributes];
            detailController = viewer;
        }
    }
    if (detailController) {
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"XUI Error", nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@\n[Parse Error]\n%@", nil), entryName, error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    });
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XUIListViewController dealloc]");
#endif
}

@end
