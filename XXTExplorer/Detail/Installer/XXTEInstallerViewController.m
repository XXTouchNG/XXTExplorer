//
//  XXTEInstallerViewController.m
//  XXTExplorer
//
//  Created by Zheng on 19/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEInstallerViewController.h"
#import "XXTExplorerEntryXPAPackageReader.h"
#import "XXTEXPAPackageExtractor.h"

#import "XXTEInstallerLoadingView.h"

#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"
#import "XXTENotificationCenterDefines.h"

#import "XXTExplorerEntryParser.h"
#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryXPPReader.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreLinkNoIconCell.h"
#import "XXTExplorerDynamicSection.h"
#import <XUI/NSObject+XUIStringValue.h>

#import <PromiseKit/PromiseKit.h>
#import "XXTEObjectViewController.h"
#import "XUIAboutCell.h"

#import "XXTExplorerEntryXPPMeta.h"

@interface XXTEInstallerViewController () <XXTEXPAPackageExtractorDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) XXTEInstallerLoadingView *loadingView;
@property (nonatomic, strong) XXTEXPAPackageExtractor *extractor;
@property (nonatomic, strong) NSArray <XXTExplorerDynamicSection *> *dynamicSections;
@property (nonatomic, strong) UIBarButtonItem *installButtonItem;

@property (nonatomic, strong) NSBundle *entryBundle;

@end

@implementation XXTEInstallerViewController

@synthesize entryPath = _entryPath, awakeFromOutside = _awakeFromOutside;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Installer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"xpa" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryXPAPackageReader class];
}

#pragma mark - Initializers

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        
        XXTEXPAPackageExtractor *extractor = [[XXTEXPAPackageExtractor alloc] initWithPath:path];
        extractor.delegate = self;
        
        _extractor = extractor;
    }
    return self;
}

#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = [self.class viewerName];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.loadingView];
    [self.navigationItem setRightBarButtonItem:self.installButtonItem];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.extractor extractMetaData];
    });
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.extractor.busyOperationProgressFlag = NO;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    NSMutableArray <NSLayoutConstraint *> *constraints = [[NSMutableArray alloc] init];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.loadingView
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.f
                                                         constant:0.f]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.loadingView
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.topLayoutGuide
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.f
                                                         constant:0.f]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.loadingView
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeWidth
                                                       multiplier:1.f
                                                         constant:0.f]];
    [self.view addConstraints:constraints];
}

- (void)reloadStaticTableViewDataWithReader:(XXTExplorerEntryReader *)entryReader {
    
    NSString *entryPath = entryReader.entryPath;
    NSMutableArray <XXTExplorerDynamicSection *> *mutableDynamicSections = [[NSMutableArray alloc] init];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSBundle *entryBundle = [NSBundle bundleWithPath:entryPath];
    entryBundle = (entryBundle != nil) ? entryBundle : mainBundle;
    _entryBundle = entryBundle;
    
    NSDictionary *controlDetail = entryReader.metaDictionary[kXXTEPackageControl];
    
    {
        XUIAboutCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XUIAboutCell class]) owner:nil options:nil] lastObject];
        
        NSString *bundleVersion = entryReader.metaDictionary[kXXTEBundleVersion];
        cell.centeredImage = entryReader.entryIconImage;
        cell.xui_label = [NSString stringWithFormat:@"%@\nv%@", entryReader.entryDisplayName, bundleVersion];
        cell.xui_value = NSLocalizedString(@"The information below is provided by the third party script author.", nil);
        
        XXTExplorerDynamicSection *section1 = [[XXTExplorerDynamicSection alloc] init];
        section1.identifier = nil;
        section1.cells = @[cell];
        section1.cellHeights = @[@(-1)];
        section1.relatedObjects = @[ [NSNull null] ];
        section1.sectionTitle = @"";
        section1.sectionFooter = @"";
        
        if (section1) [mutableDynamicSections addObject:section1];
    }
    
    // Control
    if (controlDetail)
    {
        NSMutableArray <UITableViewCell *> *cells = [[NSMutableArray alloc] init];
        NSMutableArray <NSNumber *> *heights = [[NSMutableArray alloc] init];
        NSMutableArray *objects = [[NSMutableArray alloc] init];
        
        NSArray <Class> *supportedTypes = [NSObject xui_baseTypes];
        NSDictionary *generalDictionary = controlDetail;
        
        for (NSString *generalKey in generalDictionary)
        {
            id generalValue = generalDictionary[generalKey];
            if (!generalValue) continue;
            
            Class valueClass = [generalValue class];
            BOOL supportedValue = NO;
            for (Class supportedType in supportedTypes) {
                if ([valueClass isSubclassOfClass:supportedType]) {
                    supportedValue = YES;
                    break;
                }
            }
            if (supportedValue)
            {
                XXTEMoreTitleValueCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
                NSString *localizedKey = [mainBundle localizedStringForKey:(generalKey) value:nil table:(@"Meta")];
                if (!localizedKey)
                    localizedKey = [entryBundle localizedStringForKey:(generalKey) value:nil table:(@"Meta")];
                cell.titleLabel.text = localizedKey;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.valueLabel.text = [generalValue xui_stringValue];
                
                if (cell) [cells addObject:cell];
                [heights addObject:@(44.f)];
                [objects addObject:[NSNull null]];
            }
            else
            {
                XXTEMoreLinkNoIconCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
                NSString *localizedKey = [mainBundle localizedStringForKey:(generalKey) value:nil table:(@"Meta")];
                if (!localizedKey)
                    localizedKey = [entryBundle localizedStringForKey:(generalKey) value:nil table:(@"Meta")];
                cell.titleLabel.text = localizedKey;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                if (cell) [cells addObject:cell];
                [heights addObject:@(44.f)];
                [objects addObject:generalValue];
            }
            
        }
        
        if (cells.count > 0) {
            XXTExplorerDynamicSection *section2 = [[XXTExplorerDynamicSection alloc] init];
            section2.identifier = kXXTEDynamicSectionIdentifierSectionGeneral;
            section2.cells = [[NSArray alloc] initWithArray:cells];
            section2.cellHeights = [[NSArray alloc] initWithArray:heights];
            section2.relatedObjects = [[NSArray alloc] initWithArray:objects];
            section2.sectionTitle = NSLocalizedString(@"General", nil);
            section2.sectionFooter = @"";
            
            if (section2) [mutableDynamicSections addObject:section2];
        }
        
    }
    
    // Extended
    if (entryReader &&
        entryReader.metaDictionary &&
        entryReader.metaKeys)
    {
        NSMutableArray <UITableViewCell *> *extendedCells = [[NSMutableArray alloc] init];
        NSMutableArray <NSNumber *> *extendedHeights = [[NSMutableArray alloc] init];
        NSMutableArray *extendedObjects = [[NSMutableArray alloc] init];
        
        NSArray <Class> *supportedTypes = [NSObject xui_baseTypes];
        NSDictionary *extendedDictionary = entryReader.metaDictionary;
        NSMutableArray <NSString *> *displayExtendedKeys = [[NSMutableArray alloc] initWithArray:entryReader.metaKeys];
        [displayExtendedKeys removeObject:kXXTEPackageControl];
        
        for (NSString *extendedKey in displayExtendedKeys)
        {
            id extendedValue = extendedDictionary[extendedKey];
            if (!extendedValue) continue;
            
            Class valueClass = [extendedValue class];
            BOOL supportedValue = NO;
            for (Class supportedType in supportedTypes) {
                if ([valueClass isSubclassOfClass:supportedType]) {
                    supportedValue = YES;
                    break;
                }
            }
            if (supportedValue)
            {
                XXTEMoreTitleValueCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
                NSString *localizedKey = [mainBundle localizedStringForKey:(extendedKey) value:nil table:(@"Meta")];
                if (!localizedKey)
                    localizedKey = [entryBundle localizedStringForKey:(extendedKey) value:nil table:(@"Meta")];
                cell.titleLabel.text = localizedKey;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.valueLabel.text = [extendedValue xui_stringValue];
                
                if (cell) [extendedCells addObject:cell];
                [extendedHeights addObject:@(44.f)];
                [extendedObjects addObject:[NSNull null]];
            }
            else
            {
                XXTEMoreLinkNoIconCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
                NSString *localizedKey = [mainBundle localizedStringForKey:(extendedKey) value:nil table:(@"Meta")];
                if (!localizedKey)
                    localizedKey = [entryBundle localizedStringForKey:(extendedKey) value:nil table:(@"Meta")];
                cell.titleLabel.text = localizedKey;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                if (cell) [extendedCells addObject:cell];
                [extendedHeights addObject:@(44.f)];
                [extendedObjects addObject:extendedValue];
            }
            
        }
        
        if (extendedCells.count > 0) {
            XXTExplorerDynamicSection *section3 = [[XXTExplorerDynamicSection alloc] init];
            section3.identifier = kXXTEDynamicSectionIdentifierSectionExtended;
            section3.cells = [[NSArray alloc] initWithArray:extendedCells];
            section3.cellHeights = [[NSArray alloc] initWithArray:extendedHeights];
            section3.relatedObjects = [[NSArray alloc] initWithArray:extendedObjects];
            section3.sectionTitle = NSLocalizedString(@"Extended", nil);
            section3.sectionFooter = @"";
            
            if (section3) [mutableDynamicSections addObject:section3];
        }
        
    }
    
    self.dynamicSections = [[NSArray alloc] initWithArray:mutableDynamicSections];
    
}

#pragma mark - UIView Getters

- (XXTEInstallerLoadingView *)loadingView {
    if (!_loadingView) {
        XXTEInstallerLoadingView *loadingView = [[[UINib nibWithNibName:NSStringFromClass([XXTEInstallerLoadingView class]) bundle:nil] instantiateWithOwner:self options:nil] lastObject];
        loadingView.translatesAutoresizingMaskIntoConstraints = NO;
        _loadingView = loadingView;
    }
    return _loadingView;
}

- (UIBarButtonItem *)installButtonItem {
    if (!_installButtonItem) {
        UIBarButtonItem *installButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Install", nil) style:UIBarButtonItemStyleDone target:self action:@selector(installButtonItemTapped:)];
        installButtonItem.enabled = NO;
        installButtonItem.tintColor = [UIColor whiteColor];
        _installButtonItem = installButtonItem;
    }
    return _installButtonItem;
}

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.tableFooterView = [UIView new];
        tableView.editing = NO;
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        _tableView = tableView;
    }
    return _tableView;
}

#pragma mark - XXTEXPAPackageExtractorDelegate

- (void)packageExtractor:(XXTEXPAPackageExtractor *)extractor didFinishFetchingMetaData:(NSData *)metaData {
    NSError *metaError = nil;
    NSString *metaPath = [[NSString alloc] initWithData:metaData encoding:NSUTF8StringEncoding];
    NSString *parentPath = [metaPath stringByAppendingPathComponent:@"Payload"];
    NSArray<NSString *> *topList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:parentPath error:&metaError];
    if (metaError) {
        [self displayErrorMessageInLoadingView:metaError.localizedDescription];
        return;
    }
    NSString *xppItem = nil;
    for (NSString *topItem in topList) {
        if ([[topItem lowercaseString] hasSuffix:@".xpp"]) {
            xppItem = topItem;
            break;
        }
    }
    if (!xppItem) {
        [self displayErrorMessageInLoadingView:[NSString stringWithFormat:NSLocalizedString(@"Cannot find top-level XPP from \"%@\".", nil), parentPath]];
        return;
    }
    XXTExplorerEntryParser *entryParser = [[XXTExplorerEntryParser alloc] init];
    NSString *xppPath = [parentPath stringByAppendingPathComponent:xppItem];
    NSDictionary *entryDetail = [entryParser entryOfPath:xppPath withError:nil];
    if (![entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle] ||
        ![entryDetail[XXTExplorerViewEntryAttributeEntryReader] isKindOfClass:[XXTExplorerEntryXPPReader class]]) {
        [self displayErrorMessageInLoadingView:[NSString stringWithFormat:NSLocalizedString(@"Invalid XPP Bundle: \"%@\".", nil), xppPath]];
        return;
    }
    {
        XXTExplorerEntryXPPReader *reader = entryDetail[XXTExplorerViewEntryAttributeEntryReader];
        [self.loadingView setHidden:YES];
        [self reloadStaticTableViewDataWithReader:reader];
        [self.tableView reloadData];
        [self.installButtonItem setEnabled:YES];
    }
}

- (void)packageExtractor:(XXTEXPAPackageExtractor *)extractor didFailFetchingMetaDataWithError:(NSError *)error {
    [self displayErrorMessageInLoadingView:error.localizedDescription];
}

- (void)displayErrorMessageInLoadingView:(NSString *)errorMessage {
    self.loadingView.loadingLabel.text = errorMessage;
    [self.loadingView.loadingIndicator stopAnimating];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dynamicSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.dynamicSections[(NSUInteger) section].cells.count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        CGFloat storedHeight = [self.dynamicSections[indexPath.section].cellHeights[indexPath.row] floatValue];
        if (storedHeight < 0) {
            if (@available(iOS 8.0, *)) {
                return UITableViewAutomaticDimension;
            } else {
                UITableViewCell *cell = self.dynamicSections[indexPath.section].cells[indexPath.row];
                [cell setNeedsUpdateConstraints];
                [cell updateConstraintsIfNeeded];
                
                cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
                [cell setNeedsLayout];
                [cell layoutIfNeeded];
                
                CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
                return (height > 0) ? (height + 1.0) : 44.0;
            }
        }
        return storedHeight;
    }
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        NSString *sectionIdentifier = self.dynamicSections[indexPath.section].identifier;
        UITableViewCell *cell = self.dynamicSections[indexPath.section].cells[indexPath.row];
        if ([cell isKindOfClass:[XXTEMoreLinkNoIconCell class]] &&
                 [sectionIdentifier isEqualToString:kXXTEDynamicSectionIdentifierSectionExtended]) {
            id relatedObject = self.dynamicSections[indexPath.section].relatedObjects[indexPath.row];
            XXTEObjectViewController *objectViewController = [[XXTEObjectViewController alloc] initWithRootObject:relatedObject];
            objectViewController.tableViewStyle = UITableViewStylePlain;
            objectViewController.entryBundle = self.entryBundle;
            objectViewController.title = ((XXTEMoreLinkNoIconCell *)cell).titleLabel.text;
            [self.navigationController pushViewController:objectViewController animated:YES];
        }
        else if ([cell isKindOfClass:[XXTEMoreTitleValueCell class]]) {
            NSString *detailText = ((XXTEMoreTitleValueCell *)cell).valueLabel.text;
            if (detailText && detailText.length > 0) {
                blockInteractionsWithDelay(self, YES, 2.0);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    toastMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                    blockInteractions(self, NO);
                });
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.dynamicSections[(NSUInteger) section].sectionTitle;
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.dynamicSections[(NSUInteger) section].sectionFooter;
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        UITableViewCell *cell = self.dynamicSections[(NSUInteger) indexPath.section].cells[(NSUInteger) indexPath.row];
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UIControl Actions

- (void)installButtonItemTapped:(UIBarButtonItem *)sender {
    if (!self.entryBundle) return;
    if (sender == self.installButtonItem) {
        NSURL *url = [self.entryBundle bundleURL];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:url userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeInbox}]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEInstallerViewController dealloc]");
#endif
}

@end
