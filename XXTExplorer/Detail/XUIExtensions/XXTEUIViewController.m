//
//  XXTEUIViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 09/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController.h"
#import "XXTEMasterViewController.h"

#import "XUIEntryReader.h"
#import <XUI/XUIListFooterView.h>

#import <XUI/XUI.h>
#import <XUI/XUICellFactory.h>
#import <XUI/XUIStrings.h>

#import <LGAlertView/LGAlertView.h>

// to listen
static CFStringRef const XUICallbackUIUpdated = CFSTR("com.xxtouch.XUICallbackUIUpdated");
static CFStringRef const XUICallbackValueChanged = CFSTR("com.xxtouch.XUICallbackValueChanged");

// to post
static CFStringRef const XUIEventValueChanged = CFSTR("com.xxtouch.XUIEventValueChanged");
//static CFStringRef const XUIEventUIUpdated = CFSTR("com.xxtouch.XUIEventUIUpdated");

//static CFStringRef const XUIEventViewDidAppear = CFSTR("com.xxtouch.XUIEventViewDidAppear");
//static CFStringRef const XUIEventViewDidDisappear = CFSTR("com.xxtouch.XUIEventViewDidDisappear");

void XUINotificationCallbackUIUpdated(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    XXTEUIViewController *controller = (__bridge XXTEUIViewController *)(observer);
    [controller.cellFactory setNeedsReload];
    if (controller.isBeingDisplayed)
    { // reload immediately
        [controller.cellFactory reloadIfNeeded];
    }
}

void XUINotificationCallbackValueChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {

    static NSString *valueSignalPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        valueSignalPath = [[XXTERootPath() stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"XUICallbackValueChanged.plist"];
    });

    XXTEUIViewController *controller = (__bridge XXTEUIViewController *)(observer);
    NSDictionary *payload = [[NSDictionary alloc] initWithContentsOfFile:valueSignalPath];
    if (!payload) return;
    
    NSMutableArray <NSDictionary *> *changedPairs = [[NSMutableArray alloc] init];
    NSArray <NSDictionary *> *valueSignalArray = payload[@"objects"];
    if (!valueSignalArray) return;
    
    for (NSDictionary *signalDict in valueSignalArray) {
        if (![signalDict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        if (![signalDict[@"defaults"] isKindOfClass:[NSString class]] ||
            ![signalDict[@"key"] isKindOfClass:[NSString class]] ||
            ![signalDict[@"value"] isKindOfClass:[NSString class]])
        {
            continue;
        }
        [changedPairs addObject:signalDict];
    }
    
    if (valueSignalArray.count > 0) {
        for (NSDictionary *signalDict in valueSignalArray) {
            [controller.cellFactory updateRelatedCellsForConfigurationPair:signalDict];
        }
    }

}

@interface XXTEUIViewController ()

@property (nonatomic, assign) BOOL beingDisplayed;

@end

@implementation XXTEUIViewController {
    
}

@synthesize entryPath = _entryPath, awakeFromOutside = _awakeFromOutside;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Interface Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"xuic", @"xui", @"plist", @"json" ];
}

+ (Class)relatedReader {
    return [XUIEntryReader class];
}

- (instancetype)initWithPath:(NSString *)path { 
    if (self = [super initWithPath:path]) {
        _entryPath = path;
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path withBundlePath:(NSString *)bundlePath {
    if (self = [super initWithPath:path withBundlePath:bundlePath]) {
        _entryPath = path;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.hidesBottomBarWhenPushed = YES;
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), XUINotificationCallbackValueChanged, XUICallbackValueChanged, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), XUINotificationCallbackUIUpdated, XUICallbackUIUpdated, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)dealloc {
    
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), XUICallbackUIUpdated, NULL);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), XUICallbackValueChanged, NULL);
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.awakeFromOutside) {
        [self.navigationItem setLeftBarButtonItem:nil];
        [self.navigationItem setRightBarButtonItem:nil];
    } else {
        // navigation items
        if ([self.navigationController.viewControllers firstObject] == self)
        {
            if (XXTE_COLLAPSED)
            {
                [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
            }
        }
    }
    self.footerView.footerIcon = [[UIImage imageNamed:@"XUIAboutIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)viewWillAppear:(BOOL)animated {
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotifications:) name:XXTENotificationEvent object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleXUINotifications:) name:XUINotificationEventValueChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleXUINotifications:) name:XUINotificationEventUIUpdated object:nil];
    }
    [super viewWillAppear:animated];
    self.beingDisplayed = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:XXTENotificationEvent object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:XUINotificationEventValueChanged object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:XUINotificationEventUIUpdated object:nil];
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.beingDisplayed = NO;
}

- (void)dismissViewController:(id)dismissViewController {
    if (!XXTE_IS_FULLSCREEN(self)) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationEvent object:self userInfo:@{XXTENotificationEventType: XXTENotificationEventTypeFormSheetDismissed}]];
    }
    [super dismissViewController:dismissViewController];
}

#pragma mark - Notifications

- (void)handleApplicationNotifications:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    NSString *eventType = userInfo[XXTENotificationEventType];
    if ([eventType isEqualToString:XXTENotificationEventTypeApplicationDidEnterBackground])
    {
        if (self.awakeFromOutside) {
            [self dismissViewController:aNotification];
        }
    }
}

- (void)handleXUINotifications:(NSNotification *)aNotification {
    
    if ([aNotification.name isEqualToString:XUINotificationEventValueChanged])
    {
        static NSString *valueSignalPath = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            valueSignalPath = [[XXTERootPath() stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"XUIEventValueChanged.plist"];
        });
        
        NSMutableArray <NSDictionary *> *signalArray = [[NSMutableArray alloc] init];
        if (aNotification.userInfo)
            [signalArray addObject:aNotification.userInfo];
        
        NSString *entryPath = self.entryPath;
        if (!entryPath) entryPath = @"";
        NSString *bundlePath = self.bundle.bundlePath;
        if (!bundlePath) bundlePath = @"";
        
        NSDictionary *payload =
  @{
    @"objects": signalArray,
    @"entry": entryPath,
    @"bundle": bundlePath,
    @"envp": uAppConstEnvp()
    };
        if ([payload writeToFile:valueSignalPath atomically:YES])
        {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), XUIEventValueChanged, /* aNotification.object */ NULL, /* aNotification.userInfo */ NULL, true);
        }
        
    }
    
}

- (void)presentErrorAlertController:(NSError *)error {
    if (!error) return;
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        NSString *entryName = [self.callerPath lastPathComponent];
        LGAlertView *alert = [[LGAlertView alloc] initWithTitle:[XUIStrings localizedStringForString:@"XUI Error"]
                                                        message:[NSString stringWithFormat:[XUIStrings localizedStringForString:@"%@\n%@: %@"], entryName, error.localizedFailureReason, error.localizedDescription]
                                                          style:LGAlertViewStyleAlert
                                                   buttonTitles:@[ [XUIStrings localizedStringForString:@"OK"] ]
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                                  actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) { [alertView dismissAnimated]; }
                                                  cancelHandler:nil
                                             destructiveHandler:nil];
        if (self.theme.isBackgroundDark == NO) {
            [XXTEMasterViewController setupAlertDefaultAppearance:alert];
        } else {
            [XXTEMasterViewController setupAlertDarkAppearance:alert];
        }
        [alert showAnimated];
    });
}

@end
