//
//  RMCloudNavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 12/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "RMCloudNavigationController.h"

#import "XXTEAppDefines.h"

#import "RMCloudBroadcastView.h"
#import <MWFeedParser/MWFeedParser.h>
#import <MWFeedParser/NSString+HTML.h>

#import "XXTECommonWebViewController.h"
#import "XXTENavigationController.h"

@interface RMCloudNavigationController () <MWFeedParserDelegate, RMCloudBroadcastViewDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) RMCloudBroadcastView *broadcastView;

@property (nonatomic, assign) NSUInteger currentFeedIndex;
@property (nonatomic, strong) MWFeedParser *feedParser;
@property (nonatomic, strong) NSMutableArray <NSString *> *feeds;
@property (nonatomic, strong) NSMutableArray <MWFeedItem *> *feedItems;

@end

@implementation RMCloudNavigationController

- (instancetype)init {
    if (self = [super init]) {
        NSAssert(NO, @"RMCloudNavigationController must be initialized with a rootViewController.");
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        static BOOL alreadyInitialized = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSAssert(NO == alreadyInitialized, @"RMCloudNavigationController is a singleton.");
            alreadyInitialized = YES;
            [self setup];
        });
    }
    return self;
}

- (void)setup {
    _feeds = [[NSMutableArray alloc] init];
    _feedItems = [[NSMutableArray alloc] init];
    
    NSString *feedURLString = uAppDefine(@"RSS_URL");
    if (feedURLString.length > 0) {
        NSURL *feedURL = [NSURL URLWithString:feedURLString];
        MWFeedParser *feedParser = [[MWFeedParser alloc] initWithFeedURL:feedURL];
        feedParser.delegate = self;
        feedParser.feedParseType = ParseTypeItemsOnly;
        feedParser.connectionType = ConnectionTypeAsynchronously;
        [feedParser parse];
    }
    
    self.delegate = self;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.broadcastView];
    [self configureConstraints];
    
    if (@available(iOS 11.0, *)) {
        self.navigationBar.translucent = YES;
    } else {
        self.navigationBar.translucent = NO;
    }
    
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"RuanMao Cloud", nil) image:[UIImage imageNamed:@"RMCloudTabbarIcon"] tag:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self generateRandomFeed];
}

- (void)configureConstraints {
    self.broadcastView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray <NSLayoutConstraint *> *constraints =
    @[
      [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:0.0],
      [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0],
      [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0],
      [NSLayoutConstraint constraintWithItem:self.broadcastView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:26.0],
      ];
    [self.view addConstraints:constraints];
}

#pragma mark - MWFeedParserDelegate

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    NSString *summary = [item.summary stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!summary)
        summary = @"";
    [self.feeds addObject:[NSString stringWithFormat:@"%@ %@", item.title, summary]];
    [self.feedItems addObject:item];
}

- (void)feedParserDidFinish:(MWFeedParser *)parser {
    [self generateRandomFeed];
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error {
    [self.broadcastView reloadScrollViewWithText:error.localizedDescription];
}

- (void)generateRandomFeed {
    int seed = arc4random() % self.feedItems.count;
    NSUInteger idx = (NSUInteger)seed;
    self.currentFeedIndex = idx;
    if (idx < self.feeds.count) {
        NSString *itemSummary = self.feeds[idx];
        [self.broadcastView reloadScrollViewWithText:[itemSummary stringByDecodingHTMLEntities]];
    }
    [self.view bringSubviewToFront:self.broadcastView];
}

#pragma mark - RMCloudBroadcastViewDelegate

- (void)broadcastViewDidTapped:(RMCloudBroadcastView *)view {
    NSUInteger idx = self.currentFeedIndex;
    if (idx < self.feedItems.count) {
        MWFeedItem *item = self.feedItems[idx];
        if (item.link) {
            XXTECommonWebViewController *webController = [[XXTECommonWebViewController alloc] initWithURLString:item.link];
            webController.title = NSLocalizedString(@"Loading...", nil);
            if (XXTE_COLLAPSED) {
                if (@available(iOS 8.0, *)) {
                    XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:webController];
                    [self.splitViewController showDetailViewController:navigationController sender:self];
                }
            } else {
                [self pushViewController:webController animated:YES];
            }
        }
    }
}

#pragma mark - UIView Getters

- (RMCloudBroadcastView *)broadcastView {
    if (!_broadcastView) {
        _broadcastView = [[RMCloudBroadcastView alloc] init];
        _broadcastView.translatesAutoresizingMaskIntoConstraints = NO;
        _broadcastView.delegate = self;
    }
    return _broadcastView;
}

- (void)showBroadcastAnimated:(BOOL)animated {
    if (animated) {
        self.broadcastView.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.broadcastView.alpha = 1.0;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        self.broadcastView.alpha = 1.0;
        self.broadcastView.hidden = NO;
    }
}

- (void)hideBroadcastAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.broadcastView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.broadcastView.hidden = YES;
        }];
    } else {
        self.broadcastView.alpha = 0.0;
        self.broadcastView.hidden = YES;
    }
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[XXTECommonWebViewController class]]) {
        [self hideBroadcastAnimated:NO];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (NO == [viewController isKindOfClass:[XXTECommonWebViewController class]]) {
        [self showBroadcastAnimated:YES];
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [RMCloudNavigationController dealloc]");
#endif
}

@end
