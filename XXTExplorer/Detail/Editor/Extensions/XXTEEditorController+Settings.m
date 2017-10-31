//
//  XXTEEditorController+Settings.m
//  XXTExplorer
//
//  Created by Zheng on 17/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorController+Settings.h"
#import "XXTEEditorSettingsViewController.h"
#import "XXTEEditorStatisticsViewController.h"
#import "XXTEUserInterfaceDefines.h"

#import "XXTEEditorTextView.h"

@implementation XXTEEditorController (Settings)

#pragma mark - Button Actions

- (void)shareButtonItemTapped:(UIBarButtonItem *)sender {
    if (!self.entryPath) return;
    NSURL *shareUrl = [NSURL fileURLWithPath:self.entryPath];
    if (!shareUrl) return;
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 8.0, *)) {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ shareUrl ] applicationActivities:nil];
        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        popoverPresentationController.barButtonItem = sender;
        [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
    } else {
        toastMessage(self, NSLocalizedString(@"This feature is not supported.", nil));
    }
    XXTE_END_IGNORE_PARTIAL
}

- (void)searchButtonItemTapped:(UIBarButtonItem *)sender {
    
}

- (void)symbolsButtonItemTapped:(UIBarButtonItem *)sender {
    
}

- (void)statisticsButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    XXTEEditorStatisticsViewController *statisticsController = [[XXTEEditorStatisticsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    statisticsController.editor = self;
    [self.navigationController pushViewController:statisticsController animated:YES];
}

- (void)settingsButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    XXTEEditorSettingsViewController *settingsController = [[XXTEEditorSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    settingsController.editor = self;
    [self.navigationController pushViewController:settingsController animated:YES];
}

@end
