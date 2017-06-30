//
//  XXTExplorerNavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerNavigationController.h"
#import "XXTExplorerViewController.h"
#import "XXTENotificationCenterDefines.h"
#import "XXTEDispatchDefines.h"
#import "UIView+XXTEToast.h"

@interface XXTExplorerNavigationController ()

@end

@implementation XXTExplorerNavigationController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"My Scripts", nil) image:[UIImage imageNamed:@"XXTExplorerTabbarIcon"] tag:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeInbox])
    {
        NSURL *inboxURL = aNotification.object;
        @weakify(self);
        self.view.userInteractionEnabled = NO;
        [self.view makeToastActivity:XXTEToastPositionCenter];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            @strongify(self);
            NSError *err = nil;
            NSString *lastComponent = [inboxURL lastPathComponent];
            NSString *formerPath = [inboxURL path];
            NSString *currentPath = [XXTExplorerViewController rootPath];
            UIViewController *topViewController = self.topViewController;
            if ([topViewController isKindOfClass:[XXTExplorerViewController class]])
            {
                currentPath = ((XXTExplorerViewController *)topViewController).entryPath;
            }
            NSString *latterPath = [currentPath stringByAppendingPathComponent:lastComponent];
            BOOL result = [[NSFileManager defaultManager] moveItemAtPath:formerPath toPath:latterPath error:&err];
            dispatch_async_on_main_queue(^{
                [self.view hideToastActivity];
                self.view.userInteractionEnabled = YES;
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:nil userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeInboxMoved}]];
                if (result && err == nil) {
                    [self.view makeToast:[NSString stringWithFormat:NSLocalizedString(@"File \"%@\" saved.", nil), lastComponent]];
                } else {
                    [self.view makeToast:[err localizedDescription]];
                }
            });
        });
    }
}

@end
