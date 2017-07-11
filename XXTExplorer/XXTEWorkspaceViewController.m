//
//  XXTEWorkspaceViewController.m
//  XXTExplorer
//
//  Created by Zheng on 25/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEWorkspaceViewController.h"

@interface XXTEWorkspaceViewController ()

@end

@implementation XXTEWorkspaceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    
}

@end
