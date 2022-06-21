//
//  XXTEImageViewerController.m
//  XXTExplorer
//
//  Created by Zheng Wu on 05/12/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEImageViewerController.h"
#import "XXTExplorerEntryImageReader.h"
#import "XXTEImageViewerController+NavigationBar.h"

#import "XXTExplorerEntryParser.h"
#import <LGAlertView/LGAlertView.h>


@interface XXTEImageViewerController () <MWPhotoBrowserDelegate>
@property (nonatomic, strong) NSMutableArray <NSString *> *photoPaths;
@property (nonatomic, strong) NSMutableArray <MWPhoto *> *photos;
@property (nonatomic, strong) XXTExplorerEntryParser *entryParser;
@property (nonatomic, strong) UIBarButtonItem *infoItem;

@end

@implementation XXTEImageViewerController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Image Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"png", @"jpg", @"gif", @"jpeg", @"tiff", @"heic" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryImageReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super initWithDelegate:self]) {
        _entryPath = path;
        _entryParser = [[XXTExplorerEntryParser alloc] init];
        _photoPaths = [[NSMutableArray alloc] init];
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
        [self.photoPaths addObject:singlePath];
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
    if (XXTE_COLLAPSED && [self.navigationController.viewControllers firstObject] == self) {
        [self.navigationItem setLeftBarButtonItems:self.splitButtonItems];
    }
    XXTE_END_IGNORE_PARTIAL
    [self.navigationItem setRightBarButtonItem:self.infoItem];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.titleView.tintColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self renderNavigationBarTheme:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:.4f delay:.2f options:0 animations:^{
        [self renderNavigationBarTheme:NO];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)infoItem {
    if (!_infoItem) {
        _infoItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTExplorerActionIconProperty"] style:UIBarButtonItemStylePlain target:self action:@selector(infoItemTapped:)];
        _infoItem.tintColor = [UIColor whiteColor];
    }
    return _infoItem;
}

#pragma mark - Actions

- (void)infoItemTapped:(UIBarButtonItem *)sender {
    if (self.currentIndex < self.photoPaths.count) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *photoPath = [self.photoPaths objectAtIndex:self.currentIndex];
        XXTExplorerEntryReader *entryReader = [[self.entryParser entryOfPath:photoPath withError:nil] entryReader];
        if (entryReader) {
            NSArray <NSString *> *metaKeys = entryReader.metaKeys;
            NSDictionary *meta = entryReader.metaDictionary;
            NSMutableArray <NSString *> *metaStrings = [NSMutableArray array];
            for (NSString *metaKey in metaKeys) {
                NSString *metaVal = meta[metaKey];
                if (metaVal) {
                    NSString *localizedKey = [mainBundle localizedStringForKey:(metaKey) value:nil table:(@"Meta")];
                    [metaStrings addObject:[NSString stringWithFormat:@"%@: %@", localizedKey, metaVal]];
                }
            }
            toastMessage(self, [metaStrings componentsJoinedByString:@"\n"]);
        }
    }
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.photos.count && index < self.photoPaths.count) {
        MWPhoto *photo = [self.photos objectAtIndex:index];
        // ... do something
        return photo;
    }
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    return [self photoBrowser:photoBrowser photoAtIndex:index];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index actionButton:(UIBarButtonItem *)actionButton {
    toastMessage(self, NSLocalizedString(@"This feature is not supported.", nil));
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [%@ dealloc]", NSStringFromClass([self class]));
#endif
}

@end
