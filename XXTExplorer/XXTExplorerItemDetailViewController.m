//
//  XXTExplorerItemDetailViewController.m
//  XXTExplorer
//
//  Created by Zheng on 10/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#include <pwd.h>
#include <grp.h>
#include <sys/stat.h>
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

typedef enum : NSUInteger {
    kXXTExplorerItemDetailViewSectionIndexName = 0,
    kXXTExplorerItemDetailViewSectionIndexWhere,
    kXXTExplorerItemDetailViewSectionIndexGeneral,
    kXXTExplorerItemDetailViewSectionIndexOwner,
    kXXTExplorerItemDetailViewSectionIndexPermission,
    kXXTExplorerItemDetailViewSectionIndexOpenWith,
    kXXTExplorerItemDetailViewSectionIndexExtended,
    kXXTExplorerItemDetailViewSectionIndexMax
} kXXTExplorerItemDetailViewSectionIndex;

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
    
}

#pragma mark - View Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = self.entry[XXTExplorerViewEntryAttributeName];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    self.navigationItem.rightBarButtonItem = self.doneButtonItem;
    
    [self reloadStaticTableViewData];
    [self reloadDynamicTableViewData];
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
                             NSLocalizedString(@"General", nil),
                             NSLocalizedString(@"Owner", nil),
                             NSLocalizedString(@"Permission", nil),
                             @"",
                             NSLocalizedString(@"Extended", nil),
                             ];
    staticSectionFooters = @[ NSLocalizedString(@"Tap to edit filename.", nil), @"", @"", @"", @"", NSLocalizedString(@"Use this viewer to open all documents like this one.", nil), @"" ];
    
    NSFileManager *detailManager = [[NSFileManager alloc] init];
    
    // Name
    
    XXTExplorerItemNameCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTExplorerItemNameCell class]) owner:nil options:nil] lastObject];
    cell1.nameField.delegate = self;
    cell1.nameField.text = self.entry[XXTExplorerViewEntryAttributeName];
    self.nameField = cell1.nameField;
    self.itemNameShaker = [[XXTEViewShaker alloc] initWithView:self.nameField];
    
    NSDictionary *entry = self.entry;
    
    // Where
    
    XXTEMoreAddressCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell2.addressLabel.text = entry[XXTExplorerViewEntryAttributePath];
    
    // General
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Kind", nil);
    
    if ([detailManager isReadableFileAtPath:entry[XXTExplorerViewEntryAttributePath]]) {
        NSString *mimeString = nil;
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)entry[XXTExplorerViewEntryAttributeExtension], NULL);
        CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
        CFRelease(UTI);
        if (!MIMEType) {
            mimeString = @"application/octet-stream";
        } else {
            mimeString = (__bridge NSString *)(MIMEType);
        }
        CFRelease(MIMEType);
        cell3.valueLabel.text = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(entry[XXTExplorerViewEntryAttributeKind], nil), mimeString];
    } else {
        cell3.valueLabel.text = NSLocalizedString(entry[XXTExplorerViewEntryAttributeKind], nil);
    }
    
    XXTEMoreTitleValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Size", nil);
    
    NSInteger byteCount = [entry[XXTExplorerViewEntryAttributeSize] integerValue];
    NSString *readableSize = [NSByteCountFormatter stringFromByteCount:byteCount countStyle:NSByteCountFormatterCountStyleFile];
    NSByteCountFormatter *countFormatter = [[NSByteCountFormatter alloc] init];
    countFormatter.allowedUnits = NSByteCountFormatterUseBytes;
    NSString *readableSizeInBytes = [countFormatter stringFromByteCount:byteCount];
    cell4.valueLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ (%@ on disk)", nil), readableSizeInBytes, readableSize];
    
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
    
    XXTEMoreTitleValueCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"Group", nil);
    
    // Perimssion
    
    XXTEMoreTitleValueCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"Owner", nil);
    
    XXTEMoreTitleValueCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell10.titleLabel.text = NSLocalizedString(@"Group", nil);
    
    XXTEMoreTitleValueCell *cell11 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell11.titleLabel.text = NSLocalizedString(@"Everyone", nil);
    
    XXTEMoreLinkNoIconCell *cell12 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkNoIconCell class]) owner:nil options:nil] lastObject];
    cell12.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell12.titleLabel.text = NSLocalizedString(@"Change Permission", nil);
    
    struct stat entryInfo;
    if (stat([entry[XXTExplorerViewEntryAttributePath] UTF8String], &entryInfo) == 0) {
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
    cell13.valueLabel.text = NSLocalizedString(entry[XXTExplorerViewEntryAttributeViewer], nil);
    
    staticCells = @[
                    @[ cell1 ],
                    @[ cell2 ],
                    @[ cell3, cell4, cell5, cell6 ],
                    @[ cell7, cell8 ],
                    @[ cell9, cell10, cell11, cell12 ],
                    @[ cell13 ],
                    @[  ]
                    ];
}

- (void)reloadDynamicTableViewData {
    // TODO: Load Directory Size
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)submitViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    
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
                [PMKPromise promiseWithValue:@YES].then(^() {
                    [[UIPasteboard generalPasteboard] setString:detailText];
                }).finally(^() {
                    showUserMessage(self.navigationController.view, NSLocalizedString(@"Path has been copied to the pasteboard.", nil));
                    blockUserInteractions(self, NO);
                });
            }
        }
        else if (indexPath.section == kXXTExplorerItemDetailViewSectionIndexGeneral) {
            NSString *detailText = ((XXTEMoreTitleValueCell *)staticCells[indexPath.section][indexPath.row]).valueLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self, YES);
                [PMKPromise promiseWithValue:@YES].then(^() {
                    [[UIPasteboard generalPasteboard] setString:detailText];
                }).finally(^() {
                    showUserMessage(self.navigationController.view, NSLocalizedString(@"Copied to the pasteboard.", nil));
                    blockUserInteractions(self, NO);
                });
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
