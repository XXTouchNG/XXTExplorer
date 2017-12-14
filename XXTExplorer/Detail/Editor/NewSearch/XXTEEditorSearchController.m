//
//  XXTEEditorSearchController.m
//  XXTExplorer
//
//  Created by Zheng on 2017/11/10.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTEEditorSearchController.h"

// Parent
#import "XXTEEditorController.h"
#import "XXTEEditorController+NavigationBar.h"
#import "XXTEEditorTheme.h"
#import "XXTEEditorLanguage.h"
#import "UIColor+SKColor.h"

// Child
#import "XXTEEditorSearchFindController.h"
#import "XXTEEditorSearchReplaceController.h"
#import "XXTEEditorSearchSettingsController.h"

typedef enum : NSUInteger {
    XXTEEditorSearchIndexFind = 0,
    XXTEEditorSearchIndexReplace,
} XXTEEditorSearchIndex;

@interface XXTEEditorSearchController ()

@property (nonatomic, strong) UIBarButtonItem *myBackButtonItem;
@property (nonatomic, strong) UIBarButtonItem *settingsButtonItem;

@end

@implementation XXTEEditorSearchController

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.title = NSLocalizedString(@"Search", nil);
    
    XXTEEditorSearchFindController *controller1 = [[XXTEEditorSearchFindController alloc] init];
    XXTEEditorSearchReplaceController *controller2 = [[XXTEEditorSearchReplaceController alloc] init];
    [self setViewControllers:@[ controller1, controller2 ]];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.leftBarButtonItem = self.myBackButtonItem;
    self.navigationItem.rightBarButtonItem = self.settingsButtonItem;
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.editor renderNavigationBarTheme:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self.editor renderNavigationBarTheme:NO];
    } else {
        [self.editor renderNavigationBarTheme:YES];
    }
    [super willMoveToParentViewController:parent];
}

#pragma mark - UIView Getters

- (UIBarButtonItem *)myBackButtonItem {
    if (!_myBackButtonItem) {
        UIBarButtonItem *myBackButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarBack"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonItemTapped:)];
        _myBackButtonItem = myBackButtonItem;
    }
    return _myBackButtonItem;
}

- (UIBarButtonItem *)settingsButtonItem {
    if (!_settingsButtonItem) {
        UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"XXTEToolbarSearchSettings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonItemTapped:)];
        _settingsButtonItem = settingsButtonItem;
    }
    return _settingsButtonItem;
}

#pragma mark - Actions

- (void)backButtonItemTapped:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)settingsButtonItemTapped:(UIBarButtonItem *)sender {
    XXTEEditorSearchSettingsController *settingsController = [[XXTEEditorSearchSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.navigationController pushViewController:settingsController animated:YES];
}

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEEditorSearchController dealloc]");
#endif
}

@end
