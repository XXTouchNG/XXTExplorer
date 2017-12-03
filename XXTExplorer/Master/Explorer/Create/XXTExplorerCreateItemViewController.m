//
//  XXTExplorerCreateItemViewController.m
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import "XXTExplorerCreateItemViewController.h"
#import "XXTExplorerItemNameCell.h"
#import "XXTEMoreTitleDescriptionCell.h"
#import "XXTEUserInterfaceDefines.h"
#import "XUIViewShaker.h"
#import "XXTEAppDefines.h"
#import "XXTEMoreAddressCell.h"
#import <PromiseKit/PromiseKit.h>
#import "XXTENotificationCenterDefines.h"

#import "XXTEMoreSwitchCell.h"
#import "UIControl+BlockTarget.h"

#ifndef APPSTORE
    typedef enum : NSUInteger {
        kXXTExplorerCreateItemViewSectionIndexName = 0,
        kXXTExplorerCreateItemViewSectionIndexType,
        kXXTExplorerCreateItemViewSectionIndexLocation,
        kXXTExplorerCreateItemViewSectionIndexMax
    } kXXTExplorerCreateItemViewSectionIndex;
#else
    typedef enum : NSUInteger {
        kXXTExplorerCreateItemViewSectionIndexName = 0,
        kXXTExplorerCreateItemViewSectionIndexType,
        kXXTExplorerCreateItemViewSectionIndexMax
    } kXXTExplorerCreateItemViewSectionIndex;
#endif
typedef enum : NSUInteger {
    kXXTExplorerCreateItemViewItemTypeLUA = 0,
    kXXTExplorerCreateItemViewItemTypeTXT,
    kXXTExplorerCreateItemViewItemTypeFIL,
    kXXTExplorerCreateItemViewItemTypeDIR
} kXXTExplorerCreateItemViewItemType;

@interface XXTExplorerCreateItemViewController () <UITextFieldDelegate>

@property (nonatomic, copy, readonly) NSString *entryPath;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, assign) kXXTExplorerCreateItemViewItemType selectedItemType;
@property (nonatomic, strong) XUIViewShaker *itemNameShaker;

@end

@implementation XXTExplorerCreateItemViewController {
    BOOL isFirstTimeLoaded;
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
    BOOL _editAfterCreatingItem;
}

+ (NSDateFormatter *)itemTemplateDateFormatter {
    static NSDateFormatter *itemTemplateDateFormatter = nil;
    if (!itemTemplateDateFormatter) {
        itemTemplateDateFormatter = ({
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            dateFormatter;
        });
    }
    return itemTemplateDateFormatter;
}

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

- (instancetype)initWithEntryPath:(NSString *)entryPath {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _entryPath = entryPath;
        [self setup];
    }
    return self;
}

- (void)setup {
    _editAfterCreatingItem = YES;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"Create Item", nil);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    if ([self.navigationController.viewControllers firstObject] == self) {
        self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    }
    self.navigationItem.rightBarButtonItem = self.doneButtonItem;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    [self reloadStaticTableViewData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self.nameField isFirstResponder]) {
        [self.nameField becomeFirstResponder];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeWithNotificaton:) name:UITextFieldTextDidChangeNotification object:self.nameField];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)reloadStaticTableViewData {
#ifndef APPSTORE
    staticSectionTitles = @[ NSLocalizedString(@"Filename", nil),
                             NSLocalizedString(@"Type", nil),
                             NSLocalizedString(@"Location", nil),
                             ];
    staticSectionFooters = @[ NSLocalizedString(@"Tap to edit filename.", nil), @"", @"" ];
#else
    staticSectionTitles = @[ NSLocalizedString(@"Filename", nil),
                             NSLocalizedString(@"Type", nil),
                             ];
    staticSectionFooters = @[ NSLocalizedString(@"Tap to edit filename.", nil), @"" ];
#endif
    
    XXTExplorerItemNameCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTExplorerItemNameCell class]) owner:nil options:nil] lastObject];
    cell1.nameField.delegate = self;
    self.nameField = cell1.nameField;
    self.itemNameShaker = [[XUIViewShaker alloc] initWithView:self.nameField];
    
    XXTEMoreSwitchCell *cell1_2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreSwitchCell class]) owner:nil options:nil] lastObject];
    cell1_2.titleLabel.text = NSLocalizedString(@"Edit After Creating Item", nil);
    cell1_2.optionSwitch.on = _editAfterCreatingItem;
    [cell1_2.optionSwitch addActionforControlEvents:UIControlEventValueChanged respond:^(UIControl *sender) {
        UISwitch *optionSwitch = (UISwitch *)sender;
        _editAfterCreatingItem = optionSwitch.on;
    }];
    
    XXTEMoreTitleDescriptionCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryNone;
    cell2.titleLabel.text = NSLocalizedString(@"Regular Lua File", nil);
    cell2.descriptionLabel.text = NSLocalizedString(@"A regular lua file from template. (text/lua)", nil);
    
    XXTEMoreTitleDescriptionCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryNone;
    cell3.titleLabel.text = NSLocalizedString(@"Regular Text File", nil);
    cell3.descriptionLabel.text = NSLocalizedString(@"An empty regular text file. (text/plain)", nil);
    
    XXTEMoreTitleDescriptionCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryNone;
    cell4.titleLabel.text = NSLocalizedString(@"Regular File", nil);
    cell4.descriptionLabel.text = NSLocalizedString(@"An empty regular file.", nil);
    
    XXTEMoreTitleDescriptionCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionCell class]) owner:nil options:nil] lastObject];
    cell5.accessoryType = UITableViewCellAccessoryNone;
    cell5.titleLabel.text = NSLocalizedString(@"Directory", nil);
    cell5.descriptionLabel.text = NSLocalizedString(@"A directory with nothing inside.", nil);
    
#ifndef APPSTORE
    XXTEMoreAddressCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell6.addressLabel.text = self.entryPath;
#endif
    
#ifndef APPSTORE
    staticCells = @[
                    @[ cell1, cell1_2 ],
                    @[ cell2, cell3, cell4, cell5 ],
                    @[ cell6 ],
                    ];
#else
    staticCells = @[
                    @[ cell1, cell1_2 ],
                    @[ cell2, cell3, cell4, cell5 ],
                    ];
#endif
}

#pragma mark - Getters

- (BOOL)editImmediately {
    return (_editAfterCreatingItem &&
            (
             self.selectedItemType == kXXTExplorerCreateItemViewItemTypeLUA ||
             self.selectedItemType == kXXTExplorerCreateItemViewItemTypeTXT
             ));
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

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kXXTExplorerCreateItemViewSectionIndexMax;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return staticCells[(NSUInteger) section].count;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexName) {
            if (indexPath.row == 0) {
                return 52.f;
            }
        } else if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexType) {
            return 66.f;
        }
    }
    return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexName) {
            if (indexPath.row == 0) {
                return 52.f;
            }
        }
        else if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexType) {
            return 66.f;
        }
#ifndef APPSTORE
        else if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexLocation) {
            if (@available(iOS 8.0, *)) {
                return UITableViewAutomaticDimension;
            } else {
                UITableViewCell *cell = staticCells[indexPath.section][indexPath.row];
                [cell setNeedsUpdateConstraints];
                [cell updateConstraintsIfNeeded];
                
                cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
                [cell setNeedsLayout];
                [cell layoutIfNeeded];
                
                CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
                return (height > 0) ? (height + 1.0) : 44.f;
            }
        }
#endif
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexType) {
            self.selectedItemType = (NSUInteger) indexPath.row;
            for (UITableViewCell *cell in tableView.visibleCells) {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            UITableViewCell *selectCell = [tableView cellForRowAtIndexPath:indexPath];
            selectCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
#ifndef APPSTORE
        else if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexLocation) {
            NSString *detailText = ((XXTEMoreAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
            if (detailText && detailText.length > 0) {
                UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    toastMessage(self, NSLocalizedString(@"Path has been copied to the pasteboard.", nil));
                    blockInteractions(blockVC, NO);
                });
            }
        }
#endif
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
        if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexType) {
            if (indexPath.row == self.selectedItemType) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        return cell;
    }
    return [UITableViewCell new];
}

#pragma mark - UIControl Actions

- (void)dismissViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    if ([_delegate respondsToSelector:@selector(createItemViewControllerDidDismiss:)]) {
        [_delegate createItemViewControllerDidDismiss:self];
    }
}

- (void)submitViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    if (self.entryPath.length == 0) {
        return;
    }
    NSString *itemName = self.nameField.text;
    if (itemName.length == 0 || [itemName rangeOfString:@"/"].location != NSNotFound || [itemName rangeOfString:@"\0"].location != NSNotFound) {
        [self.itemNameShaker shake];
        return;
    }
    if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeLUA) {
        if (![[itemName pathExtension] isEqualToString:@"lua"]) {
            itemName = [itemName stringByAppendingPathExtension:@"lua"];
        }
    } else if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeTXT) {
        if (![[itemName pathExtension] isEqualToString:@"txt"]) {
            itemName = [itemName stringByAppendingPathExtension:@"txt"];
        }
    }
    NSString *itemExtension = [[itemName pathExtension] lowercaseString];
    NSFileManager *createItemManager = [[NSFileManager alloc] init];
    struct stat itemStat;
    NSString *itemPath = [self.entryPath stringByAppendingPathComponent:itemName];
    if (/* [createItemManager fileExistsAtPath:itemPath] */ 0 == lstat([itemPath UTF8String], &itemStat)) {
        toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"File \"%@\" already exists.", nil), itemName]));
        [self.itemNameShaker shake];
        return;
    }
    if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeDIR) {
        NSError *createError = nil;
        BOOL createResult = [createItemManager createDirectoryAtPath:itemPath withIntermediateDirectories:NO attributes:nil error:&createError];
        if (!createResult) {
            toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Cannot create file \"%@\": %@.", nil), itemName, [createError localizedDescription]]));
            [self.itemNameShaker shake];
            return;
        }
    } else {
        
        NSError *createError = nil;
        NSData *templateData = [NSData data];
        NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"XXTEItemTemplate" ofType:itemExtension];
        
        if ([createItemManager fileExistsAtPath:templatePath]) {
            
            NSMutableString *newTemplate = [[[NSString alloc] initWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:&createError] mutableCopy];
            
            if (createError) {
                toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Cannot read template \"%@\".", nil), templatePath]));
                return;
            }
            
            NSString *deviceName = [[UIDevice currentDevice] name];
            NSString *versionString = [NSString stringWithFormat:@"%@ V%@", uAppDefine(@"PRODUCT_NAME"), uAppDefine(@"DAEMON_VERSION")];
            NSString *longDateString = [self.class.itemTemplateDateFormatter stringFromDate:[NSDate date]];
            NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]];
            NSString *yearString = [@([dateComponents year]) stringValue];
            
            [newTemplate replaceOccurrencesOfString:@"{{FILENAME}}" withString:itemName options:0 range:NSMakeRange(0, newTemplate.length)];
            [newTemplate replaceOccurrencesOfString:@"{{PRODUCT_STRING}}" withString:versionString options:0 range:NSMakeRange(0, newTemplate.length)];
            [newTemplate replaceOccurrencesOfString:@"{{AUTHOR_NAME}}" withString:deviceName options:0 range:NSMakeRange(0, newTemplate.length)];
            [newTemplate replaceOccurrencesOfString:@"{{CREATED_AT}}" withString:longDateString options:0 range:NSMakeRange(0, newTemplate.length)];
            [newTemplate replaceOccurrencesOfString:@"{{COPYRIGHT_YEAR}}" withString:yearString options:0 range:NSMakeRange(0, newTemplate.length)];
            [newTemplate replaceOccurrencesOfString:@"{{DEVICE_NAME}}" withString:deviceName options:0 range:NSMakeRange(0, newTemplate.length)];
            
            templateData = [newTemplate dataUsingEncoding:NSUTF8StringEncoding];
            
        }
        
        BOOL createResult = [createItemManager createFileAtPath:itemPath contents:templateData attributes:nil];
        if (!createResult) {
            toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Cannot create file \"%@\".", nil), itemName]));
            [self.itemNameShaker shake];
            return;
        }
    }
    if ([_delegate respondsToSelector:@selector(createItemViewController:didFinishCreatingItemAtPath:)]) {
        [_delegate createItemViewController:self didFinishCreatingItemAtPath:itemPath];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.nameField) {
        if ([string rangeOfString:@"/"].location != NSNotFound || [string rangeOfString:@"\0"].location != NSNotFound) {
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
        self.doneButtonItem.enabled = YES;
    } else {
        self.doneButtonItem.enabled = NO;
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTExplorerCreateItemViewController dealloc]");
#endif
}

@end
