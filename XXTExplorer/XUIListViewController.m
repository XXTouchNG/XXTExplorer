//
//  XUIListViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIListViewController.h"
#import "XUIConfigurationParser.h"

@interface XUIListViewController ()

@property (nonatomic, strong) XUIConfigurationParser *configurationParser;
@property (nonatomic, strong, readonly) NSArray <NSDictionary *> *entries;

@end

@implementation XUIListViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initWithRootEntry:(NSString *)entryPath {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _entryPath = entryPath;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.entryPath lastPathComponent];
    self.clearsSelectionOnViewWillAppear = YES;
    
    {
        NSDictionary *rootEntry = [[NSDictionary alloc] initWithContentsOfFile:self.entryPath];
        NSArray <NSDictionary *> *entries = [XUIConfigurationParser entriesFromRootEntry:rootEntry];
        if (!entries) {
            return;
        }
    }
    
}

@end
