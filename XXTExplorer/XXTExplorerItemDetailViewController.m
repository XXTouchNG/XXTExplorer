//
//  XXTExplorerItemDetailViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <pwd.h>
#import <grp.h>
#import <sys/stat.h>
#import "XXTExplorerItemDetailViewController.h"
#import "XXTExplorerItemNameCell.h"
#import "XXTEMoreTitleDescriptionValueCell.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEViewShaker.h"
#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreAddressCell.h"
#import "XXTEMoreLinkNoIconCell.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <PromiseKit/PromiseKit.h>
#import "NSFileManager+DeepSize.h"
#import "XXTExplorerEntryParser.h"
#import "XXTENotificationCenterDefines.h"
#import "XXTExplorerEntryReader.h"

typedef enum : NSUInteger {
    kXXTExplorerItemDetailViewSectionIndexName = 0,
    kXXTExplorerItemDetailViewSectionIndexWhere,
    kXXTExplorerItemDetailViewSectionIndexExtended,
    kXXTExplorerItemDetailViewSectionIndexGeneral,
    kXXTExplorerItemDetailViewSectionIndexOwner,
    kXXTExplorerItemDetailViewSectionIndexPermission,
    kXXTExplorerItemDetailViewSectionIndexOpenWith,
    kXXTExplorerItemDetailViewSectionIndexMax
} kXXTExplorerItemDetailViewSectionIndex;

static int sizingCancelFlag = 0;

@interface XXTExplorerItemDetailViewController () <UITextFieldDelegate>

@property (nonatomic, strong) NSDictionary *entry;

@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;
@property (nonatomic, strong) XXTEViewShaker *itemNameShaker;

@end

@implementation XXTExplorerItemDetailViewController {
    BOOL isFirstTimeLoaded;
    NSArray <NSMutableArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
}

+ (NSDateFormatter *)itemDateFormatter {
    static NSDateFormatter *itemDateFormatter = nil;
    if (!itemDateFormatter) {
        itemDateFormatter = ({
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
            [dateFormatter setDateStyle:NSDateFormatterFullStyle];
            dateFormatter;
        });
    }
    return itemDateFormatter;
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Setup

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype) initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithEntry:(NSDictionary *)entry {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _entry = entry;
        [self setup];
    }
    return self;
}

- (void)setup {
    sizingCancelFlag = 0;
}

#pragma mark - View Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = self.entry[XXTExplorerViewEntryAttributeName];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    self.navigationItem.rightBarButtonItem = self.doneButtonItem;
    
    [self reloadStaticTableViewData];
//    [self reloadDynamicTableViewData];
    [self performSelector:@selector(reloadDynamicTableViewData) withObject:nil afterDelay:.2f];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    if (![self.nameField isFirstResponder]) {
//        [self.nameField becomeFirstResponder];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeWithNotificaton:) name:UITextFieldTextDidChangeNotification object:self.nameField];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ NSLocalizedString(@"Filename", nil),
                             NSLocalizedString(@"Where", nil),
                             NSLocalizedString(@"Extended", nil),
                             NSLocalizedString(@"General", nil),
                             NSLocalizedString(@"Owner", nil),
                             NSLocalizedString(@"Permission", nil),
                             @"",
                             ];
    staticSectionFooters = @[ NSLocalizedString(@"Tap to edit filename.", nil), @"", @"", @"", @"", @"", NSLocalizedString(@"Use this viewer to open all documents like this one.", nil) ];
    
    NSDictionary *entry = self.entry;
    id <XXTExplorerEntryReader> entryReader = entry[XXTExplorerViewEntryAttributeEntryReader];
    NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
    NSBundle *entryBundle = nil;
    if ([entry[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle])
    {
        entryBundle = [NSBundle bundleWithPath:entryPath];
    }
    NSBundle *useBundle = entryBundle ? entryBundle : [NSBundle mainBundle];
    NSFileManager *detailManager = [[NSFileManager alloc] init];
    
    // Name
    
    XXTExplorerItemNameCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTExplorerItemNameCell class]) owner:nil options:nil] lastObject];
    cell1.nameField.delegate = self;
    cell1.nameField.text = entry[XXTExplorerViewEntryAttributeName];
    self.nameField = cell1.nameField;
    self.itemNameShaker = [[XXTEViewShaker alloc] initWithView:self.nameField];
    
    // Where
    
    XXTEMoreAddressCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell2.addressLabel.text = entry[XXTExplorerViewEntryAttributePath];
    
    // Extended
    NSMutableArray <UITableViewCell *> *extendedCells = [[NSMutableArray alloc] init];
    if (entryReader && entryReader.metaDictionary && entryReader.displayMetaKeys) {
        NSDictionary *extendedDictionary = entryReader.metaDictionary;
        NSArray <NSString *> *displayExtendedKeys = entryReader.displayMetaKeys;
        for (NSString *extendedKey in displayExtendedKeys) {
            id extendedValue = extendedDictionary[extendedKey];
            if ([extendedValue isKindOfClass:[NSString class]]) {
                XXTEMoreTitleValueCell *extendedCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
                extendedCell.titleLabel.text = [useBundle localizedStringForKey:(extendedKey) value:@"" table:(@"Meta")];
                extendedCell.valueLabel.text = extendedValue;
                [extendedCells addObject:extendedCell];
            }
            if ([extendedValue isKindOfClass:[NSNumber class]]) {
                XXTEMoreTitleValueCell *extendedCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
                extendedCell.titleLabel.text = [useBundle localizedStringForKey:(extendedKey) value:@"" table:(@"Meta")];
                extendedCell.valueLabel.text = [extendedValue stringValue];
                [extendedCells addObject:extendedCell];
            }
            else if ([extendedValue isKindOfClass:[NSDictionary class]] ||
                     [extendedValue isKindOfClass:[NSArray class]]) {
                XXTEMoreLinkNoIconCell *extendedCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
                extendedCell.titleLabel.text = [useBundle localizedStringForKey:(extendedKey) value:@"" table:(@"Meta")];
                [extendedCells addObject:extendedCell];
            }
        }
    }
    
    // General
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Kind", nil);
    cell3.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    NSString *entryExtensionDescription = entry[XXTExplorerViewEntryAttributeExtensionDescription];
    if (entryReader && entryReader.entryExtensionDescription) {
        entryExtensionDescription = entryReader.entryExtensionDescription;
    }
    if ([entry[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeTypeRegular] && [detailManager isReadableFileAtPath:entry[XXTExplorerViewEntryAttributePath]]) {
        NSString *mimeString = nil;
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)entry[XXTExplorerViewEntryAttributeExtension], NULL);
        CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
        CFRelease(UTI);
        if (MIMEType == NULL) {
            mimeString = @"application/octet-stream";
        } else {
            mimeString = (__bridge NSString *)(MIMEType);
            CFRelease(MIMEType);
        }
        cell3.valueLabel.text = [NSString stringWithFormat:@"%@\n(%@)", NSLocalizedString(entryExtensionDescription, nil), mimeString];
    } else {
        cell3.valueLabel.text = NSLocalizedString(entryExtensionDescription, nil);
    }
    
    XXTEMoreTitleValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Size", nil);
    cell4.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    if (![entry[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory]) {
        cell4.valueLabel.text = [self formattedSizeLabelText:entry[XXTExplorerViewEntryAttributeSize]];
    } else {
        cell4.valueLabel.text = NSLocalizedString(@"Calculating...\n", nil);
    }
    
    XXTEMoreTitleValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"Created", nil);
    cell5.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell5.valueLabel.text = [self.class.itemDateFormatter stringFromDate:entry[XXTExplorerViewEntryAttributeCreationDate]];
    
    XXTEMoreTitleValueCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Modified", nil);
    cell6.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell6.valueLabel.text = [self.class.itemDateFormatter stringFromDate:entry[XXTExplorerViewEntryAttributeModificationDate]];
    
    // Owner
    
    XXTEMoreTitleValueCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Owner", nil);
    cell7.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    XXTEMoreTitleValueCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"Group", nil);
    cell8.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    // Perimssion
    
    XXTEMoreTitleValueCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"Owner", nil);
    cell9.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    XXTEMoreTitleValueCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell10.titleLabel.text = NSLocalizedString(@"Group", nil);
    cell10.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    XXTEMoreTitleValueCell *cell11 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell11.titleLabel.text = NSLocalizedString(@"Everyone", nil);
    cell11.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    XXTEMoreLinkNoIconCell *cell12 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell12.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell12.titleLabel.text = NSLocalizedString(@"Change Permission", nil);
    
    struct stat entryInfo;
    if (lstat([entry[XXTExplorerViewEntryAttributePath] UTF8String], &entryInfo) == 0) {
        struct passwd *pwInfo = getpwuid(entryInfo.st_uid);
        struct group *grInfo = getgrgid(entryInfo.st_gid);
        if (pwInfo != NULL && grInfo != NULL) {
            cell7.valueLabel.text = [[NSString alloc] initWithUTF8String:pwInfo->pw_name];
            cell8.valueLabel.text = [[NSString alloc] initWithUTF8String:grInfo->gr_name];
        }
        NSString *userReadFlag = (entryInfo.st_mode & S_IRUSR) ? @"r" : @"-";
        NSString *userWriteFlag = (entryInfo.st_mode & S_IWUSR) ? @"w" : @"-";
        NSString *userExecuteFlag = (entryInfo.st_mode & S_IXUSR) ? @"x" : @"-";
        cell9.valueLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:17.f];
        cell9.valueLabel.text = [NSString stringWithFormat:@"%@%@%@", userReadFlag, userWriteFlag, userExecuteFlag];
        NSString *groupReadFlag = (entryInfo.st_mode & S_IRGRP) ? @"r" : @"-";
        NSString *groupWriteFlag = (entryInfo.st_mode & S_IWGRP) ? @"w" : @"-";
        NSString *groupExecuteFlag = (entryInfo.st_mode & S_IXGRP) ? @"x" : @"-";
        cell10.valueLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:17.f];
        cell10.valueLabel.text = [NSString stringWithFormat:@"%@%@%@", groupReadFlag, groupWriteFlag, groupExecuteFlag];
        NSString *otherReadFlag = (entryInfo.st_mode & S_IROTH) ? @"r" : @"-";
        NSString *otherWriteFlag = (entryInfo.st_mode & S_IWOTH) ? @"w" : @"-";
        NSString *otherExecuteFlag = (entryInfo.st_mode & S_IXOTH) ? @"x" : @"-";
        cell11.valueLabel.font = [UIFont fontWithName:@"CourierNewPSMT" size:17.f];
        cell11.valueLabel.text = [NSString stringWithFormat:@"%@%@%@", otherReadFlag, otherWriteFlag, otherExecuteFlag];
    }
    
    // Open with
    
    XXTEMoreTitleValueCell *cell13 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell13.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell13.titleLabel.text = NSLocalizedString(@"Open with...", nil);
    cell13.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    NSString *enteyViewerDescription = entry[XXTExplorerViewEntryAttributeViewerDescription];
    if (entryReader.entryViewerDescription) {
        enteyViewerDescription = entryReader.entryViewerDescription;
    }
    cell13.valueLabel.text = NSLocalizedString(enteyViewerDescription, nil);
    
    staticCells = @[
                    @[ cell1 ],
                    @[ cell2 ],
                    extendedCells,
                    @[ cell3, cell4, cell5, cell6 ],
                    @[ cell7, cell8 ],
                    @[ cell9, cell10, cell11, cell12 ],
                    @[ cell13 ]
                    ];
}

- (void)reloadDynamicTableViewData {
    NSDictionary *entry = self.entry;
    NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
    if ([entry[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory]) {
        XXTEMoreTitleValueCell *sizeCell = ((XXTEMoreTitleValueCell *)staticCells[kXXTExplorerItemDetailViewSectionIndexGeneral][1]);
//        sizeCell.valueLabel.text = NSLocalizedString(@"Calculating...", nil);
        [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
            NSError *sizingError = nil;
            NSFileManager *sizingManager = [[NSFileManager alloc] init];
            NSNumber *itemSize = [sizingManager sizeOfDirectoryAtPath:entryPath error:&sizingError cancelFlag:&sizingCancelFlag];
            if (sizingError) {
                reject(sizingError);
            } else {
                fulfill(itemSize);
            }
        }].then(^(NSNumber *itemSize) {
            sizeCell.valueLabel.text = [self formattedSizeLabelText:itemSize];
        }).catch(^(NSError *systemError) {
            
        }).finally(^() {
            [self.tableView reloadData];
        });
    }
}

- (NSString *)formattedSizeLabelText:(NSNumber *)size {
    NSInteger byteCount = [size integerValue];
    NSString *readableSize = [NSByteCountFormatter stringFromByteCount:byteCount countStyle:NSByteCountFormatterCountStyleFile];
    NSByteCountFormatter *countFormatter = [[NSByteCountFormatter alloc] init];
    countFormatter.allowedUnits = NSByteCountFormatterUseBytes;
    NSString *readableSizeInBytes = [countFormatter stringFromByteCount:byteCount];
    return [NSString stringWithFormat:NSLocalizedString(@"%@\n(%@ on disk)", nil), readableSizeInBytes, readableSize];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)closeButtonItem {
    if (!_closeButtonItem) {
        UIBarButtonItem *closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissViewController:)];
        closeButtonItem.tintColor = [UIColor whiteColor];
        _closeButtonItem = closeButtonItem;
    }
    return _closeButtonItem;
}

- (UIBarButtonItem *)doneButtonItem {
    if (!_doneButtonItem) {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(submitViewController:)];
        doneButtonItem.tintColor = [UIColor whiteColor];
        doneButtonItem.enabled = NO;
        _doneButtonItem = doneButtonItem;
    }
    return _doneButtonItem;
}

#pragma mark - UIControl Actions

- (void)dismissViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    sizingCancelFlag = 1;
    if (XXTE_PAD) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)submitViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    NSFileManager *renameManager = [[NSFileManager alloc] init];
    NSDictionary *entry = self.entry;
    NSString *entryPath = entry[XXTExplorerViewEntryAttributePath];
    NSString *entryParentPath = [entryPath stringByDeletingLastPathComponent];
    if (entryParentPath.length == 0) {
        return;
    }
    BOOL isDirectory = NO;
    BOOL parentExists = [renameManager fileExistsAtPath:entryParentPath isDirectory:&isDirectory];
    if (!parentExists || !isDirectory) {
        return;
    }
    NSString *itemName = self.nameField.text;
    if (itemName.length == 0 || [itemName containsString:@"/"] || [itemName containsString:@"\0"]) {
        [self.itemNameShaker shake];
        return;
    }
    struct stat itemStat;
    NSString *itemPath = [entryParentPath stringByAppendingPathComponent:itemName];
    if (/* [renameManager fileExistsAtPath:itemPath] */ 0 == lstat([itemPath UTF8String], &itemStat)) {
        showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" already exists.", nil), itemName]);
        [self.itemNameShaker shake];
        return;
    }
    blockUserInteractions(self, YES);
    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        NSError *renameError = nil;
        BOOL renameResult = [renameManager moveItemAtPath:entryPath toPath:itemPath error:&renameError];
        if (!renameResult) {
            if (renameError) {
                reject(renameError);
            }
        } else {
            fulfill(@(renameResult));
        }
    }].then(^(id renameResult) {
        
    }).catch(^(NSError *systemError) {
        showUserMessage(self, [systemError localizedDescription]);
    }).finally(^() {
        blockUserInteractions(self, NO);
        sizingCancelFlag = 1;
        if (XXTE_PAD) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
        }
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    });
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTExplorerItemDetailViewSectionIndexMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticCells[(NSUInteger) section].count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerItemDetailViewSectionIndexName) {
            if (indexPath.row == 0) {
                return 52.f;
            }
        }
        return UITableViewAutomaticDimension;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerItemDetailViewSectionIndexWhere) {
            NSString *detailText = ((XXTEMoreAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self, YES);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    [[UIPasteboard generalPasteboard] setString:detailText];
                    fulfill(nil);
                }].finally(^() {
                    showUserMessage(self, NSLocalizedString(@"Path has been copied to the pasteboard.", nil));
                    blockUserInteractions(self, NO);
                });
            }
        }
        else if (indexPath.section == kXXTExplorerItemDetailViewSectionIndexGeneral || indexPath.section == kXXTExplorerItemDetailViewSectionIndexExtended) {
            UITableViewCell *cell = staticCells[indexPath.section][indexPath.row];
            if ([cell isKindOfClass:[XXTEMoreTitleValueCell class]]) {
                NSString *detailText = ((XXTEMoreTitleValueCell *)cell).valueLabel.text;
                if (detailText && detailText.length > 0) {
                    blockUserInteractions(self, YES);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    }].finally(^() {
                        showUserMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                        blockUserInteractions(self, NO);
                    });
                }
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionTitles[(NSUInteger) section];
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticSectionFooters[(NSUInteger) section];
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        UITableViewCell *cell = staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.nameField) {
        if ([string containsString:@"/"] || [string containsString:@"\0"]) {
            [self.itemNameShaker shake];
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameField) {
        if ([textField isFirstResponder]) {
            [textField resignFirstResponder];
        }
        return YES;
    }
    return NO;
}

- (void)textFieldDidChangeWithNotificaton:(NSNotification *)aNotification {
    UITextField *textField = (UITextField *)aNotification.object;
    if (textField.text.length > 0) {
        if ([textField.text isEqualToString:self.entry[XXTExplorerViewEntryAttributeName]]) {
            self.doneButtonItem.enabled = NO;
        } else {
            self.doneButtonItem.enabled = YES;
        }
    } else {
        self.doneButtonItem.enabled = NO;
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTExplorerItemDetailViewController dealloc]");
#endif
}

@end
