//
//  XXTExplorerNavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 26/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerNavigationController.h"
#import "XXTExplorerViewController.h"

#import "XXTEUserInterfaceDefines.h"
#import "XXTENotificationCenterDefines.h"
#import "XXTEDispatchDefines.h"

#import "XXTExplorerViewController+SharedInstance.h"

@interface XXTExplorerNavigationController ()

@end

@implementation XXTExplorerNavigationController

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.translucent = NO;
    
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"My Scripts", nil) image:[UIImage imageNamed:@"XXTExplorerTabbarIcon"] tag:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotification:) name:XXTENotificationEvent object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)handleApplicationNotification:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeInbox])
    {
        NSURL *inboxURL = aNotification.object;
        @weakify(self);
        blockInteractionsWithDelay(self, YES, 0);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @strongify(self);
            NSError *err = nil;
            NSString *lastComponent = [inboxURL lastPathComponent];
            NSString *formerPath = [inboxURL path];
            NSString *currentPath = XXTExplorerViewController.initialPath;
            UIViewController *topViewController = self.topViewController;
            if ([topViewController isKindOfClass:[XXTExplorerViewController class]])
            {
                currentPath = ((XXTExplorerViewController *)topViewController).entryPath;
            }
            NSString *lastComponentName = [lastComponent stringByDeletingPathExtension];
            NSString *lastComponentExt = [lastComponent pathExtension];
            NSString *testedPath = [currentPath stringByAppendingPathComponent:lastComponent];
            NSUInteger testedIndex = 2;
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            while ([fileManager fileExistsAtPath:testedPath]) {
                lastComponent = [[NSString stringWithFormat:@"%@-%lu", lastComponentName, (unsigned long)testedIndex] stringByAppendingPathExtension:lastComponentExt];
                testedPath = [currentPath stringByAppendingPathComponent:lastComponent];
                testedIndex++;
            }
            BOOL result = [[NSFileManager defaultManager] moveItemAtPath:formerPath toPath:testedPath error:&err];
            dispatch_async_on_main_queue(^{
                blockInteractions(self, NO);
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



- (void)dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
