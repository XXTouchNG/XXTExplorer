//
//  XXTEObjectViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEObjectViewController.h"
//#import "XUI.h"
#import "XXTEBaseObjectViewController.h"
#import "XXTEArrayObjectViewController.h"
#import "XXTEDictionaryObjectViewController.h"
#import "XXTExplorerEntryObjectReader.h"
//#import "XUIListViewController.h"

@interface XXTEObjectViewController ()

@end

@implementation XXTEObjectViewController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return @"Object Viewer";
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"xui", @"json", @"plist" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryObjectReader class];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

+ (NSArray <Class> *)supportedTypes {
    return @[  ];
}

- (instancetype)init {
    if (self = [super init]) {
        _entryBundle = [NSBundle mainBundle];
    }
    return self;
}

- (instancetype)initWithPath:(NSString *)path {
    id RootObject = nil;
    if (!RootObject) {
        RootObject = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
    if (!RootObject) {
        RootObject = [[NSArray alloc] initWithContentsOfFile:path];
    }
    if (!RootObject) {
        NSData *jsonEntryData = [[NSData alloc] initWithContentsOfFile:path];
        if (jsonEntryData) {
            RootObject = [NSJSONSerialization JSONObjectWithData:jsonEntryData options:0 error:nil];
        }
    }
    self = [self initWithRootObject:RootObject];
    if (self) {
        _entryPath = path;
    }
    return self;
}

- (instancetype)initWithRootObject:(id)RootObject {
    NSArray <Class> *controllerClasses =
    @[
      [XXTEBaseObjectViewController class],
      [XXTEArrayObjectViewController class],
      [XXTEDictionaryObjectViewController class]
      ];
    Class ObjectClass = [RootObject class];
    for (Class controllerClass in controllerClasses) {
        NSArray <Class> *supportedTypes = [[controllerClass class] supportedTypes];
        BOOL supported = NO;
        for (Class supportedType in supportedTypes) {
            if ([ObjectClass isSubclassOfClass:supportedType]) {
                self = [[[controllerClass class] alloc] initWithRootObject:RootObject];
                supported = YES;
                break;
            }
        }
        if (supported) {
            break;
        }
    }
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.editing = NO;
        XXTE_START_IGNORE_PARTIAL
        if (XXTE_SYSTEM_9) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        tableView;
    });
    
    [self.view addSubview:self.tableView];
}

#pragma mark - UIView Getters

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            return UITableViewAutomaticDimension;
        }
    }
    return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
