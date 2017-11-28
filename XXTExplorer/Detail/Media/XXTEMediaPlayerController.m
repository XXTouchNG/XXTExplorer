//
//  XXTEMediaPlayerController.m
//  XXTExplorer
//
//  Created by Zheng on 13/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEMediaPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"
#import "XXTExplorerEntryMediaReader.h"

@interface XXTEMediaPlayerController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;

@end

@implementation XXTEMediaPlayerController

@synthesize entryPath = _entryPath, awakeFromOutside = _awakeFromOutside;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Movie Player", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"m4a", @"m4v", @"mov", @"flv", @"fla", @"mp4", @"mp3", @"aac", @"wav" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryMediaReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = self.shareButtonItem;
    
    [self moviePlayer];
    [self.view addSubview:self.moviePlayer.view];

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackWillEnterFullscreen:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackWillExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackDidExitFullscreen:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
    [self.moviePlayer pause];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        insets = self.view.safeAreaInsets;
    }
    if (XXTE_COLLAPSED) {
        self.moviePlayer.view.frame = UIEdgeInsetsInsetRect(self.view.bounds, insets);
    } else {
        self.moviePlayer.view.frame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.navigationController.tabBarController.tabBar.bounds)), insets);
    }
}

#pragma mark - Notifications

- (void)moviePlaybackDidFinish:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    if ([userInfo[@"error"] isKindOfClass:[NSError class]]) {
        NSString *entryName = [self.entryPath lastPathComponent];
        NSString *reason = [userInfo[@"error"] localizedDescription];
        toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Cannot load movie \"%@\": %@", nil), entryName, reason]));
    }
}

- (void)moviePlaybackWillEnterFullscreen:(NSNotification *)aNotification {
    self.moviePlayer.view.backgroundColor = [UIColor blackColor];
    self.moviePlayer.backgroundView.backgroundColor = [UIColor blackColor];
}

- (void)moviePlaybackWillExitFullscreen:(NSNotification *)aNotification {
    self.moviePlayer.view.backgroundColor = [UIColor whiteColor];
    self.moviePlayer.backgroundView.backgroundColor = [UIColor whiteColor];
}

- (void)moviePlaybackDidExitFullscreen:(NSNotification *)aNotification {
    self.moviePlayer.view.backgroundColor = [UIColor whiteColor];
    self.moviePlayer.backgroundView.backgroundColor = [UIColor whiteColor];
}

#pragma mark - UIView Getter

- (MPMoviePlayerController *)moviePlayer {
    if (!_moviePlayer) {
        NSURL *urlString = [NSURL fileURLWithPath:self.entryPath];
        MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:urlString];
        moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        moviePlayer.view.backgroundColor = [UIColor whiteColor];
        moviePlayer.backgroundView.backgroundColor = [UIColor whiteColor];
        moviePlayer.shouldAutoplay = NO;
        [moviePlayer setControlStyle:MPMovieControlStyleEmbedded];
        [moviePlayer prepareToPlay];
        _moviePlayer = moviePlayer;
    }
    return _moviePlayer;
}

- (UIBarButtonItem *)shareButtonItem {
    if (!_shareButtonItem) {
        UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped:)];
        shareButtonItem.tintColor = [UIColor whiteColor];
        _shareButtonItem = shareButtonItem;
    }
    return _shareButtonItem;
}

#pragma mark - Share

- (void)shareButtonItemTapped:(UIBarButtonItem *)sender {
    NSURL *shareURL = [NSURL fileURLWithPath:self.entryPath];
    if (!shareURL) {
        return;
    }
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ shareURL ] applicationActivities:nil];
        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        popoverPresentationController.barButtonItem = sender;
        [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
    }
    XXTE_END_IGNORE_PARTIAL
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEMediaPlayerController dealloc]");
#endif
}

@end
