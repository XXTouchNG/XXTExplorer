//
//  XXTEUIViewController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 09/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController.h"
#import "XXTENotificationCenterDefines.h"
#import "XUIEntryReader.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.awakeFromOutside) {
        [self.navigationItem setLeftBarButtonItem:nil];
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationNotifications:) name:XXTENotificationEvent object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)dismissViewController:(id)dismissViewController {
    if (XXTE_PAD) {
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
