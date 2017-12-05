//
//  XXTEImageViewerController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 05/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEImageViewerController.h"
#import "XXTExplorerEntryImageReader.h"

@interface XXTEImageViewerController () <MWPhotoBrowserDelegate>
@property (nonatomic, strong) NSMutableArray <MWPhoto *> *photos;

@end

@implementation XXTEImageViewerController

@synthesize entryPath = _entryPath, awakeFromOutside = _awakeFromOutside;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Image Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"png", @"jpg", @"gif", @"jpeg", @"heic" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryImageReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super initWithDelegate:self]) {
        _entryPath = path;
        _photos = [[NSMutableArray alloc] init];
        [self setup];
    }
    return self;
}

- (void)setup {
    self.displayActionButton = YES;
    self.displayNavArrows = YES;
    self.displaySelectionButtons = NO;
    self.zoomPhotosToFill = NO;
    self.alwaysShowControls = NO;
    self.enableGrid = YES;
    self.startOnGrid = NO;
    self.autoPlayOnAppear = NO;
    
    [self preparePhotos];
}

- (void)preparePhotos {
    if (!self.entryPath) {
        return;
    }
    NSString *singlePath = self.entryPath;
    NSURL *singleURL = [NSURL fileURLWithPath:singlePath];
    MWPhoto *singlePhoto = [MWPhoto photoWithURL:singleURL];
    singlePhoto.caption = [singlePath lastPathComponent];
    [self.photos addObject:singlePhoto];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photos.count) {
        return [self.photos objectAtIndex:index];
    }
    return nil;
}

@end
