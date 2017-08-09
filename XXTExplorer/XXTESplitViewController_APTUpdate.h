//
//  XXTESplitViewController+APTUpdate.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/9.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTESplitViewController.h"

#import "XXTEAPTHelper.h"
#import "XXTEAPTPackage.h"
#import "XXTEUpdateReminder.h"
#import <LGAlertView/LGAlertView.h>

@interface XXTESplitViewController () <XXTEAPTHelperDelegate, XXTEUpdateReminderDelegate, LGAlertViewDelegate>

@property (nonatomic, strong) NSString *packageIdentifier;
@property (nonatomic, strong) XXTEAPTHelper *aptHelper;
@property (nonatomic, strong) XXTEUpdateReminder *updateReminder;
- (void)setupAPT;
- (void)checkUpdate;

@end
