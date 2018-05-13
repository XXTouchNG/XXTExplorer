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
#import "XXTESymbolViewController.h"
#import "XXTENavigationController.h"
#import "XXTETerminalViewController.h"

#import "XXTEEditorTextView.h"
#import "XXTEEditorLanguage.h"

@implementation XXTEEditorController (Settings)

#pragma mark - Button Actions

- (void)backButtonItemTapped:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)shareButtonItemTapped:(UIBarButtonItem *)sender {
    if (!self.entryPath) return;
    NSURL *shareUrl = [NSURL fileURLWithPath:self.entryPath];
    if (!shareUrl) return;
    XXTE_START_IGNORE_PARTIAL
    if (@available(iOS 9.0, *)) {
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[ shareUrl ] applicationActivities:nil];
        if (XXTE_IS_IPAD) {
            activityViewController.modalPresentationStyle = UIModalPresentationPopover;
            UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
            popoverPresentationController.barButtonItem = sender;
        }
        [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
    } else {
        toastMessage(self, NSLocalizedString(@"This feature requires iOS 9.0 or later.", nil));
    }
    XXTE_END_IGNORE_PARTIAL
}

- (void)launchItemTapped:(UIBarButtonItem *)sender {
    BOOL supported = NO;
    NSArray <NSString *> *suggested = [XXTETerminalViewController suggestedExtensions];
    NSArray <NSString *> *holded = self.language.extensions;
    for (NSString *holdedExt in holded) {
        if ([suggested containsObject:holdedExt]) {
            supported = YES;
            break;
        }
    }
    if (!supported) {
        return;
    }
    NSString *entryPath = self.entryPath;
    XXTETerminalViewController *terminalController = [[XXTETerminalViewController alloc] initWithPath:entryPath];
    terminalController.runImmediately = YES;
    terminalController.editor = self;
    [self.navigationController pushViewController:terminalController animated:YES];
}

- (void)searchButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    [self toggleSearchBar:sender animated:YES];
}

- (void)symbolsButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    if ([XXTESymbolViewController hasSymbolPatternsForLanguage:self.language]) {
        XXTESymbolViewController *symbolController = [[XXTESymbolViewController alloc] init];
        symbolController.editor = self;
        [self.navigationController pushViewController:symbolController animated:YES];
    } else {
        toastMessage(self, NSLocalizedString(@"No symbol definition found for this language.", nil));
    }
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
