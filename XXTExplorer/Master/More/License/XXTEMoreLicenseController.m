//
//  XXTEMoreLicenseController.m
//  XXTExplorer
//
//  Created by Zheng on 01/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <sys/stat.h>
#import <objc/runtime.h>
#import "XXTEMoreLicenseController.h"
#import <LGAlertView/LGAlertView.h>
#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreLicenseCell.h"
#import "XXTEMoreLinkCell.h"
#import "XXTENetworkDefines.h"
#import "XUIViewShaker.h"
#import "XXTExplorerViewController.h"

#import "XXTEShimmeringView.h"
#import "XXTECommonWebViewController.h"

#import "XXTEAppDefines.h"

static NSString * const kXXTEMoreLicenseCachedLicense = @"kXXTEMoreLicenseCachedLicense";

typedef enum : NSUInteger {
    kXXTEMoreLicenseSectionIndexNewLicense = 0,
    kXXTEMoreLicenseSectionIndexCurrentLicense,
    kXXTEMoreLicenseSectionIndexDevice,
    kXXTEMoreLicenseSectionIndexMax
} kXXTEMoreLicenseSectionIndex;

typedef enum : NSUInteger {
    kXXTEMoreLicenseDeviceRowIndexVersion = 0,
    kXXTEMoreLicenseDeviceRowIndexiOSVersion,
    kXXTEMoreLicenseDeviceRowIndexDeviceType,
    kXXTEMoreLicenseDeviceRowIndexDeviceName,
    kXXTEMoreLicenseDeviceRowIndexDeviceSerial,
    kXXTEMoreLicenseDeviceRowIndexMacAddress,
    kXXTEMoreLicenseDeviceRowIndexUDID
} kXXTEMoreLicenseDeviceRowIndex;

typedef void (^ _Nullable XXTERefreshControlHandler)(void);

@interface XXTEMoreLicenseController () <UITextFieldDelegate, LGAlertViewDelegate>

@property (nonatomic, weak) UITextField *licenseField;
@property (nonatomic, strong) XUIViewShaker *licenseShaker;
@property (nonatomic, strong) NSString *licenseCode;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;
@property (nonatomic, strong) NSDictionary *dataDictionary;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    XXTE_END_IGNORE_PARTIAL
    
    self.title = NSLocalizedString(@"License & Device", nil);
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlDidChanged:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
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
    [self reloadDynamicTableViewDataWithCompletion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeWithNotificaton:) name:UITextFieldTextDidChangeNotification object:self.licenseField];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ NSLocalizedString(@"New License", nil),
                             NSLocalizedString(@"Current License", nil),
                             NSLocalizedString(@"Device", nil) ];
    staticSectionFooters = @[ NSLocalizedString(@"Enter your 12/16-digit license code and tap \"Done\" to activate the license and bind it to current device.\nLicense code only contains 3-9 and A-Z, spaces are not included.", nil), NSLocalizedString(@"The content displayed in this page cannot be the proof of your purchase.", nil), @"" ];
    
    XXTEMoreLicenseCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLicenseCell class]) owner:nil options:nil] lastObject];
    cell1.licenseField.text = @"";
    cell1.licenseField.delegate = self;
    self.licenseField = cell1.licenseField;
    self.licenseShaker = [[XUIViewShaker alloc] initWithView:self.licenseField];
    
    NSString *initialLicenseCode = self.licenseCode;
    if (initialLicenseCode.length > 0) {
        if ([self isValidLicenseFormat:initialLicenseCode]) {
            cell1.licenseField.text = [self formatLicense:initialLicenseCode];
            [self textFieldDidChange:cell1.licenseField];
        } else {
            toastMessage(self, NSLocalizedString(@"Cannot autofill license field: Invalid license code.", nil));
        }
    }
    
    XXTEMoreTitleValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Status", nil);
    cell2.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Expired At", nil);
    cell3.valueLabel.text = @"\n";
    cell3.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell3.valueLabel.numberOfLines = 2;
    
#ifdef DEBUG
    XXTEMoreLinkCell *linkCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLinkCell class]) owner:nil options:nil] lastObject];
    linkCell.titleLabel.text = NSLocalizedString(@"Buy License", nil);
    linkCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#endif
    
    XXTEMoreTitleValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Version", nil);
    cell4.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"iOS Version", nil);
    cell5.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Device Type", nil);
    cell6.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Device Name", nil);
    cell7.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"Serial Number", nil);
    cell8.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"MAC Address", nil);
    cell9.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell10.titleLabel.text = NSLocalizedString(@"Unique ID", nil);
    cell10.valueLabel.text = @"";
    
    staticCells = @[
                    @[ cell1 ],
                    //
#ifdef DEBUG
                    @[ cell2, cell3, linkCell ],
#else
                    @[ cell2, cell3, /* linkCell */ ],
#endif
                    //
                    @[ cell4, cell5, cell6, cell7, cell8, cell9, cell10 ]
                    ];
}

- (void)reloadDynamicTableViewDataWithCompletion:(XXTERefreshControlHandler)handler {
    NSDictionary *cachedLicense = XXTEDefaultsObject(kXXTEMoreLicenseCachedLicense, nil);
    if (cachedLicense)
    {
        [self updateLicenseDictionary:cachedLicense];
    }
    UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
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
            self.dataDictionary = dataDictionary;
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
        XXTEDefaultsSetObject(kXXTEMoreLicenseCachedLicense, licenseDictionary);
        [self updateLicenseDictionary:licenseDictionary];
    })
    .catch(^(NSError *serverError) {
        if (serverError.code == -1004) {
            toastMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
        } else {
            toastMessage(self, [serverError localizedDescription]);
        }
    })
    .finally(^() {
        blockInteractions(blockVC, NO);
        if (handler) {
            handler();
        }
    });
}

- (void)updateLicenseDictionary:(NSDictionary *)licenseDictionary {
    if ([licenseDictionary isKindOfClass:[NSDictionary class]] &&
        [licenseDictionary[@"code"] isKindOfClass:[NSNumber class]] &&
        [licenseDictionary[@"code"] isEqualToNumber:@0]) {
        NSDictionary *licenseData = licenseDictionary[@"data"];
        if ([licenseData isKindOfClass:[NSDictionary class]] &&
            [licenseData[@"expireDate"] isKindOfClass:[NSNumber class]] &&
            [licenseData[@"nowDate"] isKindOfClass:[NSNumber class]]
            ) {
            NSTimeInterval expirationInterval = [licenseData[@"expireDate"] doubleValue];
            NSTimeInterval nowInterval = [licenseData[@"nowDate"] doubleValue];
            [self updateCellExpirationTime:expirationInterval
                               nowInterval:nowInterval];
        }
    }
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
    if (trimedString.length != 12 && trimedString.length != 16) {
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
        if (indexPath.section == kXXTEMoreLicenseSectionIndexNewLicense) {
            if (indexPath.row == 0) {
                return 56.f;
            }
        }
        else if (indexPath.section == kXXTEMoreLicenseSectionIndexCurrentLicense) {
            if (indexPath.row == 0 || indexPath.row == 1) {
                return 66.f;
            }
        }
    }
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (tableView == self.tableView) {
        if (indexPath.section == kXXTEMoreLicenseSectionIndexDevice) {
            NSString *titleText =
            ((XXTEMoreTitleValueCell *)staticCells
             [(NSUInteger) indexPath.section]
             [(NSUInteger) indexPath.row])
            .titleLabel.text;
            NSString *detailText =
            ((XXTEMoreTitleValueCell *)staticCells
             [(NSUInteger) indexPath.section]
             [(NSUInteger) indexPath.row])
            .valueLabel.text;
            if (titleText && titleText.length > 0 &&
                detailText && detailText.length > 0) {
                @weakify(self);
                void (^copyBlock)(NSString *) = ^(NSString *textToCopy) {
                    @strongify(self);
                    UIViewController *blockVC = blockInteractionsWithDelay(self, YES, 2.0);
                    [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            [[UIPasteboard generalPasteboard] setString:textToCopy];
                            fulfill(nil);
                        });
                    }].finally(^() {
                        toastMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                        blockInteractions(blockVC, NO);
                    });
                };
                if (indexPath.row == kXXTEMoreLicenseDeviceRowIndexDeviceSerial ||
                    indexPath.row == kXXTEMoreLicenseDeviceRowIndexMacAddress ||
                    indexPath.row == kXXTEMoreLicenseDeviceRowIndexUDID) {
                    LGAlertView *copyAlert = [[LGAlertView alloc] initWithTitle:titleText message:detailText style:LGAlertViewStyleActionSheet buttonTitles:@[ NSLocalizedString(@"Copy", ni) ] cancelButtonTitle:NSLocalizedString(@"Cancel", ni;) destructiveButtonTitle:nil actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
                        [alertView dismissAnimated:YES completionHandler:^{
                            copyBlock(detailText);
                        }];
                    } cancelHandler:^(LGAlertView * _Nonnull alertView) {
                        [alertView dismissAnimated];
                    } destructiveHandler:nil];
                    [copyAlert showAnimated];
                } else {
                    copyBlock(detailText);
                }
            }
        }
        else if (indexPath.section == kXXTEMoreLicenseSectionIndexCurrentLicense) {
            NSString *titleText =
            ((XXTEMoreLinkCell *)staticCells
             [(NSUInteger) indexPath.section]
             [(NSUInteger) indexPath.row])
            .titleLabel.text;
            if (indexPath.row == 2) {
                NSString *urlString = uAppDefine(@"XXTOUCH_BUY_URL");
                if (urlString) {
                    NSURL *url = nil;
                    NSDictionary *dataDict = self.dataDictionary;
                    if (dataDict)
                    {
                        NSString *paraString = [dataDict stringFromQueryComponents];
                        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", urlString, paraString]];
                    } else {
                        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", urlString]];
                    }
                    XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURL:url];
                    webController.title = titleText;
                    [self.navigationController pushViewController:webController animated:YES];
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
    } else {
        textField.textColor = XXTE_COLOR;
    }
    if (trimedString.length == 12 || trimedString.length == 16) {
        self.doneButtonItem.enabled = YES;
    } else {
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
    NSString *trimmedString = [licenseCode stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSUInteger trimmedLength = trimmedString.length;
    NSString *upperedString = [trimmedString uppercaseString];
    NSMutableString *spacedString = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < upperedString.length; i++) {
        [spacedString appendString:[upperedString substringWithRange:NSMakeRange(i, 1)]];
        if ((i + 1) % 4 == 0 && (i != trimmedLength - 1)) {
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
    BOOL batchLicense = (licenseCode.length == 12);
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
            return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
                UIImage *cardImage = [self generateCardImageWithLicense:licenseDictionary];
                if (cardImage && NO == batchLicense) {
                    resolve(@[ licenseDictionary, cardImage ]);
                } else {
                    resolve(@[ licenseDictionary, [UIImage new] ]);
                }
            }];
        } else {
            @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot active license: %@", nil), licenseDictionary[@"message"]];
        }
        return [PMKPromise promiseWithValue:@[ @{}, [UIImage new] ]];
    })
    .then(^(NSArray *licenseData) {
        
        NSDictionary *licenseDictionary = licenseData[0];
        UIImage *licenseImage = licenseData[1];
        UIImageView *licenseImageView = [[UIImageView alloc] initWithImage:licenseImage];
        [licenseImageView setContentMode:UIViewContentModeScaleAspectFit];
        
        NSTimeInterval deviceExpirationInterval = [licenseDictionary[@"data"][@"deviceExpireDate"] doubleValue];
        // !!! You cannot use expireDate here !!!
        NSTimeInterval nowInterval = [licenseDictionary[@"data"][@"nowDate"] doubleValue];
        
        [self updateCellExpirationTime:deviceExpirationInterval
                           nowInterval:nowInterval];
        
        NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:nowInterval];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:XXTE_STANDARD_LOCALE]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        NSString *nowDateString = [dateFormatter stringFromDate:nowDate];
        
        // Add Animations
        XXTEShimmeringView *shimmeringView = nil;
        NSArray <NSString *> *buttonTitles = @[ ];
        LGAlertViewActionHandler actionHandler = nil;
        NSString *cancelButtonTitle = nil;
        if (NO == batchLicense) {
            shimmeringView = [[XXTEShimmeringView alloc] init];
            buttonTitles = @[ NSLocalizedString(@"Save to Camera Roll", nil) ];
            actionHandler = ^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
                shimmeringView.shimmering = NO;
                if (index == 0) {
                    self.licenseField.text = @"";
                    [self textFieldDidChange:self.licenseField];
                    [alertView dismissAnimated];
                    UIImageWriteToSavedPhotosAlbum(licenseImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                }
            };
        } else {
            cancelButtonTitle = NSLocalizedString(@"Dismiss", nil);
        }
        
        LGAlertView *cardAlertView = [[LGAlertView alloc] initWithViewAndTitle:NSLocalizedString(@"License Activated", nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"%@\nActivated At: %@", nil), licenseDictionary[@"message"], nowDateString]
                                                                         style:LGAlertViewStyleActionSheet
                                                                          view:shimmeringView
                                                                  buttonTitles:buttonTitles
                                                             cancelButtonTitle:cancelButtonTitle
                                                        destructiveButtonTitle:nil
                                                                 actionHandler:actionHandler
                                                                 cancelHandler:^ (LGAlertView *alert) {
                                                                     self.licenseField.text = @"";
                                                                     [self textFieldDidChange:self.licenseField];
                                                                     [alert dismissAnimated];
                                                                 }
                                                            destructiveHandler:nil];
        
        if (NO == batchLicense) {
            // Adjust Frame
            CGFloat imageRatio = 284.f / 450.f;
            CGFloat alertWidth = cardAlertView.width;
            CGFloat imageHeight = alertWidth * imageRatio;
            [licenseImageView setFrame:CGRectMake(0, 0, alertWidth, imageHeight)];
            [shimmeringView setFrame:licenseImageView.bounds];
            
            // Start shimmering.
            shimmeringView.shimmering = YES;
            shimmeringView.shimmeringSpeed = 150.;
            shimmeringView.shimmeringAnimationOpacity = .2;
            shimmeringView.contentView = licenseImageView;
        }
        
        if (alertView1 && alertView1.isShowing) {
            [alertView1 transitionToAlertView:cardAlertView completionHandler:nil];
        } else {
            [cardAlertView showAnimated];
        }
        
        NSString *licenseLog = [NSString stringWithFormat:@"[%@] %@\n", NSStringFromClass([self class]), licenseDictionary];
        return licenseLog;
    })
    .then(^(NSString *licenseLog) {
        if (licenseLog.length > 0) {
            NSString *licenseLogPath = uAppDefine(@"LICENSE_LOG_PATH");
            NSString *licenseLogFullPath = [[XXTEAppDelegate sharedRootPath] stringByAppendingPathComponent:licenseLogPath];
            struct stat licenseLogStat;
            if (0 != lstat([licenseLogFullPath UTF8String], &licenseLogStat)) {
                [[NSFileManager defaultManager] createFileAtPath:licenseLogFullPath
                                                        contents:[NSData data]
                                                      attributes:nil];
            }
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:licenseLogFullPath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[licenseLog dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
    })
    .catch(^(NSError *serverError) {
        LGAlertView *errorAlertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Operation Failed", nil)
                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"Failed to activate license \"%@\": %@", nil), licenseCode, [serverError localizedDescription]]
                                                                   style:LGAlertViewStyleActionSheet
                                                            buttonTitles:@[  ]
                                                       cancelButtonTitle:NSLocalizedString(@"Retry", nil)
                                                  destructiveButtonTitle:nil
                                                                delegate:self];
        if (alertView1 && alertView1.isShowing) {
            [alertView1 transitionToAlertView:errorAlertView completionHandler:nil];
        } else {
            [errorAlertView showAnimated];
        }
    })
    .finally(^() {
        
    });
}

#pragma mark - Reusable UI Updater

- (void)updateCellExpirationTime:(NSTimeInterval)expirationInterval nowInterval:(NSTimeInterval)nowInterval {
    XXTEMoreTitleValueCell *statusLabelCell = ((XXTEMoreTitleValueCell *)staticCells[1][0]);
    XXTEMoreTitleValueCell *timeLabelCell = ((XXTEMoreTitleValueCell *)staticCells[1][1]);
    
    int status = -1; // Activated
    NSString *displayDateString = nil;
    
    if (expirationInterval > 0) {
        
        NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:nowInterval];
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationInterval];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:XXTE_STANDARD_LOCALE]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd\nHH:mm:ss"];
        
        NSString *expirationDateString = [dateFormatter stringFromDate:expirationDate];
        
        NSTimeInterval interval = [nowDate timeIntervalSinceDate:expirationDate];
        
        status = interval;
        displayDateString = expirationDateString;
        
    } else {
        status = 0; // Outdated
        displayDateString = NSLocalizedString(@"N/A\n(Not Available)", nil);
    }
    UILabel *dateLabel = timeLabelCell.valueLabel;
    dateLabel.text = displayDateString;
    if (status >= 0) {
        statusLabelCell.valueLabel.text = NSLocalizedString(@"Outdated", nil);
        dateLabel.textColor = XXTE_COLOR_DANGER;
    }
    else {
        statusLabelCell.valueLabel.text = NSLocalizedString(@"Activated", nil);
        dateLabel.textColor = XXTE_COLOR;
    }
    [self.tableView reloadData];
}

- (UIImage *)generateCardImageWithLicense:(NSDictionary *)licenseDictionary {
    NSString *logPath = uAppDefine(@"LOG_PATH");
    NSString *logFullPath = [[XXTEAppDelegate sharedRootPath] stringByAppendingPathComponent:logPath];
    NSString *uuidString = [[NSUUID UUID] UUIDString];
    NSString *cardPath = [[logFullPath stringByAppendingPathComponent:uuidString] stringByAppendingPathExtension:@"pdf"];
    [self createSignaturedPDFWithLicense:(NSDictionary *)licenseDictionary atPath:cardPath];
    UIImage *cardImage = [self imageFromPDFAtURL:[NSURL fileURLWithPath:cardPath] forPage:1];
    return cardImage;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
}

- (UIImage *)createImagefromUIScrollView:(UIScrollView *)scrollView {
    CGFloat scale = [[UIScreen mainScreen] scale];
    UIGraphicsBeginImageContextWithOptions(scrollView.contentSize, YES, scale);
    CGContextRef imageContext = UIGraphicsGetCurrentContext();
    CGRect origSize = scrollView.frame;
    CGRect newSize = origSize;
    newSize.size = scrollView.contentSize;
    [scrollView setFrame:newSize];
    [scrollView.layer renderInContext:imageContext];
    [scrollView setFrame:origSize];
    UIImage *imageResult = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageResult;
}

- (void)createSignaturedPDFWithLicense:(NSDictionary *)licenseDictionary atPath:(NSString *)cardPath
{
    NSURL *previewURL = [[NSBundle mainBundle] URLForResource:@"XXTEPremiumPreview" withExtension:@"pdf"];
    
    CGFloat scale = 3.0;
    
    NSString *licenseCode = self.licenseField.text;
    UIFont *licenseFont = [UIFont fontWithName:@"Menlo-Regular" size:32.0 * scale];
    if (!licenseCode || !licenseFont) return;
    
    NSString *deviceSN = licenseDictionary[@"data"][@"deviceSerialNumber"];
    UIFont *deviceSNFont = [UIFont fontWithName:@"Menlo-Regular" size:14.0 * scale];
    if (!deviceSN || !deviceSNFont) return;
    
    NSTimeInterval nowInterval = [licenseDictionary[@"data"][@"nowDate"] doubleValue];
    NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:nowInterval];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:XXTE_STANDARD_LOCALE]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString *nowDateString = [dateFormatter stringFromDate:nowDate];
    
    NSTimeInterval expirationInterval = [licenseDictionary[@"data"][@"expireDate"] doubleValue];
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationInterval];
    
    NSTimeInterval interval = [expirationDate timeIntervalSinceDate:nowDate];
    NSMutableString *intervalString = [[NSMutableString alloc] init];
    int intervalDay = (int)floor(interval / 86400);
    if (intervalDay > 1)
    {
        [intervalString appendFormat:NSLocalizedString(@"%d Days ", nil), intervalDay];
    } else if (intervalDay == 1) {
        [intervalString appendFormat:NSLocalizedString(@"%d Day ", nil), intervalDay];
    }
    int intervalHour = (int)floor((interval - intervalDay * 86400) / 3600);
    if (intervalHour > 1) {
        [intervalString appendFormat:NSLocalizedString(@"%d Hours ", nil), intervalHour];
    } else if (intervalHour == 1) {
        [intervalString appendFormat:NSLocalizedString(@"%d Hour ", nil), intervalHour];
    }
    if (intervalString.length == 0) {
        [intervalString appendString:NSLocalizedString(@"Test", nil)];
    }
    
    NSString *nowString = [NSString stringWithFormat:@"%@ %@", nowDateString, intervalString];
    UIFont *nowFont = [UIFont fontWithName:@"Menlo-Regular" size:14.0 * scale];
    if (!nowString || !nowFont) return;
    
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((CFURLRef)previewURL);
    const size_t numberOfPages = CGPDFDocumentGetNumberOfPages(pdf);
    
    NSMutableData *data = [NSMutableData data];
    UIGraphicsBeginPDFContextToData(data, CGRectZero, nil);
    
    for (size_t page = 1; page <= numberOfPages; page++)
    {
        //	Get the current page and page frame
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdf, page);
        const CGRect pageFrame = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
        
        UIGraphicsBeginPDFPageWithInfo(pageFrame, nil);
        
        //	Draw the page (flipped)
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        CGContextScaleCTM(ctx, 1, -1);
        CGContextTranslateCTM(ctx, 0, -pageFrame.size.height);
        CGContextDrawPDFPage(ctx, pdfPage);
        CGContextRestoreGState(ctx);
        
        // Drawing commands
        NSDictionary *licenseCodeAttr = @{ NSFontAttributeName: licenseFont, NSForegroundColorAttributeName: [UIColor colorWithWhite:.92f alpha:1.f] };
        CGSize licenseSize = [licenseCode sizeWithAttributes:licenseCodeAttr];
        [licenseCode drawAtPoint:CGPointMake(pageFrame.size.width / 2.0 - licenseSize.width / 2.0, 197.0 * scale) withAttributes:licenseCodeAttr];
        
        NSDictionary *deviceSNAttr = @{ NSFontAttributeName: deviceSNFont, NSForegroundColorAttributeName: [UIColor colorWithWhite:1.f alpha:.33f] };
        CGSize deviceSNSize = [deviceSN sizeWithAttributes:deviceSNAttr];
        [deviceSN drawAtPoint:CGPointMake(pageFrame.size.width - 12.0 * scale - deviceSNSize.width, 256.0 * scale) withAttributes:deviceSNAttr];
        
        NSDictionary *nowAttr = @{ NSFontAttributeName: nowFont, NSForegroundColorAttributeName: [UIColor colorWithWhite:1.f alpha:.33f] };
        [nowString drawAtPoint:CGPointMake(12.0 * scale, 256.0 * scale) withAttributes:nowAttr];
        
    }
    
    UIGraphicsEndPDFContext();
    
    CGPDFDocumentRelease(pdf);
    pdf = nil;
    
    [data writeToFile:cardPath atomically:YES];
}

- (UIImage *)imageFromPDFAtURL:(NSURL *)url forPage:(NSUInteger)page {
    
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((CFURLRef)url);
    const size_t numberOfPages = CGPDFDocumentGetNumberOfPages(pdf);
    if (page > numberOfPages) {
        CGPDFDocumentRelease(pdf);
        return nil;
    }
    
    CGFloat scale = 0.0;
    
    CGPDFPageRef pdfPageRef = CGPDFDocumentGetPage(pdf, page);
    
    CGRect pageRect = CGPDFPageGetBoxRect(pdfPageRef, kCGPDFMediaBox);
    CGSize pageSize = pageRect.size;
    
    UIGraphicsBeginImageContextWithOptions(pageSize, NO, scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextTranslateCTM(context, 0.0, pageSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSaveGState(context);
    
    CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(pdfPageRef, kCGPDFCropBox, CGRectMake(0, 0, pageSize.width, pageSize.height), 0, true);
    CGContextConcatCTM(context, pdfTransform);
    
    CGContextDrawPDFPage(context, pdfPageRef);
    CGContextRestoreGState(context);
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGPDFDocumentRelease(pdf);
    pdf = nil;
    
    return resultingImage;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEMoreLicenseController dealloc]");
#endif
}

@end
