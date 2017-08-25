//
//  XXTEMoreApplicationDetailController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#include <objc/runtime.h>
#import "XXTEMoreApplicationDetailController.h"
#import <LGAlertView/LGAlertView.h>
#import <PromiseKit/PromiseKit.h>
#import "LSApplicationWorkspace.h"
#import "NSURLConnection+PromiseKit.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreAddressCell.h"
#import "XXTEMoreActionCell.h"
#import "XXTENetworkDefines.h"

typedef enum : NSUInteger {
    kXXTEMoreApplicationDetailSectionIndexDetail = 0,
    kXXTEMoreApplicationDetailSectionIndexBundlePath,
    kXXTEMoreApplicationDetailSectionIndexContainerPath,
    kXXTEMoreApplicationDetailSectionIndexAction,
    kXXTEMoreApplicationDetailSectionIndexMax
} kXXTEMoreApplicationDetailSectionIndex;

@interface XXTEMoreApplicationDetailController () <LGAlertViewDelegate>
@property(nonatomic, strong, readonly) LSApplicationWorkspace *applicationWorkspace;

@end

@implementation XXTEMoreApplicationDetailController {
    NSArray <NSArray <UITableViewCell *> *> *staticCells;
    NSArray <NSString *> *staticSectionTitles;
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
    
    _applicationWorkspace = ({
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        SEL selector = NSSelectorFromString(@"defaultWorkspace");
        LSApplicationWorkspace *applicationWorkspace = [LSApplicationWorkspace_class performSelector:selector];
        applicationWorkspace;
    });
    
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    self.title = self.applicationDetail[kXXTEMoreApplicationDetailKeyName];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_SYSTEM_9) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    XXTE_END_IGNORE_PARTIAL
    
    [self reloadStaticTableViewData];
}

- (void)reloadStaticTableViewData {
    staticSectionTitles = @[ NSLocalizedString(@"Detail", nil),
                             NSLocalizedString(@"Bundle Path", nil),
                             NSLocalizedString(@"Container Path", nil),
                             NSLocalizedString(@"Actions", nil) ];
    
    XXTEMoreTitleValueCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Name", nil);
    cell1.valueLabel.text = self.applicationDetail[kXXTEMoreApplicationDetailKeyName];
    
    XXTEMoreTitleValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Bundle ID", nil);
    cell2.valueLabel.text = self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID];
    
    XXTEMoreAddressCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    cell3.addressLabel.text = self.applicationDetail[kXXTEMoreApplicationDetailKeyBundlePath];
    
    XXTEMoreAddressCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    NSString *containerPath = self.applicationDetail[kXXTEMoreApplicationDetailKeyContainerPath];
    if (!containerPath || containerPath.length <= 0) {
        containerPath = @"/private/var/mobile";
    }
    cell4.addressLabel.text = containerPath;
    
    XXTEMoreActionCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreActionCell class]) owner:nil options:nil] lastObject];
    cell5.actionNameLabel.textColor = XXTE_COLOR_SUCCESS;
    cell5.actionNameLabel.text = NSLocalizedString(@"Launch Application", nil);
    
    XXTEMoreActionCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreActionCell class]) owner:nil options:nil] lastObject];
    cell6.actionNameLabel.textColor = XXTE_COLOR_DANGER;
    cell6.actionNameLabel.text = NSLocalizedString(@"Clean GPS Caches", nil);
    
    XXTEMoreActionCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreActionCell class]) owner:nil options:nil] lastObject];
    cell7.actionNameLabel.textColor = XXTE_COLOR_DANGER;
    cell7.actionNameLabel.text = NSLocalizedString(@"Clean Application Data", nil);
    
    staticCells = @[
                    @[ cell1, cell2 ],
                    //
                    @[ cell3 ],
                    //
                    @[ cell4 ],
                    //
                    @[ cell5, cell6, cell7 ]
                    ];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return kXXTEMoreApplicationDetailSectionIndexMax;
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
        if (indexPath.section == kXXTEMoreApplicationDetailSectionIndexDetail) {
            NSString *detailText = ((XXTEMoreTitleValueCell *)staticCells[indexPath.section][indexPath.row]).valueLabel.text;
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
        } else if (indexPath.section == kXXTEMoreApplicationDetailSectionIndexBundlePath || indexPath.section == kXXTEMoreApplicationDetailSectionIndexContainerPath) {
            NSString *detailText = ((XXTEMoreAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
            if (detailText && detailText.length > 0) {
                blockUserInteractions(self, YES, 2.0);
                [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                        [[UIPasteboard generalPasteboard] setString:detailText];
                        fulfill(nil);
                    });
                }].finally(^() {
                    showUserMessage(self, NSLocalizedString(@"Path has been copied to the pasteboard.", nil));
                    blockUserInteractions(self, NO, 2.0);
                });
            }
        } else if (indexPath.section == kXXTEMoreApplicationDetailSectionIndexAction) {
            if (indexPath.row == 0) {
                [self.applicationWorkspace openApplicationWithBundleID:self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID]];
            }
            else if (indexPath.row == 1) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clean GPS Caches", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Clean the GPS caches of the application \"%@\"?\nThis operation cannot be revoked.", nil), self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID]]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clean Now", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:cleanApplicationGPSCaches:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
            }
            else if (indexPath.row == 2) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clean Application Data", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Clean all the data of the application \"%@\"?\nThis operation cannot be revoked.", nil), self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID]]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[  ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clean Now", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:cleanApplicationData:), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return staticCells[indexPath.section][indexPath.row];
    }
    return [UITableViewCell new];
}

#pragma mark - LGAlertViewDelegate

- (void)alertViewDestructed:(LGAlertView *)alertView {
    SEL selectors[] = {
        @selector(alertView:cleanApplicationData:),
        @selector(alertView:cleanApplicationGPSCaches:)
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

- (void)alertView:(LGAlertView *)alertView cleanApplicationGPSCaches:(id)obj {
    blockUserInteractions(self, YES, 2.0);
    [alertView dismissAnimated:YES completionHandler:^{
        [NSURLConnection POST:uAppDaemonCommandUrl(@"clear_gps") JSON:@{ @"bid": self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID] }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Clean succeed: %@", nil), jsonDictionary[@"message"]]);
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Clean failed: %@", nil), jsonDictionary[@"message"]];
            }
        }).catch(^(NSError *serverError) {
            if (serverError.code == -1004) {
                showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                showUserMessage(self, [serverError localizedDescription]);
            }
        }).finally(^() {
            blockUserInteractions(self, NO, 2.0);
        });
    }];
}

- (void)alertView:(LGAlertView *)alertView cleanApplicationData:(id)obj {
    blockUserInteractions(self, YES, 2.0);
    [alertView dismissAnimated:YES completionHandler:^{
        [NSURLConnection POST:uAppDaemonCommandUrl(@"clear_app_data") JSON:@{ @"bid": self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID] }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Clean succeed: %@", nil), jsonDictionary[@"message"]]);
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Clean failed: %@", nil), jsonDictionary[@"message"]];
            }
        }).catch(^(NSError *serverError) {
            if (serverError.code == -1004) {
                showUserMessage(self, NSLocalizedString(@"Could not connect to the daemon.", nil));
            } else {
                showUserMessage(self, [serverError localizedDescription]);
            }
        }).finally(^() {
            blockUserInteractions(self, NO, 2.0);
        });
    }];
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"[XXTEMoreApplicationDetailController dealloc]");
#endif
}

@end
