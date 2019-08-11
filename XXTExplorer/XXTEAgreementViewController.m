//
//  XXTEAgreementViewController.m
//  XXTExplorer
//
//  Created by Zheng on 2018/5/31.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTEAgreementViewController.h"
#import "XXTEAppDelegate.h"

#import <LGAlertView/LGAlertView.h>
#import <XUI/XUIListFooterView.h>

@interface XXTEAgreementViewController ()

@property (nonatomic, strong) UIBarButtonItem *quitItem;
@property (nonatomic, strong) UIBarButtonItem *agreeItem;
@property (nonatomic, assign) NSTimeInterval appearTime;

@end

@implementation XXTEAgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.quitItem;
    self.navigationItem.rightBarButtonItem = self.agreeItem;
    
    self.footerView.footerIcon = [[UIImage imageNamed:@"XUIAboutIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _appearTime = [[NSDate date] timeIntervalSince1970];
}

#pragma mark - Getter

- (UIBarButtonItem *)quitItem {
    if (!_quitItem) {
        _quitItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Quit", nil) style:UIBarButtonItemStylePlain target:self action:@selector(quitItemTapped:)];
    }
    return _quitItem;
}

- (UIBarButtonItem *)agreeItem {
    if (!_agreeItem) {
        _agreeItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Agree", nil) style:UIBarButtonItemStyleDone target:self action:@selector(agreeItemTapped:)];
    }
    return _agreeItem;
}

#pragma mark - Actions

- (void)quitItemTapped:(UIBarButtonItem *)sender {
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Quit Confirm", nil) message:NSLocalizedString(@"Do you want to quit XXTouch? \nIf you do not agree to our \"Terms Of Service\", you cannot continue using our application.", nil) style:LGAlertViewStyleAlert buttonTitles:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Quit Now", nil) actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
        [self ExitImmediately];
    }];
    [alertView showAnimated];
}

- (void)ExitImmediately {
    exit(0);
}

- (void)agreeItemTapped:(UIBarButtonItem *)sender {
    NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
    if (nowTime - self.appearTime < 5.0)
    {
        NSTimeInterval timeLeft = round(5.0 - (nowTime - self.appearTime));
        int secRemain = (int)timeLeft;
        if (secRemain < 1)
            secRemain = 1;
        toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Please read our \"Terms Of Service\" for more than 5 seconds, %ld seconds left.", nil), secRemain]);
        return;
    }
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm", nil) message:NSLocalizedString(@"I Agree To \"Terms Of Service (XXTouch)\".", nil) style:LGAlertViewStyleAlert buttonTitles:@[ NSLocalizedString(@"I Agree", nil) ] cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
        [alertView dismissAnimated];
        [self AgreeImmediately];
    } cancelHandler:^(LGAlertView * _Nonnull alertView) {
        [alertView dismissAnimated];
    } destructiveHandler:nil];
    [alertView showAnimated];
}

- (void)AgreeImmediately {
    XXTEAppDelegate *delegate = (XXTEAppDelegate *)[UIApplication sharedApplication].delegate;
    if (![delegate isKindOfClass:[XXTEAppDelegate class]]) {
        return;
    }
    [delegate reloadWorkspace];
}

#pragma mark - Style

- (NSString *)title {
    return NSLocalizedString(@"Terms Of Service (XXTouch)", nil);
}

- (UIColor *)preferredNavigationBarColor {
    return XXTColorBarTint();
}

- (UIColor *)preferredNavigationBarTintColor {
    return [UIColor whiteColor];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
