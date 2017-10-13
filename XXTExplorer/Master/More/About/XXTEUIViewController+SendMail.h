//
//  XXTEUIViewController+SendMail.h
//  XXTExplorer
//
//  Created by Zheng Wu on 13/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController.h"
#import <MessageUI/MFMailComposeViewController.h>

@class XUIButtonCell;

@interface XXTEUIViewController (SendMail) <MFMailComposeViewControllerDelegate>

- (NSNumber *)xui_SendMail:(XUIButtonCell *)cell;

@end
