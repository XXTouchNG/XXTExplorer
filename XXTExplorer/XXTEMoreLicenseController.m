//
//  XXTEMoreLicenseController.m
//  XXTExplorer
//
//  Created by Zheng on 01/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#include <objc/runtime.h>
#import "XXTEMoreLicenseController.h"
#import <LGAlertView/LGAlertView.h>
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreLicenseCell.h"
#import "XXTENetworkDefines.h"
#import "XXTEViewShaker.h"

typedef enum : NSUInteger {
    kXXTEMoreLicenseSectionIndexNewLicense = 0,
    kXXTEMoreLicenseSectionIndexCurrentLicense,
    kXXTEMoreLicenseSectionIndexDevice,
    kXXTEMoreLicenseSectionIndexMax
} kXXTEMoreLicenseSectionIndex;

typedef void (^ _Nullable XXTERefreshControlHandler)();

@interface XXTEMoreLicenseController () <UITextFieldDelegate, LGAlertViewDelegate>
@property (nonatomic, weak) UITextField *licenseField;
@property (nonatomic, strong) XXTEViewShaker *licenseShaker;
@property (nonatomic, strong) NSString *licenseCode;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@end

@implementation XXTEMoreLicenseController {
    BOOL isFirstTimeLoaded;
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
    NSArray <NSString *> *staticSectionFooters;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithLicenseCode:(NSString *)licenseCode {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _licenseCode = licenseCode;
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

#pragma mark - Default Style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = NSLocalizedString(@"My License", nil);
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlDidChanged:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL

    if ([self.navigationController.viewControllers firstObject] == self) {
        self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    }
    self.navigationItem.rightBarButtonItem = self.doneButtonItem;
    
    [self reloadStaticTableViewData];
    [self reloadDynamicTableViewDataWithCompletion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeWithNotificaton:) name:UITextFieldTextDidChangeNotification object:self.licenseField];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ NSLocalizedString(@"New License", nil),
                             NSLocalizedString(@"Current License", nil),
                             NSLocalizedString(@"Device", nil) ];
    staticSectionFooters = @[ NSLocalizedString(@"Enter your 16-digit license code and tap \"Done\" to activate the license and bind it to current device.\nLicense code only contains 3-9 and A-Z, spaces are not included.", nil), @"", @"" ];
    
    XXTEMoreLicenseCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLicenseCell class]) owner:nil options:nil] lastObject];
    cell1.licenseField.text = @"";
    cell1.licenseField.delegate = self;
    self.licenseField = cell1.licenseField;
    self.licenseShaker = [[XXTEViewShaker alloc] initWithView:self.licenseField];
    
    NSString *initialLicenseCode = self.licenseCode;
    if ([self isValidLicenseFormat:initialLicenseCode]) {
        cell1.licenseField.text = [self formatLicense:initialLicenseCode];
        [self textFieldDidChange:cell1.licenseField];
    } else {
        showUserMessage(self, NSLocalizedString(@"Cannot autofill license field: Invalid license code.", nil));
    }
    
    XXTEMoreTitleValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Expired At", nil);
    cell2.valueLabel.text = @"\n";
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Version", nil);
    cell3.valueLabel.text = @"";
    cell3.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"iOS Version", nil);
    cell4.valueLabel.text = @"";
    cell4.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"Device Type", nil);
    cell5.valueLabel.text = @"";
    cell5.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Device Name", nil);
    cell6.valueLabel.text = @"";
    cell6.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Serial Number", nil);
    cell7.valueLabel.text = @"";
    cell7.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"MAC Address", nil);
    cell8.valueLabel.text = @"";
    cell8.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"Unique ID", nil);
    cell9.valueLabel.text = @"";
    cell9.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    staticCells = @[
                    @[ cell1 ],
                    //
                    @[ cell2 ],
                    //
                    @[ cell3, cell4, cell5, cell6, cell7, cell8, cell9 ]
                    ];
}

- (void)reloadDynamicTableViewDataWithCompletion:(XXTERefreshControlHandler)handler {
    blockUserInteractions(self, YES);
    [NSURLConnection POST:uAppDaemonCommandUrl(@"deviceinfo") JSON:@{  }]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDictionary) {
        NSDictionary *dataDictionary = jsonDictionary[@"data"];
        if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
            ((XXTEMoreTitleValueCell *)staticCells[2][0]).valueLabel.text = dataDictionary[@"zeversion"];
            ((XXTEMoreTitleValueCell *)staticCells[2][1]).valueLabel.text = dataDictionary[@"sysversion"];
            ((XXTEMoreTitleValueCell *)staticCells[2][2]).valueLabel.text = dataDictionary[@"devtype"];
            ((XXTEMoreTitleValueCell *)staticCells[2][3]).valueLabel.text = dataDictionary[@"devname"];
            ((XXTEMoreTitleValueCell *)staticCells[2][4]).valueLabel.text = dataDictionary[@"devsn"];
            ((XXTEMoreTitleValueCell *)staticCells[2][5]).valueLabel.text = dataDictionary[@"devmac"];
            ((XXTEMoreTitleValueCell *)staticCells[2][6]).valueLabel.text = dataDictionary[@"deviceid"];
        }
        NSDictionary *sendDictionary = @{
                                         @"did": dataDictionary[@"deviceid"],
                                         @"sv": dataDictionary[@"sysversion"],
                                         @"v": dataDictionary[@"zeversion"],
                                         @"dt": dataDictionary[@"devtype"],
                                         @"ts": [@((int)[[NSDate date] timeIntervalSince1970]) stringValue],
                                         @"sn": dataDictionary[@"devsn"],
                                         };
        return @[uAppLicenseServerCommandUrl(@"device_info"), sendDictionary];
    })
    .then(sendCloudApiRequest)
    .then(^(NSDictionary *licenseDictionary) {
        if ([licenseDictionary[@"code"] isEqualToNumber:@0]) {
            NSTimeInterval expirationInterval = [licenseDictionary[@"data"][@"expireDate"] doubleValue];
            NSTimeInterval nowInterval = [licenseDictionary[@"data"][@"nowDate"] doubleValue];
            [self updateTableViewCell:((XXTEMoreTitleValueCell *)staticCells[1][0])
                       expirationTime:expirationInterval
                          nowInterval:nowInterval];
        }
    })
    .catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            showUserMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockUserInteractions(self, NO);
        if (handler) {
            handler();
        }
    });
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

- (void)refreshControlDidChanged:(UIRefreshControl *)refreshControl {
    [self reloadDynamicTableViewDataWithCompletion:^{
        [refreshControl endRefreshing];
    }];
}

- (void)dismissViewController:(id)dismissViewController {
    if ([self.licenseField isFirstResponder]) {
        [self.licenseField resignFirstResponder];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)submitViewController:(id)sender {
    UITextField *textField = self.licenseField;
    NSString *fromString = textField.text;
    NSString *trimedString = [fromString stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (trimedString.length != 16) {
        [self.licenseShaker shake];
        return NO;
    }
    if ([textField isFirstResponder]) {
        [textField resignFirstResponder];
    }
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"License Activation", nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Activate license \"%@\" for this device?", nil), trimedString]
                                                          style:LGAlertViewStyleActionSheet
                                                   buttonTitles:@[  ]
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:NSLocalizedString(@"Activate", nil)
                                                       delegate:self];
    objc_setAssociatedObject(alertView, @selector(alertView:activateLicense:), trimedString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alertView showAnimated:YES completionHandler:nil];
    return YES;
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return kXXTEMoreLicenseSectionIndexMax;
    }
    return 0;
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
        return UITableViewAutomaticDimension;
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreLicenseSectionIndexDevice) {
            NSString *detailText = ((XXTEMoreTitleValueCell *)staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row]).valueLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self, YES);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    showUserMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
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
        return staticCells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
    }
    return [UITableViewCell new];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self submitViewController:textField];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.licenseField) {
        NSString *fromString = textField.text;
        if (range.location == fromString.length - 1 && range.length == 1) {
            if ([[fromString substringWithRange:range] isEqualToString:@" "]) {
                [textField deleteBackward];
            }
            [textField deleteBackward];
            [self textFieldDidChange:textField];
            return NO;
        }
        if (range.location != fromString.length) {
            [self textFieldDidChange:textField];
            return NO;
        }
        NSString *toString = [fromString stringByReplacingCharactersInRange:range withString:string];
        if (![self isValidLicenseFormat:toString]) {
            [self.licenseShaker shake];
            [self textFieldDidChange:textField];
            return NO;
        }
        textField.text = [self formatLicense:toString];
        [self textFieldDidChange:textField];
        return NO;
    }
    return YES;
}

- (void)textFieldDidChangeWithNotificaton:(NSNotification *)aNotification {
    UITextField *textField = (UITextField *)aNotification.object;
    [self textFieldDidChange:textField];
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSString *fromString = textField.text;
    NSString *trimedString = [fromString stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (trimedString.length == 16) {
        textField.textColor = XXTE_COLOR_SUCCESS;
        self.doneButtonItem.enabled = YES;
    } else {
        textField.textColor = XXTE_COLOR;
        self.doneButtonItem.enabled = NO;
    }
}

#pragma mark - License Check

- (BOOL)isValidLicenseFormat:(NSString *)licenseCode {
    NSString *trimedString = [licenseCode stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *upperedString = [trimedString uppercaseString];
    NSString *regex = @"^[3-9A-Z]{0,16}$";
    NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:NULL];
    return [pattern numberOfMatchesInString:upperedString options:0 range:NSMakeRange(0, upperedString.length)] > 0;
}

- (NSString *)formatLicense:(NSString *)licenseCode {
    NSString *trimedString = [licenseCode stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *upperedString = [trimedString uppercaseString];
    NSMutableString *spacedString = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < upperedString.length; i++) {
        [spacedString appendString:[upperedString substringWithRange:NSMakeRange(i, 1)]];
        if ((i + 1) % 4 == 0 && i != 15) {
            [spacedString appendString:@" "];
        }
    }
    return [[NSString alloc] initWithString:spacedString];
}

#pragma mark - LGAlertViewDelegate

- (void)alertViewDestructed:(LGAlertView *)alertView {
    SEL selectors[] = {
        @selector(alertView:activateLicense:)
    };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    for (int i = 0; i < sizeof(selectors) / sizeof(SEL); i++) {
        SEL selector = selectors[i];
        id obj = objc_getAssociatedObject(alertView, selector);
        if (obj) {
            objc_setAssociatedObject(alertView, selector, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [self performSelector:selector withObject:alertView withObject:obj];
            break;
        }
    }
    objc_removeAssociatedObjects(alertView);
#pragma clang diagnostic pop
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
}

- (void)alertView:(LGAlertView *)alertView activateLicense:(NSString *)licenseCode {
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Activating", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Activating license \"%@\" and bind to current device...", nil), licenseCode]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:nil
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:nil
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    [NSURLConnection POST:uAppDaemonCommandUrl(@"deviceinfo") JSON:@{  }]
    .then(convertJsonString)
    .then(^(NSDictionary *jsonDictionary) {
        NSDictionary *dataDictionary = jsonDictionary[@"data"];
        NSDictionary *sendDictionary = @{
                                         @"did": dataDictionary[@"deviceid"],
                                         @"code": licenseCode,
                                         @"sv": dataDictionary[@"sysversion"],
                                         @"v": dataDictionary[@"zeversion"],
                                         @"dt": dataDictionary[@"devtype"],
                                         @"ts": [@((int)[[NSDate date] timeIntervalSince1970]) stringValue],
                                         @"sn": dataDictionary[@"devsn"],
                                         };
        return @[uAppLicenseServerCommandUrl(@"bind_code"), sendDictionary];
    })
    .then(sendCloudApiRequest)
    .then(^(NSDictionary *licenseDictionary) {
        if ([licenseDictionary[@"code"] isEqualToNumber:@0]) {
            NSTimeInterval expirationInterval = [licenseDictionary[@"data"][@"deviceExpireDate"] doubleValue];
            NSTimeInterval nowInterval = [licenseDictionary[@"data"][@"nowDate"] doubleValue];
            [self updateTableViewCell:((XXTEMoreTitleValueCell *)staticCells[1][0])
                       expirationTime:expirationInterval
                          nowInterval:nowInterval];
            NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:nowInterval];
            NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationInterval];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *expirationDateString = [dateFormatter stringFromDate:expirationDate];
            NSString *nowDateString = [dateFormatter stringFromDate:nowDate];
            LGAlertView *alertView2 = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"License Activated", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"%@\nActivated At: %@\nExpired At: %@", nil), licenseDictionary[@"message"], nowDateString, expirationDateString]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[  ]
                                                      cancelButtonTitle:NSLocalizedString(@"Done", nil)
                                                 destructiveButtonTitle:nil
                                                               delegate:self];
            if (alertView1 && alertView1.isShowing) {
                [alertView1 transitionToAlertView:alertView2 completionHandler:nil];
            }
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot active license: %@", nil), licenseDictionary[@"message"]];
        }
    })
    .catch(^(NSError *serverError) {
        LGAlertView *alertView2 = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Failed", nil)
                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Failed to activate license \"%@\": %@", nil), licenseCode, [serverError localizedDescription]]
                                                               style:LGAlertViewStyleActionSheet
                                                        buttonTitles:@[  ]
                                                   cancelButtonTitle:NSLocalizedString(@"Try Again Later", nil)
                                              destructiveButtonTitle:nil
                                                            delegate:self];
        if (alertView1 && alertView1.isShowing) {
            [alertView1 transitionToAlertView:alertView2 completionHandler:nil];
        }
    })
    .finally(^() {
        
    });
}

#pragma mark - Reusable UI Updater

- (void)updateTableViewCell:(XXTEMoreTitleValueCell *)cell
             expirationTime:(NSTimeInterval)expirationInterval
                nowInterval:(NSTimeInterval)nowInterval {
    if (expirationInterval > 0) {
        NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:nowInterval];
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationInterval];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd\nHH:mm:ss"];
        NSString *expirationDateString = [dateFormatter stringFromDate:expirationDate];
        UILabel *dateLabel = cell.valueLabel;
        dateLabel.text = expirationDateString;
        if ([nowDate timeIntervalSinceDate:expirationDate] >= 0) {
            dateLabel.textColor = XXTE_COLOR_DANGER;
        }
        else {
            dateLabel.textColor = XXTE_COLOR;
        }
        [self.tableView reloadData];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreLicenseController dealloc]");
#endif
}

@end
