//
//  XUIListViewController+ScanQRCode.h
//  XXTExplorer
//
//  Created by Zheng on 20/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIListViewController.h"
#import "XXTEScanViewController.h"

@class XUIButtonCell;

@interface XUIListViewController (ScanQRCode) <XXTEScanViewControllerDelegate>

- (id)xui_ScanQRCode:(XUIButtonCell *)cell;

@end
