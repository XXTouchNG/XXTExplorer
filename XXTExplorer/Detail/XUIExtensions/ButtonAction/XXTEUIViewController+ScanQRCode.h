//
//  XXTEUIViewController+ScanQRCode.h
//  XXTExplorer
//
//  Created by Zheng on 20/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController.h"
#import "XXTEScanViewController.h"

@class XUIButtonCell;

@interface XXTEUIViewController (ScanQRCode) <XXTEScanViewControllerDelegate>

- (id)xui_ScanQRCode:(XUIButtonCell *)cell;

@end
