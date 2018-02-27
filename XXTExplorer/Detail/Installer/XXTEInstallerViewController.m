//
//  XXTEInstallerViewController.m
//  XXTExplorer
//
//  Created by Zheng on 19/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>

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
#import "XXTEMoreLinkCell.h"
#import "XXTExplorerDynamicSection.h"
#import <XUI/NSObject+XUIStringValue.h>

#import <PromiseKit/PromiseKit.h>
#import "XXTEObjectViewController.h"
#import "XUIAboutCell.h"

#import "XXTExplorerEntryXPPMeta.h"
#import <LGAlertView/LGAlertView.h>

#import "XXTEMoreSwitchCell.h"
#import "UIControl+BlockTarget.h"

#import "XXTEPermissionDefines.h"

typedef enum : NSUInteger {
    XXTEInstallerViewControllerReplacementTypeNone = 0,
    XXTEInstallerViewControllerReplacementTypeRename,
    XXTEInstallerViewControllerReplacementTypeOverride,
} XXTEInstallerViewControllerReplacementType;

@interface XXTEInstallerViewController () <XXTEXPAPackageExtractorDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) XXTEInstallerLoadingView *loadingView;
@property (nonatomic, strong) XXTEXPAPackageExtractor *extractor;
@property (nonatomic, strong) NSArray <XXTExplorerDynamicSection *> *dynamicSections;
@property (nonatomic, strong) UIBarButtonItem *installButtonItem;

@property (nonatomic, strong) NSBundle *temporarilyEntryBundle;
@property (nonatomic, assign) BOOL removeAfterInstallation;

@property (nonatomic, strong) NSDictionary *entryDetail;

@end

@implementation XXTEInstallerViewController

@synthesize entryPath = _entryPath;

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
        _removeAfterInstallation = YES;
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
    
    if (self.title.length == 0) {
        self.title = [self.class viewerName];
    }
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.loadingView];
    [self.navigationItem setRightBarButtonItem:self.installButtonItem];
    
    [self.extractor extractMetaData];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
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
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.f
                                                         constant:0.f]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.loadingView
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeWidth
                                                       multiplier:1.f
                                                         constant:0.f]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.loadingView
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:1.f
                                                         constant:XXTEInstallerLoadingViewHeight]];
    [self.view addConstraints:constraints];
}

- (void)reloadStaticTableViewDataWithReader:(XXTExplorerEntryReader *)entryReader {
    
    NSString *entryPath = entryReader.entryPath;
    NSMutableArray <XXTExplorerDynamicSection *> *mutableDynamicSections = [[NSMutableArray alloc] init];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSBundle *entryBundle = [NSBundle bundleWithPath:entryPath];
    entryBundle = (entryBundle != nil) ? entryBundle : mainBundle;
    _temporarilyEntryBundle = entryBundle;
    
    NSDictionary *controlDetail = entryReader.metaDictionary[kXXTEPackageControl];
    
    {
        XUIAboutCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XUIAboutCell class]) owner:nil options:nil] lastObject];
        
        NSString *bundleVersion = entryReader.metaDictionary[kXXTEBundleVersion];
        cell.centeredImage = entryReader.entryIconImage;
        cell.xui_label = [NSString stringWithFormat:@"%@\nv%@", entryReader.entryDisplayName, bundleVersion];
        cell.xui_value = NSLocalizedString(@"The information below is provided by the third party script author.", nil);
        
        XXTExplorerDynamicSection *section = [[XXTExplorerDynamicSection alloc] init];
        section.identifier = @"";
        section.cells = @[cell];
        section.cellHeights = @[@(-1)];
        section.relatedObjects = @[ [NSNull null] ];
        section.sectionTitle = @"";
        section.sectionFooter = @"";
        
        if (section) [mutableDynamicSections addObject:section];
    }
    
    // Install
    {
        XXTEMoreSwitchCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
        cell.titleLabel.text = NSLocalizedString(@"Remove after installation", nil);
        cell.optionSwitch.on = self.removeAfterInstallation;
        {
            @weakify(self);
            [cell.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
                @strongify(self);
                self.removeAfterInstallation = ((UISwitch *)sender).on;
            }];
        }
        
        XXTExplorerDynamicSection *section = [[XXTExplorerDynamicSection alloc] init];
        section.identifier = @"";
        section.cells = @[cell];
        section.cellHeights = @[@(44.0)];
        section.relatedObjects = @[ [NSNull null] ];
        section.sectionTitle = @"";
        section.sectionFooter = @"";
        
        if (section) [mutableDynamicSections addObject:section];
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
                XXTEMoreLinkCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
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
            XXTExplorerDynamicSection *section = [[XXTExplorerDynamicSection alloc] init];
            section.identifier = kXXTEDynamicSectionIdentifierSectionGeneral;
            section.cells = [[NSArray alloc] initWithArray:cells];
            section.cellHeights = [[NSArray alloc] initWithArray:heights];
            section.relatedObjects = [[NSArray alloc] initWithArray:objects];
            section.sectionTitle = NSLocalizedString(@"General", nil);
            section.sectionFooter = @"";
            
            if (section) [mutableDynamicSections addObject:section];
        }
        
    }
    
    // Extended
    if (entryReader &&
        entryReader.metaDictionary &&
        entryReader.metaKeys)
    {
        NSMutableArray <UITableViewCell *> *cells = [[NSMutableArray alloc] init];
        NSMutableArray <NSNumber *> *heights = [[NSMutableArray alloc] init];
        NSMutableArray *objects = [[NSMutableArray alloc] init];
        
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
                
                if (cell) [cells addObject:cell];
                [heights addObject:@(44.f)];
                [objects addObject:[NSNull null]];
            }
            else
            {
                XXTEMoreLinkCell *cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
                NSString *localizedKey = [mainBundle localizedStringForKey:(extendedKey) value:nil table:(@"Meta")];
                if (!localizedKey)
                    localizedKey = [entryBundle localizedStringForKey:(extendedKey) value:nil table:(@"Meta")];
                cell.titleLabel.text = localizedKey;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
                if (cell) [cells addObject:cell];
                [heights addObject:@(44.f)];
                [objects addObject:extendedValue];
            }
            
        }
        
        if (cells.count > 0) {
            XXTExplorerDynamicSection *section = [[XXTExplorerDynamicSection alloc] init];
            section.identifier = kXXTEDynamicSectionIdentifierSectionExtended;
            section.cells = [[NSArray alloc] initWithArray:cells];
            section.cellHeights = [[NSArray alloc] initWithArray:heights];
            section.relatedObjects = [[NSArray alloc] initWithArray:objects];
            section.sectionTitle = NSLocalizedString(@"Extended", nil);
            section.sectionFooter = @"";
            
            if (section) [mutableDynamicSections addObject:section];
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
        tableView.editing = NO;
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        tableView.tableFooterView = [UIView new];
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
    self.entryDetail = entryDetail;
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
        if ([cell isKindOfClass:[XXTEMoreLinkCell class]] &&
                 [sectionIdentifier isEqualToString:kXXTEDynamicSectionIdentifierSectionExtended]) {
            id relatedObject = self.dynamicSections[indexPath.section].relatedObjects[indexPath.row];
            XXTEObjectViewController *objectViewController = [[XXTEObjectViewController alloc] initWithRootObject:relatedObject];
            objectViewController.title = ((XXTEMoreLinkCell *)cell).titleLabel.text;
            objectViewController.entryBundle = self.temporarilyEntryBundle;
            objectViewController.tableViewStyle = UITableViewStylePlain;
            objectViewController.containerDisplayMode = XXTEObjectContainerDisplayModeDescription;
            [self.navigationController pushViewController:objectViewController animated:YES];
        }
        else if ([cell isKindOfClass:[XXTEMoreTitleValueCell class]]) {
            NSString *detailText = ((XXTEMoreTitleValueCell *)cell).valueLabel.text;
            if (detailText && detailText.length > 0) {
                UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    toastMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                    blockInteractions(blockVC, NO);
                });
            }
        }
    }
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
    if (!self.temporarilyEntryBundle) return;
    if (!self.entryDetail) return;
    XXTExplorerEntryReader *entryReader = self.entryDetail[XXTExplorerViewEntryAttributeEntryReader];
    if (!entryReader) return;
    NSString *unsupportedReason = [entryReader localizedUnsupportedReason];
    if (unsupportedReason != nil) {
        LGAlertView *unsupportedAlert = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:unsupportedReason style:LGAlertViewStyleAlert buttonTitles:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) destructiveButtonTitle:nil actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
            [alertView dismissAnimated];
        } destructiveHandler:nil];
        [unsupportedAlert showAnimated];
        return;
    }
    if (sender == self.installButtonItem) {
        NSString *bundleTestName = [[self.temporarilyEntryBundle bundlePath] lastPathComponent];
        NSString *bundleTestPath = [[self.entryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:bundleTestName];
        struct stat testStat;
        if (0 == lstat(bundleTestPath.UTF8String, &testStat)) {
            LGAlertView *alertView = [LGAlertView alertViewWithTitle:NSLocalizedString(@"Overwrite Confirm", nil)
                                                             message:[NSString stringWithFormat:NSLocalizedString(@"File \"%@\" exists, overwrite or rename it?", nil), bundleTestName]
                                                               style:LGAlertViewStyleActionSheet
                                                        buttonTitles:@[ NSLocalizedString(@"Rename", nil) ]
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              destructiveButtonTitle:NSLocalizedString(@"Overwrite", nil)
                                                       actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
                                                           [alertView dismissAnimated];
                                                           if (index == 0)
                                                           {
                                                               [self performMoveImmediatelyWithReplacementType:XXTEInstallerViewControllerReplacementTypeRename];
                                                           }
                                                       }
                                                       cancelHandler:^(LGAlertView * _Nonnull alertView) {
                                                           [alertView dismissAnimated];
                                                       }
                                                  destructiveHandler:^(LGAlertView * _Nonnull alertView) {
                                                      [alertView dismissAnimated];
                                                      [self performMoveImmediatelyWithReplacementType:XXTEInstallerViewControllerReplacementTypeOverride];
                                                  }];
            [alertView showAnimated];
        } else {
            [self performMoveImmediatelyWithReplacementType:XXTEInstallerViewControllerReplacementTypeNone];
        }
    }
}

- (void)performMoveImmediatelyWithReplacementType:(XXTEInstallerViewControllerReplacementType)type {
    NSString *bundlePath = [self.temporarilyEntryBundle bundlePath];
    NSString *bundleTestName = [bundlePath lastPathComponent];
    NSString *bundleTestPath = [[self.entryPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:bundleTestName];
    
    if (type == XXTEInstallerViewControllerReplacementTypeOverride) {
        promiseFixPermission(bundleTestPath, YES); // fix permission
        NSError *removeError = nil;
        BOOL result = [[NSFileManager defaultManager] removeItemAtPath:bundleTestPath error:&removeError];
        if (!result) {
            toastMessageWithDelay(self, removeError.localizedDescription, 5.0);
            return;
        }
    }
    
    {
        NSURL *bundleURL = [self.temporarilyEntryBundle bundleURL];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:bundleURL userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeInbox}]];
    }
    
    [self performCleanAfterInstallation];
    self.installButtonItem.enabled = NO;
    if (XXTE_COLLAPSED) {
        if (self == [self.navigationController.viewControllers firstObject]) {
            [self.navigationController restoreWorkspaceViewController];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

- (void)performCleanAfterInstallation {
    if (self.removeAfterInstallation) {
        NSError *cleanError = nil;
        BOOL cleanResult = [[NSFileManager defaultManager] removeItemAtPath:self.entryPath error:&cleanError];
        if (!cleanResult && cleanError) {
            toastMessageWithDelay(self, [NSString stringWithFormat:NSLocalizedString(@"Failed to clean: %@", nil), cleanError.localizedDescription], 5.0);
        }
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEInstallerViewController dealloc]");
#endif
}

@synthesize awakeFromOutside;

@end
