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

@interface XXTEEditorSearchController ()

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
    
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"Search", nil);
    
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

#pragma mark - Memory

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"- [XXTEEditorSearchController dealloc]");
#endif
}

@end
