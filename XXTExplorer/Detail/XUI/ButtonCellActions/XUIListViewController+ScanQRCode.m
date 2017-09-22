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

@implementation XUIListViewController (ScanQRCode)

- (id)xui_ScanQRCode:(XUIButtonCell *)cell {
    XXTEScanViewController *scanViewController = [[XXTEScanViewController alloc] init];
    scanViewController.delegate = self;
    self.pickerCell = cell;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scanViewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
    return nil;
}

#pragma mark - Scan Results

- (void)scanViewController:(XXTEScanViewController *)controller urlOperation:(NSURL *)url {
    XUIBaseCell *cell = self.pickerCell;
    if ([cell isKindOfClass:[XUIButtonCell class]]) {
        cell.xui_value = [url absoluteString];
        [self.adapter saveDefaultsFromCell:cell];
        [controller dismissViewControllerAnimated:YES completion:^{
            showUserMessage(self, NSLocalizedString(@"Scan result has been saved.", nil));
        }];
    }
    self.pickerCell = nil;
}

- (void)scanViewController:(XXTEScanViewController *)controller textOperation:(NSString *)string {
    XUIBaseCell *cell = self.pickerCell;
    if ([cell isKindOfClass:[XUIButtonCell class]]) {
        cell.xui_value = string;
        [self.adapter saveDefaultsFromCell:cell];
        [controller dismissViewControllerAnimated:YES completion:^{
            showUserMessage(self, NSLocalizedString(@"Scan result has been saved.", nil));
        }];
    }
    self.pickerCell = nil;
}

- (void)scanViewController:(XXTEScanViewController *)controller jsonOperation:(NSDictionary *)jsonDictionary {
    XUIBaseCell *cell = self.pickerCell;
    if ([cell isKindOfClass:[XUIButtonCell class]]) {
        cell.xui_value = jsonDictionary;
        [self.adapter saveDefaultsFromCell:cell];
        [controller dismissViewControllerAnimated:YES completion:^{
            showUserMessage(self, NSLocalizedString(@"Scan result has been saved.", nil));
        }];
    }
    self.pickerCell = nil;
}

@end
