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

@synthesize entryPath = _entryPath;

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
    
    NSError *prepareError = nil;
    NSFileManager *prepareManager = [NSFileManager defaultManager];
    
    NSString *singlePath = self.entryPath;
    NSString *parentPath = [singlePath stringByDeletingLastPathComponent];
    
    NSArray <NSString *> *fileList = [prepareManager contentsOfDirectoryAtPath:parentPath error:&prepareError];
    if (!fileList) {
        return;
    }
    
    NSMutableArray <NSString *> *filteredFileList = [[NSMutableArray alloc] init];
    [fileList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fileExt = [[obj pathExtension] lowercaseString];
        if ([[[self class] suggestedExtensions] containsObject:fileExt])
        {
            [filteredFileList addObject:obj];
        }
    }];
    
    [filteredFileList sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
    }];
    
    for (NSString *filteredFile in filteredFileList) {
        NSString *singlePath = [parentPath stringByAppendingPathComponent:filteredFile];
        NSURL *singleURL = [NSURL fileURLWithPath:singlePath];
        MWPhoto *singlePhoto = [MWPhoto photoWithURL:singleURL];
        singlePhoto.caption = [singlePath lastPathComponent];
        [self.photos addObject:singlePhoto];
    }
    
    NSString *singleName = [singlePath lastPathComponent];
    NSUInteger selectedIndex = [filteredFileList indexOfObject:singleName];
    if (selectedIndex != NSNotFound) {
        [self setCurrentPhotoIndex:selectedIndex];
    }
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
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

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    return [self photoBrowser:photoBrowser photoAtIndex:index];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@synthesize awakeFromOutside;

@end
