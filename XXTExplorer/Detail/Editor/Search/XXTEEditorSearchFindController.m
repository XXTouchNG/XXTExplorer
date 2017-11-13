//
//  XXTEEditorSearchFindController.m
//  XXTExplorer
//
//  Created by Zheng on 11/11/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorSearchFindController.h"
#import "XXTEEditorController.h"

@interface XXTEEditorSearchFindController ()

@end

@implementation XXTEEditorSearchFindController

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.title = NSLocalizedString(@"Find", nil);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
}

@end
