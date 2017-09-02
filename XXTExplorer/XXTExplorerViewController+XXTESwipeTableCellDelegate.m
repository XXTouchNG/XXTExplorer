//
//  XXTExplorerViewController+XXTESwipeTableCellDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTESwipeTableCellDelegate.h"
#import "XXTExplorerViewController+Shortcuts.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"

#import "XXTExplorerItemDetailViewController.h"
#import "XXTExplorerItemDetailNavigationController.h"

#import "XXTECommonNavigationController.h"

#import "XXTExplorerEntryService.h"

#import <objc/runtime.h>

#import <LGAlertView/LGAlertView.h>

#import "XXTExplorerEntryReader.h"
#import "XXTExplorerEntryBundleReader.h"

@interface XXTExplorerViewController () <LGAlertViewDelegate>

@end

@implementation XXTExplorerViewController (XXTESwipeTableCellDelegate)

#pragma mark - XXTESwipeTableCellDelegate

- (BOOL)swipeTableCell:(XXTESwipeTableCell *)cell canSwipe:(XXTESwipeDirection)direction fromPoint:(CGPoint)point {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (entryDetail) {
        return YES;
    }
    return NO;
}

- (BOOL)swipeTableCell:(XXTESwipeTableCell *)cell tappedButtonAtIndex:(NSInteger)index direction:(XXTESwipeDirection)direction fromExpansion:(BOOL)fromExpansion {
    [cell hideSwipeAnimated:YES];
    static char *const XXTESwipeButtonAction = "XXTESwipeButtonAction";
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    NSString *entryPath = entryDetail[XXTExplorerViewEntryAttributePath];
    NSString *entryName = entryDetail[XXTExplorerViewEntryAttributeName];
    if (direction == XXTESwipeDirectionLeftToRight) {
        XXTESwipeButton *button = cell.leftButtons[index];
        NSString *buttonAction = objc_getAssociatedObject(cell.leftButtons[index], XXTESwipeButtonAction);
        if ([buttonAction isEqualToString:@"Launch"]) {
            [self performAction:button launchScript:entryPath];
        } else if ([buttonAction isEqualToString:@"Property"]) {
            XXTExplorerItemDetailViewController *detailController = [[XXTExplorerItemDetailViewController alloc] initWithPath:entryPath];
            XXTExplorerItemDetailNavigationController *detailNavigationController = [[XXTExplorerItemDetailNavigationController alloc] initWithRootViewController:detailController];
            detailNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            detailNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self.navigationController presentViewController:detailNavigationController animated:YES completion:nil];
        } else if ([buttonAction isEqualToString:@"Inside"]) {
            if ([entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle]) {
                NSError *accessError = nil;
                [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&accessError];
                if (accessError) {
                    showUserMessage(self, [accessError localizedDescription]);
                } else {
                    XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:entryPath];
                    [self.navigationController pushViewController:explorerViewController animated:YES];
                }
            }
        } else if ([buttonAction isEqualToString:@"Configure"]) {
            if ([self.class.explorerEntryService hasConfiguratorForEntry:entryDetail]) {
                UIViewController *configurator = [self.class.explorerEntryService configuratorForEntry:entryDetail];
                if (configurator) {
                    if (XXTE_COLLAPSED) {
                        XXTE_START_IGNORE_PARTIAL
                        if (XXTE_SYSTEM_8) {
                            XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:configurator];
                            [self.splitViewController showDetailViewController:navigationController sender:self];
                        }
                        XXTE_END_IGNORE_PARTIAL
                    } else {
                        [self.navigationController pushViewController:configurator animated:YES];
                    }
                }
            } else {
                showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configurator can't be found.", nil), entryName]);
            }
        } else if ([buttonAction isEqualToString:@"Edit"]) {
            if (XXTE_SYSTEM_8) {
                if ([self.class.explorerEntryService hasEditorForEntry:entryDetail]) {
                    UIViewController *editor = [self.class.explorerEntryService editorForEntry:entryDetail];
                    if (editor) {
                        if (XXTE_COLLAPSED) {
                            XXTE_START_IGNORE_PARTIAL
                            if (XXTE_SYSTEM_8) {
                                XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:editor];
                                [self.splitViewController showDetailViewController:navigationController sender:self];
                            }
                            XXTE_END_IGNORE_PARTIAL
                        } else {
                            [self.navigationController pushViewController:editor animated:YES];
                        }
                    }
                } else {
                    showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be edited because its editor can't be found.", nil), entryName]);
                }
            } else {
                showUserMessage(self, NSLocalizedString(@"This feature is not supported.", nil));
            }
        }
    } else if (direction == XXTESwipeDirectionRightToLeft && index == 0) {
        NSString *buttonAction = objc_getAssociatedObject(cell.rightButtons[index], XXTESwipeButtonAction);
        if ([buttonAction isEqualToString:@"Trash"]) {
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Confirm", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Delete \"%@\"?\nThis operation cannot be revoked.", nil), entryDetail[XXTExplorerViewEntryAttributeName]]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[]
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            objc_setAssociatedObject(alertView, @selector(alertView:removeEntryCell:), cell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [alertView showAnimated:YES completionHandler:nil];
        }
    }
    return NO;
}

- (NSArray *)swipeTableCell:(XXTESwipeTableCell *)cell swipeButtonsForDirection:(XXTESwipeDirection)direction
              swipeSettings:(XXTESwipeSettings *)swipeSettings expansionSettings:(XXTESwipeExpansionSettings *)expansionSettings {
    static char *const XXTESwipeButtonAction = "XXTESwipeButtonAction";
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (direction == XXTESwipeDirectionLeftToRight) {
        NSMutableArray *swipeButtons = [[NSMutableArray alloc] init];
        id <XXTExplorerEntryReader> entryReader = entryDetail[XXTExplorerViewEntryAttributeEntryReader];
        id <XXTExplorerEntryBundleReader> entryBundleReader = entryDetail[XXTExplorerViewEntryAttributeEntryReader];
        if (entryReader.executable) {
            XXTESwipeButton *swipeLaunchButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconLaunch]
                                                                  backgroundColor:[XXTE_COLOR colorWithAlphaComponent:1.f]
                                                                           insets:UIEdgeInsetsMake(0, 24, 0, 24)];
            objc_setAssociatedObject(swipeLaunchButton, XXTESwipeButtonAction, @"Launch", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:swipeLaunchButton];
        }
        if ([entryBundleReader respondsToSelector:@selector(configurable)]) {
            if (entryBundleReader.configurable) {
                XXTESwipeButton *swipeConfigureButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconConfigure]
                                                                         backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.9f]
                                                                                  insets:UIEdgeInsetsMake(0, 24, 0, 24)];
                objc_setAssociatedObject(swipeConfigureButton, XXTESwipeButtonAction, @"Configure", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [swipeButtons addObject:swipeConfigureButton];
            }
        }
        if (entryReader.editable) {
            XXTESwipeButton *swipeEditButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconEdit]
                                                                backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.8f]
                                                                         insets:UIEdgeInsetsMake(0, 24, 0, 24)];
            objc_setAssociatedObject(swipeEditButton, XXTESwipeButtonAction, @"Edit", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:swipeEditButton];
        }
        if ([entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle]) {
            XXTESwipeButton *swipeInsideButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconInside]
                                                                  backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.8f]
                                                                           insets:UIEdgeInsetsMake(0, 24, 0, 24)];
            objc_setAssociatedObject(swipeInsideButton, XXTESwipeButtonAction, @"Inside", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:swipeInsideButton];
        }
        XXTESwipeButton *swipePropertyButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconProperty]
                                                                backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.6f]
                                                                         insets:UIEdgeInsetsMake(0, 24, 0, 24)];
        objc_setAssociatedObject(swipePropertyButton, XXTESwipeButtonAction, @"Property", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [swipeButtons addObject:swipePropertyButton];
        return swipeButtons;
    } else if (direction == XXTESwipeDirectionRightToLeft) {
        XXTESwipeButton *swipeTrashButton = [XXTESwipeButton buttonWithTitle:nil icon:[UIImage imageNamed:XXTExplorerActionIconTrash]
                                                             backgroundColor:XXTE_COLOR_DANGER
                                                                      insets:UIEdgeInsetsMake(0, 24, 0, 24)];
        objc_setAssociatedObject(swipeTrashButton, XXTESwipeButtonAction, @"Trash", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return @[swipeTrashButton];
    }
    return @[];
}

@end
