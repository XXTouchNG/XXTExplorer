//
//  XXTEEditorController+Settings.m
//  XXTExplorer
//
//  Created by Zheng on 17/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+Settings.h"
#import "XXTEEditorSettingsViewController.h"

#import "XXTEEditorTextView.h"

@implementation XXTEEditorController (Settings)

#pragma mark - Button Actions

- (void)settingsButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    XXTEEditorSettingsViewController *settingsController = [[XXTEEditorSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    settingsController.editor = self;
    [self.navigationController pushViewController:settingsController animated:YES];
}

@end
