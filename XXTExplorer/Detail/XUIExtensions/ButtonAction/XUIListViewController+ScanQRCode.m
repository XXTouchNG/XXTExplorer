//
//  XUIListViewController+ScanQRCode.m
//  XXTExplorer
//
//  Created by Zheng on 20/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIListViewController+ScanQRCode.h"

#import "XUIButtonCell.h"
#import "XXTEScanViewController.h"
#import "XXTEUserInterfaceDefines.h"

#import <objc/runtime.h>

@implementation XUIListViewController (ScanQRCode)

- (id)xui_ScanQRCode:(XUIButtonCell *)cell {
    XXTEScanViewController *scanViewController = [[XXTEScanViewController alloc] init];
    scanViewController.delegate = self;
    objc_setAssociatedObject(self, XUIButtonCellStorageKey, cell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scanViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
    return nil;
}

#pragma mark - Scan Results

- (void)scanViewController:(XXTEScanViewController *)controller urlOperation:(NSURL *)url {
    XUIBaseCell *cell = objc_getAssociatedObject(self, XUIButtonCellStorageKey);
    if ([cell isKindOfClass:[XUIButtonCell class]]) {
        cell.xui_value = [url absoluteString];
        [self.adapter saveDefaultsFromCell:cell];
        [controller dismissViewControllerAnimated:YES completion:^{
            toastMessage(self, NSLocalizedString(@"Scan result has been saved.", nil));
        }];
    }
    objc_setAssociatedObject(self, XUIButtonCellStorageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)scanViewController:(XXTEScanViewController *)controller textOperation:(NSString *)string {
    XUIBaseCell *cell = objc_getAssociatedObject(self, XUIButtonCellStorageKey);
    if ([cell isKindOfClass:[XUIButtonCell class]]) {
        cell.xui_value = string;
        [self.adapter saveDefaultsFromCell:cell];
        [controller dismissViewControllerAnimated:YES completion:^{
            toastMessage(self, NSLocalizedString(@"Scan result has been saved.", nil));
        }];
    }
    objc_setAssociatedObject(self, XUIButtonCellStorageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)scanViewController:(XXTEScanViewController *)controller jsonOperation:(NSDictionary *)jsonDictionary {
    XUIBaseCell *cell = objc_getAssociatedObject(self, XUIButtonCellStorageKey);
    if ([cell isKindOfClass:[XUIButtonCell class]]) {
        cell.xui_value = jsonDictionary;
        [self.adapter saveDefaultsFromCell:cell];
        [controller dismissViewControllerAnimated:YES completion:^{
            toastMessage(self, NSLocalizedString(@"Scan result has been saved.", nil));
        }];
    }
    objc_setAssociatedObject(self, XUIButtonCellStorageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
