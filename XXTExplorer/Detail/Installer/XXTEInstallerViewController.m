//
//  XXTEInstallerViewController.m
//  XXTExplorer
//
//  Created by Zheng on 19/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEInstallerViewController.h"
#import "XXTExplorerEntryDiskImageReader.h"

@interface XXTEInstallerViewController ()

@end

@implementation XXTEInstallerViewController

@synthesize entryPath = _entryPath, awakeFromOutside = _awakeFromOutside;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Installer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"xpa" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryDiskImageReader class];
}

#pragma mark - Initializers

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
    }
    return self;
}

#pragma mark - Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    
    // load contents of disk image
    
    
    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEInstallerViewController dealloc]");
#endif
}

@end
