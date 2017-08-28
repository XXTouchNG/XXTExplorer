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
#import "XXTENetworkDefines.h"
#import "XXTEViewShaker.h"
#import "XXTExplorerViewController.h"

#import "XXTEShimmeringView.h"

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
    staticSectionFooters = @[ NSLocalizedString(@"Enter your 16-digit license code and tap \"Done\" to activate the license and bind it to current device.\nLicense code only contains 3-9 and A-Z, spaces are not included.\nThe content displayed in this page cannot be the proof of your purchase.", nil), @"", @"" ];
    
    XXTEMoreLicenseCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreLicenseCell class]) owner:nil options:nil] lastObject];
    cell1.licenseField.text = @"";
    cell1.licenseField.delegate = self;
    self.licenseField = cell1.licenseField;
    self.licenseShaker = [[XXTEViewShaker alloc] initWithView:self.licenseField];
    
    NSString *initialLicenseCode = self.licenseCode;
    if (initialLicenseCode.length > 0) {
        if ([self isValidLicenseFormat:initialLicenseCode]) {
            cell1.licenseField.text = [self formatLicense:initialLicenseCode];
            [self textFieldDidChange:cell1.licenseField];
        } else {
            showUserMessage(self, NSLocalizedString(@"Cannot autofill license field: Invalid license code.", nil));
        }
    }
    
    XXTEMoreTitleValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Status", nil);
    cell2.valueLabel.text = @"";
    
    XXTEMoreTitleValueCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell3.titleLabel.text = NSLocalizedString(@"Expired At", nil);
    cell3.valueLabel.text = @"\n";
    
    XXTEMoreTitleValueCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell4.titleLabel.text = NSLocalizedString(@"Version", nil);
    cell4.valueLabel.text = @"";
    cell4.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell5.titleLabel.text = NSLocalizedString(@"iOS Version", nil);
    cell5.valueLabel.text = @"";
    cell5.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell6.titleLabel.text = NSLocalizedString(@"Device Type", nil);
    cell6.valueLabel.text = @"";
    cell6.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell7.titleLabel.text = NSLocalizedString(@"Device Name", nil);
    cell7.valueLabel.text = @"";
    cell7.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell8 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell8.titleLabel.text = NSLocalizedString(@"Serial Number", nil);
    cell8.valueLabel.text = @"";
    cell8.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell9 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell9.titleLabel.text = NSLocalizedString(@"MAC Address", nil);
    cell9.valueLabel.text = @"";
    cell9.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    XXTEMoreTitleValueCell *cell10 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell10.titleLabel.text = NSLocalizedString(@"Unique ID", nil);
    cell10.valueLabel.text = @"";
    cell10.valueLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    staticCells = @[
                    @[ cell1 ],
                    //
                    @[ cell2, cell3 ],
                    //
                    @[ cell4, cell5, cell6, cell7, cell8, cell9, cell10 ]
                    ];
}

- (void)reloadDynamicTableViewDataWithCompletion:(XXTERefreshControlHandler)handler {
    blockUserInteractions(self, YES, 2.0);
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
            [self updateCellExpirationTime:expirationInterval
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
        blockUserInteractions(self, NO, 2.0);
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
                blockUserInteractions(self, YES, 2.0);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    showUserMessage(self, NSLocalizedString(@"Copied to the pasteboard.", nil));
                    blockUserInteractions(self, NO, 2.0);
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
    if (licenseCode.length <= 0)
        return NO;
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
            return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
                UIImage *cardImage = [self generateCardImage];
                if (cardImage) {
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
        
        NSTimeInterval expirationInterval = [licenseDictionary[@"data"][@"deviceExpireDate"] doubleValue];
        NSTimeInterval nowInterval = [licenseDictionary[@"data"][@"nowDate"] doubleValue];
        
        [self updateCellExpirationTime:expirationInterval
                           nowInterval:nowInterval];
        
        NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:nowInterval];
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationInterval];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        NSString *expirationDateString = [dateFormatter stringFromDate:expirationDate];
        NSString *nowDateString = [dateFormatter stringFromDate:nowDate];
        
        // Add Animations
        XXTEShimmeringView *shimmeringView = [[XXTEShimmeringView alloc] init];
        
        LGAlertViewActionHandler actionHandler = ^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
            shimmeringView.shimmering = NO;
            if (index == 0) {
                self.licenseField.text = @"";
                [self textFieldDidChange:self.licenseField];
                [alertView dismissAnimated];
                UIImageWriteToSavedPhotosAlbum(licenseImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            }
        };
        
        LGAlertView *cardAlertView = [[LGAlertView alloc] initWithViewAndTitle:NSLocalizedString(@"License Activated", nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"%@\nActivated At: %@\nExpired At: %@", nil), licenseDictionary[@"message"], nowDateString, expirationDateString]
                                                                         style:LGAlertViewStyleActionSheet
                                                                          view:shimmeringView
                                                                  buttonTitles:@[ NSLocalizedString(@"Save to Camera Roll", nil) ]
                                                             cancelButtonTitle:nil
                                                        destructiveButtonTitle:nil
                                                                 actionHandler:actionHandler
                                                                 cancelHandler:nil
                                                            destructiveHandler:nil];
        
        // Adjust Frame
        CGFloat imageRatio = 284.f / 450.f;
        CGFloat alertWidth = cardAlertView.width;
        CGFloat imageHeight = alertWidth * imageRatio;
        [licenseImageView setFrame:CGRectMake(0, 0, alertWidth, imageHeight)];
        [shimmeringView setFrame:licenseImageView.bounds];
        
        // Start shimmering.
        shimmeringView.shimmering = YES;
        shimmeringView.shimmeringBeginFadeDuration = .2;
        shimmeringView.shimmeringSpeed = 150.;
        shimmeringView.shimmeringAnimationOpacity = .2;
        shimmeringView.contentView = licenseImageView;
        
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
            if (0 == lstat([licenseLogFullPath UTF8String], &licenseLogStat)) {
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
    if (expirationInterval > 0) {
        XXTEMoreTitleValueCell *statusLabelCell = ((XXTEMoreTitleValueCell *)staticCells[1][0]);
        XXTEMoreTitleValueCell *timeLabelCell = ((XXTEMoreTitleValueCell *)staticCells[1][1]);
        NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:nowInterval];
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSince1970:expirationInterval];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd\nHH:mm:ss"];
        NSString *expirationDateString = [dateFormatter stringFromDate:expirationDate];
        UILabel *dateLabel = timeLabelCell.valueLabel;
        dateLabel.text = expirationDateString;
        if ([nowDate timeIntervalSinceDate:expirationDate] >= 0) {
            statusLabelCell.valueLabel.text = NSLocalizedString(@"Outdated", nil);
            dateLabel.textColor = XXTE_COLOR_DANGER;
        }
        else {
            statusLabelCell.valueLabel.text = NSLocalizedString(@"Activated", nil);
            dateLabel.textColor = XXTE_COLOR;
        }
        [self.tableView reloadData];
    }
}

- (UIImage *)generateCardImage {
    NSString *logPath = uAppDefine(@"LOG_PATH");
    NSString *logFullPath = [[XXTEAppDelegate sharedRootPath] stringByAppendingPathComponent:logPath];
    NSString *uuidString = [[NSUUID UUID] UUIDString];
    NSString *cardPath = [[logFullPath stringByAppendingPathComponent:uuidString] stringByAppendingPathExtension:@"pdf"];
    [self createSignaturedPDFLicenseAtPath:cardPath];
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

- (void)createSignaturedPDFLicenseAtPath:(NSString *)cardPath
{
    NSURL *previewURL = [[NSBundle mainBundle] URLForResource:@"XXTEPremiumPreview" withExtension:@"pdf"];
    
    CGFloat scale = 3.0;
    
    NSString *licenseCode = self.licenseField.text;
    UIFont *licenseFont = [UIFont fontWithName:@"CamingoCode-Regular" size:36.0 * scale];
    
    NSString *deviceSN = ((XXTEMoreTitleValueCell *)staticCells[2][4]).valueLabel.text;
    UIFont *deviceSNFont = [UIFont fontWithName:@"CamingoCode-Regular" size:14.0 * scale];
    
    NSString *expirationString = [((XXTEMoreTitleValueCell *)staticCells[1][1]).valueLabel.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    UIFont *expirationFont = [UIFont fontWithName:@"CamingoCode-Regular" size:14.0 * scale];
    
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
        [licenseCode drawAtPoint:CGPointMake(37.0 * scale, 197.0 * scale) withAttributes:@{ NSFontAttributeName: licenseFont, NSForegroundColorAttributeName: [UIColor colorWithWhite:.92f alpha:1.f] }];
        [deviceSN drawAtPoint:CGPointMake(345.0 * scale, 256.0 * scale) withAttributes:@{ NSFontAttributeName: deviceSNFont, NSForegroundColorAttributeName: [UIColor colorWithWhite:1.f alpha:.33f] }];
        [expirationString drawAtPoint:CGPointMake(12.0 * scale, 256.0 * scale) withAttributes:@{ NSFontAttributeName: expirationFont, NSForegroundColorAttributeName: [UIColor colorWithWhite:1.f alpha:.33f] }];
        
    }
    
    UIGraphicsEndPDFContext();
    
    CGPDFDocumentRelease(pdf);
    pdf = nil;
    
    [data writeToFile:cardPath atomically:YES];
}

- (UIImage *)imageFromPDFAtURL:(NSURL *)url forPage:(NSUInteger)page {
    
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((CFURLRef)url);
    const size_t numberOfPages = CGPDFDocumentGetNumberOfPages(pdf);
    if (page > numberOfPages) return nil;
    
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
    
    return resultingImage;
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreLicenseController dealloc]");
#endif
}

@end
