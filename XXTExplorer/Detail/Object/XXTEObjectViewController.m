//
//  XXTEObjectViewController.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEObjectViewController.h"
#import "XXTEBaseObjectViewController.h"
#import "XXTEArrayObjectViewController.h"
#import "XXTEDictionaryObjectViewController.h"
#import "XXTExplorerEntryObjectReader.h"

#import "XUITheme.h"

@interface XXTEObjectViewController ()

@end

@implementation XXTEObjectViewController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Object Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"json", @"plist" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryObjectReader class];
}

+ (NSArray <Class> *)supportedTypes {
    return @[  ];
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
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
        [self setup];
    }
    return self;
}

- (instancetype)initWithRootObject:(id)RootObject {
    id initObject = nil;
    if (RootObject) {
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
                    initObject = [(XXTEObjectViewController *) [[controllerClass class] alloc] initWithRootObject:RootObject];
                    supported = YES;
                    break;
                }
            }
            if (supported) {
                break;
            }
        }
    }
    if (initObject) {
        self = initObject;
    } else {
        self = [super init];
    }
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _tableViewStyle = UITableViewStyleGrouped;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *entryPath = self.entryPath;
    if (entryPath) {
        NSString *entryName = [entryPath lastPathComponent];
        self.title = entryName;
    }
    
    _tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:self.tableViewStyle];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.editing = NO;
        XXTE_START_IGNORE_PARTIAL
        if (@available(iOS 9.0, *)) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        XXTE_END_IGNORE_PARTIAL
        tableView;
    });
    
    [self.view addSubview:self.tableView];

    XXTE_START_IGNORE_PARTIAL
    if (XXTE_COLLAPSED && self.navigationController.viewControllers[0] == self) {
        [self.navigationItem setLeftBarButtonItem:self.splitViewController.displayModeButtonItem];
    }
    XXTE_END_IGNORE_PARTIAL
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
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
    return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@synthesize awakeFromOutside;

@end
