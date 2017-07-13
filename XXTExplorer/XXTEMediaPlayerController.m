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

@interface XXTEMediaPlayerController ()

@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;
@property (nonatomic, strong) UIBarButtonItem *closeItem;
@property (nonatomic, strong) UIBarButtonItem *shareItem;

@end

@implementation XXTEMediaPlayerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return @"Movie Player";
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"m4a", @"aac", @"m4v", @"m4r", @"mp3", @"mov", @"mp4", @"ogg", @"aif", @"wav", @"flv", @"mpg", @"avi" ];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
        [self setup];
    }
    return self;
}

- (void)setup {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackWillEnterFullscreen:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackWillExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.entryPath lastPathComponent];
    self.view.backgroundColor = [UIColor whiteColor];
//    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self moviePlayer];
    [self.view addSubview:self.moviePlayer.view];
    
    if (XXTE_PAD) {
        self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    }
    
}

#pragma mark - Notifications

- (void)moviePlaybackDidFinish:(NSNotification *)aNotification {
    NSDictionary *userInfo = aNotification.userInfo;
    if ([userInfo[@"error"] isKindOfClass:[NSError class]]) {
        NSString *entryName = [self.entryPath lastPathComponent];
        NSString *reason = [userInfo[@"error"] localizedDescription];
        showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Cannot load movie \"%@\": %@", nil), entryName, reason]);
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

#pragma mark - UIView Getter

- (MPMoviePlayerController *)moviePlayer {
    if (!_moviePlayer) {
        NSURL *urlString = [NSURL fileURLWithPath:self.entryPath];
        MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:urlString];
        if (XXTE_PAD) {
            moviePlayer.view.frame = self.view.bounds;
        } else {
            CGSize viewSize = self.view.bounds.size;
            moviePlayer.view.frame = CGRectMake(0, 0, viewSize.width, viewSize.height - self.navigationController.tabBarController.tabBar.bounds.size.height);
        }
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

#pragma mark - Memory

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
    NSLog(@"- [XXTEMediaPlayerController dealloc]");
#endif
}

@end
