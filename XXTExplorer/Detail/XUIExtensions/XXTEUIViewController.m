//
//  XXTEUIViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 09/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController.h"
#import "XUIEntryReader.h"
#import <XUI/XUIListFooterView.h>

#import <XUI/XUI.h>
#import <XUI/XUICellFactory.h>


static NSString * const XUIEventUIUpdated = @"XUIEventUIUpdated";
static NSString * const XUIEventValueChanged = @"XUIEventValueChanged";
void XUINotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *notificationName = (__bridge NSString *)(name);
        if ([notificationName isEqualToString:XUIEventUIUpdated])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:XUINotificationEventUIUpdated object:nil userInfo:@{}];
        }
        else if ([notificationName isEqualToString:XUIEventValueChanged])
        {
            NSMutableArray <NSDictionary *> *changedPairs = [[NSMutableArray alloc] init];
            NSString *valueSignalPath = [[XXTERootPath() stringByAppendingPathComponent:@"caches"] stringByAppendingPathComponent:@"XUIValueChanged.plist"];
            NSArray <NSDictionary *> *valueSignalArray = [[NSArray alloc] initWithContentsOfFile:valueSignalPath];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:XUINotificationEventValueChanged object:[changedPairs copy] userInfo:@{}];
        }
    });
}

@interface XXTEUIViewController ()

@end

@implementation XXTEUIViewController

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
}

- (void)dealloc {
    
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
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), XUINotificationCallback, ((__bridge CFStringRef)XUIEventValueChanged), (__bridge const void *)(self.cellFactory), CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), XUINotificationCallback, ((__bridge CFStringRef)XUIEventUIUpdated), (__bridge const void *)(self.cellFactory), CFNotificationSuspensionBehaviorDeliverImmediately);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotifications:) name:XXTENotificationEvent object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), ((__bridge CFStringRef)XUIEventUIUpdated), (__bridge const void *)(self.cellFactory));
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), ((__bridge CFStringRef)XUIEventValueChanged), (__bridge const void *)(self.cellFactory));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)dismissViewController:(id)dismissViewController {
    if (XXTE_IS_IPAD) {
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

@end
