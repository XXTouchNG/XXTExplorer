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

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"

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

- (BOOL)isLaunchItemAvailable {
    if (self.isLockedState) {
        return NO;
    }
    BOOL supported = NO;
    NSArray <NSString *> *suggested = [XXTETerminalViewController suggestedExtensions];
    NSArray <NSString *> *holded = self.language.extensions;
    for (NSString *holdedExt in holded) {
        if ([suggested containsObject:holdedExt]) {
            supported = YES;
            break;
        }
    }
    return supported;
}

- (void)launchItemTapped:(UIBarButtonItem *)sender {
    if ([self isLaunchItemAvailable]) {
        [self saveDocumentIfNecessary];
        NSString *entryPath = self.entryPath;
        XXTETerminalPresentationStyle style = XXTEDefaultsInt(XXTExplorerTerminalPresentationStyle, XXTETerminalPresentationStylePush);
        XXTETerminalViewController *terminalController = [[XXTETerminalViewController alloc] initWithPath:entryPath];
        terminalController.runImmediately = YES;
        terminalController.editor = self;
        if (XXTE_COLLAPSED || style == XXTETerminalPresentationStylePresentAsPopover) {
            XXTE_START_IGNORE_PARTIAL
            if (@available(iOS 9.0, *)) {
                terminalController.modalPresentationStyle = UIModalPresentationPopover;
                UIPopoverPresentationController *popoverPresentationController = terminalController.popoverPresentationController;
                popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                popoverPresentationController.barButtonItem = sender;
                popoverPresentationController.delegate = self;
                [self.navigationController presentViewController:terminalController animated:YES completion:nil];
            } else {
                toastMessage(self, NSLocalizedString(@"This feature requires iOS 9.0 or later.", nil));
            }
            XXTE_END_IGNORE_PARTIAL
        } else if (style == XXTETerminalPresentationStylePresentInModal) {
            XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:terminalController];
            [self presentViewController:navigationController animated:YES completion:nil];
        } else {
            [self.navigationController pushViewController:terminalController animated:YES];
        }
    } else {
        toastMessage(self, NSLocalizedString(@"This file is not executable.", nil));
        return;
    }
}

- (BOOL)isSearchButtonItemAvailable {
    if (self.isLockedState) {
        return NO;
    }
    return YES;
}

- (void)searchButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    if ([self isSearchButtonItemAvailable]) {
        [self toggleSearchBar:sender animated:YES];
    }
}

- (BOOL)isSymbolsButtonItemAvailable {
    if (self.isLockedState) {
        return NO;
    }
    return [XXTESymbolViewController hasSymbolPatternsForLanguage:self.language];
}

- (void)symbolsButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    if ([self isSymbolsButtonItemAvailable]) {
        XXTESymbolViewController *symbolController = [[XXTESymbolViewController alloc] init];
        symbolController.editor = self;
        [self.navigationController pushViewController:symbolController animated:YES];
    } else {
        toastMessage(self, NSLocalizedString(@"No symbol definition found for this language.", nil));
    }
}

- (BOOL)isStatisticsButtonItemAvailable {
    if (self.isLockedState) {
        return NO;
    }
    return YES;
}

- (void)statisticsButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    if ([self isStatisticsButtonItemAvailable]) {
        XXTEEditorStatisticsViewController *statisticsController = [[XXTEEditorStatisticsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        statisticsController.editor = self;
        [self.navigationController pushViewController:statisticsController animated:YES];
    }
}

- (BOOL)isSettingsButtonItemAvailable {
    if (self.isLockedState) {
        return NO;
    }
    return YES;
}

- (void)settingsButtonItemTapped:(UIBarButtonItem *)sender {
    [self.textView resignFirstResponder];
    if ([self isSettingsButtonItemAvailable]) {
        XXTEEditorSettingsViewController *settingsController = [[XXTEEditorSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        settingsController.editor = self;
        [self.navigationController pushViewController:settingsController animated:YES];
    }
}

#pragma mark - UIPopoverPresentationControllerDelegate

XXTE_START_IGNORE_PARTIAL
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}
XXTE_END_IGNORE_PARTIAL

@end
