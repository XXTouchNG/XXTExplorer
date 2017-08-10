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
#import "XXTEMoreTitleDescriptionValueCell.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEViewShaker.h"
#import "XXTEAppDefines.h"
#import "XXTEMoreAddressCell.h"
#import <PromiseKit/PromiseKit.h>
#import "XXTENotificationCenterDefines.h"

typedef enum : NSUInteger {
    kXXTExplorerCreateItemViewSectionIndexName = 0,
    kXXTExplorerCreateItemViewSectionIndexType,
    kXXTExplorerCreateItemViewSectionIndexLocation,
    kXXTExplorerCreateItemViewSectionIndexMax
} kXXTExplorerCreateItemViewSectionIndex;

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
@property (nonatomic, strong) XXTEViewShaker *itemNameShaker;

@end

@implementation XXTExplorerCreateItemViewController {
    BOOL isFirstTimeLoaded;
    NSArray <NSMutableArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
    NSArray <NSNumber *> *staticSectionRowNum;
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
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = NSLocalizedString(@"Create Item", nil);
    
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self.nameField isFirstResponder]) {
        [self.nameField becomeFirstResponder];
    }
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
                             NSLocalizedString(@"Type", nil),
                             NSLocalizedString(@"Location", nil)
                             ];
    staticSectionFooters = @[ NSLocalizedString(@"Tap to edit filename.", nil), @"", @"" ];
    
    XXTExplorerItemNameCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTExplorerItemNameCell class]) owner:nil options:nil] lastObject];
    cell1.nameField.delegate = self;
    self.nameField = cell1.nameField;
    self.itemNameShaker = [[XXTEViewShaker alloc] initWithView:self.nameField];
    
    XXTEMoreTitleDescriptionValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) owner:nil options:nil] lastObject];
    cell2.accessoryType = UITableViewCellAccessoryNone;
    cell2.titleLabel.text = NSLocalizedString(@"Regular Lua File", nil);
    cell2.descriptionLabel.text = NSLocalizedString(@"A regular lua file from template. (text/lua)", nil);
    cell2.valueLabel.text = @"LUA";
    
    XXTEMoreTitleDescriptionValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) owner:nil options:nil] lastObject];
    cell3.accessoryType = UITableViewCellAccessoryNone;
    cell3.titleLabel.text = NSLocalizedString(@"Regular Text File", nil);
    cell3.descriptionLabel.text = NSLocalizedString(@"An empty regular text file. (text/plain)", nil);
    cell3.valueLabel.text = @"TXT";
    
    XXTEMoreTitleDescriptionValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) owner:nil options:nil] lastObject];
    cell4.accessoryType = UITableViewCellAccessoryNone;
    cell4.titleLabel.text = NSLocalizedString(@"Regular File", nil);
    cell4.descriptionLabel.text = NSLocalizedString(@"An empty regular file.", nil);
    cell4.valueLabel.text = @"FIL";
    
    XXTEMoreTitleDescriptionValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleDescriptionValueCell class]) owner:nil options:nil] lastObject];
    cell5.accessoryType = UITableViewCellAccessoryNone;
    cell5.titleLabel.text = NSLocalizedString(@"Directory", nil);
    cell5.descriptionLabel.text = NSLocalizedString(@"A directory with nothing inside.", nil);
    cell5.valueLabel.text = @"DIR";
    
    XXTEMoreAddressCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell6.addressLabel.text = self.entryPath;
    
    staticCells = @[
                    @[ cell1 ],
                    @[ cell2, cell3, cell4, cell5 ],
                    @[ cell6 ]
                    ];
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
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexName) {
            if (indexPath.row == 0) {
                return 52.f;
            }
        } else if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexType) {
            return 66.f;
        } else if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexLocation) {
            return UITableViewAutomaticDimension;
        }
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
        } else if (indexPath.section == kXXTExplorerCreateItemViewSectionIndexLocation) {
            NSString *detailText = ((XXTEMoreAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self, YES);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    showUserMessage(self, NSLocalizedString(@"Path has been copied to the pasteboard.", nil));
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
    if (XXTE_COLLAPSED) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)submitViewController:(id)sender {
    if ([self.nameField isFirstResponder]) {
        [self.nameField resignFirstResponder];
    }
    if (self.entryPath.length == 0) {
        return;
    }
    NSString *itemName = self.nameField.text;
    if (itemName.length == 0 || [itemName containsString:@"/"] || [itemName containsString:@"\0"]) {
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
        showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" already exists.", nil), itemName]);
        [self.itemNameShaker shake];
        return;
    }
    if (self.selectedItemType == kXXTExplorerCreateItemViewItemTypeDIR) {
        NSError *createError = nil;
        BOOL createResult = [createItemManager createDirectoryAtPath:itemPath withIntermediateDirectories:NO attributes:nil error:&createError];
        if (!createResult) {
            showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot create file \"%@\": %@.", nil), itemName, [createError localizedDescription]]);
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
                showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot read template \"%@\".", nil), templatePath]);
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
            showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot create file \"%@\".", nil), itemName]);
            [self.itemNameShaker shake];
            return;
        }
    }
    if (XXTE_COLLAPSED) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
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
        self.doneButtonItem.enabled = YES;
    } else {
        self.doneButtonItem.enabled = NO;
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTExplorerCreateItemViewController dealloc]");
#endif
}

@end
