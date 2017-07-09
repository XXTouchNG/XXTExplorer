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

- (void)setup {
//    self.hidesBottomBarWhenPushed = YES;
}

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
//    self.tableView.rowHeight = UITableViewAutomaticDimension;
//    self.tableView.estimatedRowHeight = 44.f;
    
    [self reloadStaticTableViewData];
    [self reloadDynamicTableViewDataWithCompletion:nil];
}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    if (isFirstTimeLoaded) {
//        [self reloadDynamicTableViewDataWithCompletion:nil];
//    }
//    isFirstTimeLoaded = YES;
//}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ @"New License", @"Current License", @"Device" ];
    staticSectionFooters = @[ @"Enter your 16-digit license code and tap \"Done\" to activate the license and bind it to current device.\nLicense code only contains 3-9 and A-Z, spaces are not included.", @"", @"" ];
    
    XXTEMoreLicenseCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLicenseCell class]) owner:nil options:nil] lastObject];
    cell1.licenseField.text = @"";
    cell1.licenseField.delegate = self;
    self.licenseField = cell1.licenseField;
    self.licenseShaker = [[XXTEViewShaker alloc] initWithView:self.licenseField];
    
    XXTEMoreTitleValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Expired At", nil);
    cell2.valueLabel.text = @"\n";
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Version", nil);
    cell3.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"iOS Version", nil);
    cell4.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"Device Type", nil);
    cell5.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Device Name", nil);
    cell6.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Serial Number", nil);
    cell7.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"MAC Address", nil);
    cell8.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"Unique ID", nil);
    cell9.valueLabel.text = @"";
    
    staticCells = @[
                    @[ cell1 ],
                    //
                    @[ cell2 ],
                    //
                    @[ cell3, cell4, cell5, cell6, cell7, cell8, cell9 ]
                    ];
}

- (void)reloadDynamicTableViewDataWithCompletion:(XXTERefreshControlHandler)handler {
    blockUserInteractions(self.navigationController.view, YES);
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
            showUserMessage(self.navigationController.view, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            showUserMessage(self.navigationController.view, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockUserInteractions(self.navigationController.view, NO);
        if (handler) {
            handler();
        }
    });
}

#pragma mark - UIControl Actions

- (void)refreshControlDidChanged:(UIRefreshControl *)refreshControl {
    [self reloadDynamicTableViewDataWithCompletion:^{
        [refreshControl endRefreshing];
    }];
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
            NSString *detailText = ((XXTEMoreTitleValueCell *)staticCells[indexPath.section][indexPath.row]).valueLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self.navigationController.view, YES);
                [PMKPromise promiseWithValue:@YES].then(^() {
                    [[UIPasteboard generalPasteboard] setString:detailText];
                }).finally(^() {
                    showUserMessage(self.navigationController.view, NSLocalizedString(@"Copied to the pasteboard.", nil));
                    blockUserInteractions(self.navigationController.view, NO);
                });
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return NSLocalizedString(staticSectionTitles[section], nil);
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return NSLocalizedString(staticSectionFooters[section], nil);
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return staticCells[indexPath.section][indexPath.row];
    }
    return [UITableViewCell new];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isFirstResponder]) {
        NSString *fromString = textField.text;
        NSString *trimedString = [fromString stringByReplacingOccurrencesOfString:@" " withString:@""];
        if (trimedString.length != 16) {
            [self.licenseShaker shake];
            return NO;
        }
        [textField resignFirstResponder];
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"License Activation", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Activate license \"%@\" for this device?", nil), trimedString]
                                                              style:LGAlertViewStyleActionSheet
                                                       buttonTitles:@[  ]
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Activate", nil)
                                                           delegate:self];
        objc_setAssociatedObject(alertView, @selector(alertView:activateLicense:), trimedString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [alertView showAnimated:YES completionHandler:nil];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.licenseField) {
        NSString *fromString = textField.text;
        NSString *toString = [fromString stringByReplacingCharactersInRange:range withString:string];
        NSString *trimedString = [toString stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString *upperedString = [trimedString uppercaseString];
        if (range.location == fromString.length - 1 && range.length == 1) {
            if ([[fromString substringWithRange:range] isEqualToString:@" "]) {
                [textField deleteBackward];
            }
            [textField deleteBackward];
            [self updateTextFieldTextColor];
            return NO;
        }
        if (range.location != fromString.length) {
            [self updateTextFieldTextColor];
            return NO;
        }
        NSString *regex = @"^[3-9A-Z]{0,16}$";
        NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:NULL];
        if ([pattern numberOfMatchesInString:upperedString options:0 range:NSMakeRange(0, upperedString.length)] <= 0) {
            [self.licenseShaker shake];
            [self updateTextFieldTextColor];
            return NO;
        }
        NSMutableString *spacedString = [[NSMutableString alloc] init];
        for (NSUInteger i = 0; i < upperedString.length; i++) {
            [spacedString appendString:[upperedString substringWithRange:NSMakeRange(i, 1)]];
            if ((i + 1) % 4 == 0 && i != 15) {
                [spacedString appendString:@" "];
            }
        }
        textField.text = [spacedString copy];
        [self updateTextFieldTextColor];
        return NO;
    }
    return YES;
}

- (void)updateTextFieldTextColor {
    NSString *fromString = self.licenseField.text;
    NSString *trimedString = [fromString stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (trimedString.length == 16) {
        self.licenseField.textColor = XXTE_COLOR_SUCCESS;
    } else {
        self.licenseField.textColor = XXTE_COLOR;
    }
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
            NSTimeInterval expirationInterval = [licenseDictionary[@"data"][@"expireDate"] doubleValue];
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
            @throw licenseDictionary[@"message"];
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
