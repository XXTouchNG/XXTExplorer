//
//  XXTEImageViewerController.m
//  XXTExplorer
//
//  Created by Zheng on 14/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEImageViewerController.h"
#import "XXTExplorerEntryImageReader.h"

@interface XXTEImageViewerController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIBarButtonItem *shareButtonItem;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;

@end

@implementation XXTEImageViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return @"Image Viewer";
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"png", @"jpg", @"gif", @"jpeg" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryImageReader class];
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
    self.navigationItem.rightBarButtonItem = self.shareButtonItem;
    
    UIImage *image = [UIImage imageWithContentsOfFile:self.entryPath];
    self.imageView.image = image;
    CGSize imageSize = image.size;
    CGRect maxRect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.navigationController.tabBarController.tabBar.bounds.size.height);
    if (CGRectContainsRect(maxRect, CGRectMake(0, 0, imageSize.width, imageSize.height)))
    {
        self.imageView.contentMode = UIViewContentModeCenter;
    } else {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    [self.scrollView addSubview:self.imageView];
    [self.view addSubview:self.scrollView];
    
    [self.scrollView addGestureRecognizer:self.doubleTapGestureRecognizer];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self.scrollView setContentOffset:CGPointZero animated:NO];
    [self.imageView removeFromSuperview];
    self.imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.navigationController.tabBarController.tabBar.bounds.size.height);
    [self.scrollView addSubview:self.imageView];
}

#pragma mark - UIView Getters

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.delegate = self;
        scrollView.scrollEnabled = YES;
        scrollView.bounces = YES;
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
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _imageView = imageView;
    }
    return _imageView;
}

- (UIBarButtonItem *)shareButtonItem {
    if (!_shareButtonItem) {
        UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped:)];
        shareButtonItem.tintColor = [UIColor whiteColor];
        _shareButtonItem = shareButtonItem;
    }
    return _shareButtonItem;
}

- (UITapGestureRecognizer *)doubleTapGestureRecognizer {
    if (!_doubleTapGestureRecognizer) {
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapRecognized:)];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        doubleTapGestureRecognizer.delegate = self;
        _doubleTapGestureRecognizer = doubleTapGestureRecognizer;
    }
    return _doubleTapGestureRecognizer;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView == self.scrollView) {
        return self.imageView;
    }
    return nil;
}

#pragma mark - UIGestureRecognizerDelegate

- (void)doubleTapRecognized:(UITapGestureRecognizer *)recognizer {
    float newScale = [self.scrollView zoomScale] * 4.0;
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale)
    {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
    else
    {
        CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[recognizer locationInView:recognizer.view]];
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    zoomRect.size.height = [self.imageView frame].size.height / scale;
    zoomRect.size.width  = [self.imageView frame].size.width  / scale;
    center = [self.imageView convertPoint:center fromView:self.scrollView];
    zoomRect.origin.x = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y = center.y - ((zoomRect.size.height / 2.0));
    return zoomRect;
}

#pragma mark - Share

- (void)shareButtonItemTapped:(UIBarButtonItem *)sender {
    NSURL *shareURL = [NSURL fileURLWithPath:self.entryPath];
    if (!shareURL) {
        return;
    }
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ shareURL ] applicationActivities:nil];
    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
    popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverPresentationController.barButtonItem = sender;
    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEImageViewerController dealloc]");
#endif
}

@end
