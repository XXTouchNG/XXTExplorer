//
//  XXTEMoreApplicationDetailController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 30/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMoreApplicationDetailController.h"
#import <LGAlertView/LGAlertView.h>
#import <PromiseKit/PromiseKit.h>
#import "LSApplicationWorkspace.h"
#import "NSURLConnection+PromiseKit.h"
#import "XXTEMoreTitleValueCell.h"
#import "XXTEMoreAddressCell.h"
#import "XXTEMoreActionCell.h"


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
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.tableView.style == UITableViewStylePlain) {
        self.view.backgroundColor = XXTColorPlainBackground();
    } else {
        self.view.backgroundColor = XXTColorGroupedBackground();
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    _applicationWorkspace = ({
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        SEL selector = NSSelectorFromString(@"defaultWorkspace");
        LSApplicationWorkspace *applicationWorkspace = [LSApplicationWorkspace_class performSelector:selector];
        applicationWorkspace;
    });
#pragma clang diagnostic pop
    
    XXTE_START_IGNORE_PARTIAL
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    XXTE_END_IGNORE_PARTIAL
    
    NSString *controllerTitle = self.applicationDetail[kXXTEMoreApplicationDetailKeyName];
    if (controllerTitle.length == 0) {
        controllerTitle = self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID];
    }
    if (controllerTitle.length == 0) {
        controllerTitle = @"(null)";
    }
    
    self.title = controllerTitle;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    XXTE_START_IGNORE_PARTIAL
    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    XXTE_END_IGNORE_PARTIAL
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    
    [self reloadStaticTableViewData];
}

- (void)reloadStaticTableViewData {
    NSMutableArray <NSString *> *sectionTitles = [NSMutableArray arrayWithArray:@[
        NSLocalizedString(@"Detail", nil),
        NSLocalizedString(@"Bundle Path", nil),
        NSLocalizedString(@"Data Container Path", nil)
    ]];
    staticSectionTitles = sectionTitles;
    
    NSMutableArray <NSArray <UITableViewCell *> *> *sectionCells = [NSMutableArray array];
    staticCells = sectionCells;
    
    XXTEMoreTitleValueCell *cell1 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell1.titleLabel.text = NSLocalizedString(@"Name", nil);
    
    NSString *applicationName = self.applicationDetail[kXXTEMoreApplicationDetailKeyName];
    if (applicationName.length == 0) {
        applicationName = @"(null)";
    }
    cell1.valueLabel.text = applicationName;
    
    XXTEMoreTitleValueCell *cell2 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreTitleValueCell class]) owner:nil options:nil] lastObject];
    cell2.titleLabel.text = NSLocalizedString(@"Bundle ID", nil);
    
    NSString *applicationBundleID = self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID];
    if (applicationBundleID.length == 0) {
        applicationBundleID = @"(null)";
    }
    cell2.valueLabel.text = applicationBundleID;
    
    [sectionCells addObject:@[ cell1, cell2 ]];
    
    XXTEMoreAddressCell *cell3 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    NSString *bundlePath = self.applicationDetail[kXXTEMoreApplicationDetailKeyBundlePath];
    if (!bundlePath || bundlePath.length <= 0) {
        bundlePath = @"(null)";
    }
    cell3.addressLabel.text = bundlePath;
    
    [sectionCells addObject:@[ cell3 ]];
    
    XXTEMoreAddressCell *cell4 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
    NSString *containerPath = self.applicationDetail[kXXTEMoreApplicationDetailKeyDataContainerPath];
    if (!containerPath || containerPath.length <= 0) {
        containerPath = NSLocalizedString(@"/private/var/mobile", nil);
    }
    cell4.addressLabel.text = containerPath;
    
    [sectionCells addObject:@[ cell4 ]];
    
    NSDictionary <NSString *, NSString *> *groupContainerPaths = self.applicationDetail[kXXTEMoreApplicationDetailKeyGroupContainerPaths];
    NSArray <NSString *> *groupContainerIDs = [[groupContainerPaths allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    for (NSString *groupContainerID in groupContainerIDs) {
        [sectionTitles addObject:groupContainerID];
        
        XXTEMoreAddressCell *groupCell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreAddressCell class]) owner:nil options:nil] lastObject];
        groupCell.addressLabel.text = groupContainerPaths[groupContainerID];
        [sectionCells addObject:@[ groupCell ]];
    }
    
    [sectionTitles addObject:NSLocalizedString(@"Actions", nil)];
    
    XXTEMoreActionCell *cell5 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreActionCell class]) owner:nil options:nil] lastObject];
    cell5.actionNameLabel.textColor = XXTColorSuccess();
    cell5.actionNameLabel.text = NSLocalizedString(@"Launch Application", nil);
    
    XXTEMoreActionCell *cell6 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreActionCell class]) owner:nil options:nil] lastObject];
    cell6.actionNameLabel.textColor = XXTColorDanger();
    cell6.actionNameLabel.text = NSLocalizedString(@"Clean GPS Caches", nil);
    
    XXTEMoreActionCell *cell7 = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([XXTEMoreActionCell class]) owner:nil options:nil] lastObject];
    cell7.actionNameLabel.textColor = XXTColorDanger();
    cell7.actionNameLabel.text = NSLocalizedString(@"Clean Application Data", nil);
    
    [sectionCells addObject:@[ cell5, cell6, cell7 ]];
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return staticSectionTitles.count;
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
    return 44.f;
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
        if (indexPath.section == 0) {
            NSString *detailText = ((XXTEMoreTitleValueCell *)staticCells[indexPath.section][indexPath.row]).valueLabel.text;
            if (detailText && detailText.length > 0) {
                UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 1.0);
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
        } else if (indexPath.section == staticSectionTitles.count - 1) {
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
        } else if ([staticCells[indexPath.section][indexPath.row] isKindOfClass:[XXTEMoreAddressCell class]]) {
            NSString *detailText = ((XXTEMoreAddressCell *)staticCells[indexPath.section][indexPath.row]).addressLabel.text;
            if (detailText && detailText.length > 0) {
                UIViewController *blockVC = blockInteractionsWithToastAndDelay(self, YES, YES, 1.0);
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
    UIViewController *blockVC = blockInteractions(self, YES);
    [alertView dismissAnimated:YES completionHandler:^{
        [NSURLConnection POST:uAppDaemonCommandUrl(@"clear_gps") JSON:@{ @"bid": self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID] }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Clean succeed: %@", nil), jsonDictionary[@"message"]]));
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Clean failed: %@", nil), jsonDictionary[@"message"]];
            }
        }).catch(^(NSError *serverError) {
            toastDaemonError(self, serverError);
        }).finally(^() {
            blockInteractions(blockVC, NO);
        });
    }];
}

- (void)alertView:(LGAlertView *)alertView cleanApplicationData:(id)obj {
    UIViewController *blockVC = blockInteractions(self, YES);
    [alertView dismissAnimated:YES completionHandler:^{
        [NSURLConnection POST:uAppDaemonCommandUrl(@"clear_app_data") JSON:@{ @"bid": self.applicationDetail[kXXTEMoreApplicationDetailKeyBundleID] }].then(convertJsonString).then(^(NSDictionary *jsonDictionary) {
            if ([jsonDictionary[@"code"] isEqualToNumber:@0]) {
                toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Clean succeed: %@", nil), jsonDictionary[@"message"]]));
            } else {
                @throw [NSString stringWithFormat:NSLocalizedString(@"Clean failed: %@", nil), jsonDictionary[@"message"]];
            }
        }).catch(^(NSError *serverError) {
            toastDaemonError(self, serverError);
        }).finally(^() {
            blockInteractions(blockVC, NO);
        });
    }];
}

- (void)alertViewCancelled:(LGAlertView *)alertView {
    [alertView dismissAnimated];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
