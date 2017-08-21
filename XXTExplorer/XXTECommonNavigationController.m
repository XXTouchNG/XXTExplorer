//
//  XXTECommonNavigationController.m
//  XXTExplorer
//
//  Created by Zheng on 04/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTECommonNavigationController.h"

@interface XXTECommonNavigationController ()

@end

@implementation XXTECommonNavigationController

#pragma mark - Initializers

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    if (self = [super initWithRootViewController:rootViewController]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

@end
