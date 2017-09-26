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

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"

#import "XXTExplorerItemDetailViewController.h"
#import "XXTExplorerItemDetailNavigationController.h"
#import "XXTECommonNavigationController.h"

#import <objc/runtime.h>
#import <LGAlertView/LGAlertView.h>

#import "XXTExplorerEntryReader.h"
#import "XXTExplorerEntryService.h"
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
    static char *const XXTESwipeButtonAction = "XXTESwipeButtonAction";
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    NSString *entryPath = entryDetail[XXTExplorerViewEntryAttributePath];
    NSString *entryName = entryDetail[XXTExplorerViewEntryAttributeName];
    
    {
        [cell hideSwipeAnimated:YES];
    }
    
    if (direction == XXTESwipeDirectionLeftToRight) {
        XXTESwipeButton *button = (XXTESwipeButton *)cell.leftButtons[index];
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
                    XXTECommonNavigationController *navigationController = [[XXTECommonNavigationController alloc] initWithRootViewController:configurator];
                    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
                    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
                } else {
                    showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configuration file can't be found or loaded.", nil), entryName]);
                }
            } else {
                showUserMessage(self, [NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configurator can't be found.", nil), entryName]);
            }
        } else if ([buttonAction isEqualToString:@"Edit"]) {
            if ([self.class.explorerEntryService hasEditorForEntry:entryDetail]) {
                UIViewController *editor = [self.class.explorerEntryService editorForEntry:entryDetail];
                if (editor) {
                    if (XXTE_COLLAPSED) {
                        XXTE_START_IGNORE_PARTIAL
                        if (@available(iOS 8.0, *)) {
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
    swipeSettings.transition = XXTESwipeTransitionBorder;
    expansionSettings.buttonIndex = 0;
    expansionSettings.fillOnTrigger = YES;
#ifdef DEBUG
    BOOL hidesLabel = XXTEDefaultsBool(XXTExplorerViewEntryHideOperationLabelKey, YES);
#else
    BOOL hidesLabel = XXTEDefaultsBool(XXTExplorerViewEntryHideOperationLabelKey, NO);
#endif
    UIEdgeInsets buttonInsets = hidesLabel ? UIEdgeInsetsMake(0, 24.0, 0, 24.0) : UIEdgeInsetsMake(0, 8.0, 0, 8.0);
    static char *const XXTESwipeButtonAction = "XXTESwipeButtonAction";
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (direction == XXTESwipeDirectionLeftToRight) {
        NSMutableArray *swipeButtons = [[NSMutableArray alloc] init];
        id <XXTExplorerEntryReader> entryReader = entryDetail[XXTExplorerViewEntryAttributeEntryReader];
        id <XXTExplorerEntryBundleReader> entryBundleReader = entryDetail[XXTExplorerViewEntryAttributeEntryReader];
        if (entryReader.executable) {
            NSString *buttonTitle = nil;
            if (!hidesLabel) {
                buttonTitle = NSLocalizedString(@"Launch", nil);
            }
            XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:XXTExplorerActionIconLaunch]
                                                       backgroundColor:[XXTE_COLOR colorWithAlphaComponent:1.f]
                                                                insets:buttonInsets];
            if (!hidesLabel) {
                button.titleLabel.font = [UIFont systemFontOfSize:12.f];
                [button centerIconOverText];
            }
            objc_setAssociatedObject(button, XXTESwipeButtonAction, @"Launch", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:button];
        }
        if ([entryBundleReader respondsToSelector:@selector(configurable)]) {
            if (entryBundleReader.configurable) {
                NSString *buttonTitle = nil;
                if (!hidesLabel) {
                    buttonTitle = NSLocalizedString(@"Configure", nil);
                }
                XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:XXTExplorerActionIconConfigure]
                                                           backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.9f]
                                                                    insets:buttonInsets];
                if (!hidesLabel) {
                    button.titleLabel.font = [UIFont systemFontOfSize:12.f];
                    [button centerIconOverText];
                }
                objc_setAssociatedObject(button, XXTESwipeButtonAction, @"Configure", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [swipeButtons addObject:button];
            }
        }
        if (entryReader.editable) {
            NSString *buttonTitle = nil;
            if (!hidesLabel) {
                buttonTitle = NSLocalizedString(@"Edit", nil);
            }
            XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:XXTExplorerActionIconEdit]
                                                       backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.8f]
                                                                insets:buttonInsets];
            if (!hidesLabel) {
                button.titleLabel.font = [UIFont systemFontOfSize:12.f];
                [button centerIconOverText];
            }
            objc_setAssociatedObject(button, XXTESwipeButtonAction, @"Edit", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:button];
        }
        if ([entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle]) {
            NSString *buttonTitle = nil;
            if (!hidesLabel) {
                buttonTitle = NSLocalizedString(@"Inside", nil);
            }
            XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:XXTExplorerActionIconInside]
                                                       backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.8f]
                                                                insets:buttonInsets];
            if (!hidesLabel) {
                button.titleLabel.font = [UIFont systemFontOfSize:12.f];
                [button centerIconOverText];
            }
            objc_setAssociatedObject(button, XXTESwipeButtonAction, @"Inside", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:button];
        }
        NSString *buttonTitle = nil;
        if (!hidesLabel) {
            buttonTitle = NSLocalizedString(@"Property", nil);
        }
        XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:XXTExplorerActionIconProperty]
                                                   backgroundColor:[XXTE_COLOR colorWithAlphaComponent:.6f]
                                                            insets:buttonInsets];
        if (!hidesLabel) {
            button.titleLabel.font = [UIFont systemFontOfSize:12.f];
            [button centerIconOverText];
        }
        objc_setAssociatedObject(button, XXTESwipeButtonAction, @"Property", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [swipeButtons addObject:button];
        return [swipeButtons copy];
    } else if (direction == XXTESwipeDirectionRightToLeft) {
        NSString *buttonTitle = nil;
        if (!hidesLabel) {
            buttonTitle = NSLocalizedString(@"Trash", nil);
        }
        XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:XXTExplorerActionIconTrash]
                                                   backgroundColor:XXTE_COLOR_DANGER
                                                            insets:buttonInsets];
        if (!hidesLabel) {
            button.titleLabel.font = [UIFont systemFontOfSize:12.f];
            [button centerIconOverText];
        }
        objc_setAssociatedObject(button, XXTESwipeButtonAction, @"Trash", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return @[button];
    }
    return @[];
}

@end
