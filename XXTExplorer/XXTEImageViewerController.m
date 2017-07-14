//
//  XXTEImageViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEImageViewerController.h"

@interface XXTEImageViewerController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation XXTEImageViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return @"Image Viewer";
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"png", @"jpg", @"gif" ];
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
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.entryPath lastPathComponent];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImage *image = [UIImage imageWithContentsOfFile:self.entryPath];
    self.imageView.image = image;
    CGSize imageSize = image.size;
    if (CGRectContainsRect(self.imageView.bounds, CGRectMake(0, 0, imageSize.width, imageSize.height)))
    {
        self.imageView.contentMode = UIViewContentModeCenter;
    } else {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    self.scrollView.contentSize = self.imageView.bounds.size;
    [self.scrollView addSubview:self.imageView];
    [self.view addSubview:self.scrollView];
    
    if (XXTE_PAD) {
        self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    }
    
}

#pragma mark - UIView Getters

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.delegate = self;
        scrollView.scrollEnabled = YES;
        scrollView.bounces = YES;
//        scrollView.alwaysBounceVertical = YES;
//        scrollView.alwaysBounceHorizontal = YES;
        scrollView.bouncesZoom = YES;
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 10.f;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.clipsToBounds = YES;
        _scrollView = scrollView;
    }
    return _scrollView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.navigationController.navigationBar.bounds.size.height - self.navigationController.tabBarController.tabBar.bounds.size.height - [self statusBarHeight])];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _imageView = imageView;
    }
    return _imageView;
}

- (CGFloat)statusBarHeight {
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.height, statusBarSize.width);
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView) {
        return self.imageView;
    }
    return nil;
}

#pragma mark - Memory

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
    NSLog(@"- [XXTEImageViewerController dealloc]");
#endif
}

@end
