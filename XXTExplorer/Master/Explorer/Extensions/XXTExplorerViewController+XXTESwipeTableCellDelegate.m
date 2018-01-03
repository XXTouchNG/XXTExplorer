//
//  XXTExplorerViewController+XXTESwipeTableCellDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTESwipeTableCellDelegate.h"
#import "XXTExplorerViewController+SharedInstance.h"
#import "XXTExplorerViewController+FileOperation.h"
#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"
#import "XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.h"

#import "XXTExplorerDefaults.h"
#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENotificationCenterDefines.h"

#import "XXTExplorerItemDetailViewController.h"
#import "XXTENavigationController.h"

#import <objc/runtime.h>
#import <LGAlertView/LGAlertView.h>

#import "XXTExplorerEntryReader.h"
#import "XXTExplorerEntryService.h"

#import "XXTExplorerViewCell.h"

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
    NSString *buttonAction = nil;
    if (direction == XXTESwipeDirectionLeftToRight) {
        buttonAction = objc_getAssociatedObject(cell.leftButtons[index], XXTESwipeButtonAction);
    } else if (direction == XXTESwipeDirectionRightToLeft && index == 0) {
        buttonAction = objc_getAssociatedObject(cell.rightButtons[index], XXTESwipeButtonAction);
    }
    return [self performButtonAction:buttonAction forEntryCell:cell];
}

- (BOOL)performButtonAction:(NSString *)buttonAction forEntryCell:(XXTESwipeTableCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    BOOL handled = NO;
    if (!handled) {
        handled = [self performUnchangedButtonAction:buttonAction forEntry:entryDetail];
    }
    if (!handled) {
        if ([buttonAction isEqualToString:XXTExplorerEntryButtonActionTrash]) {
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Confirm", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Delete \"%@\"?\nThis operation cannot be revoked.", nil), entryDetail[XXTExplorerViewEntryAttributeName]]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[ ]
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            objc_setAssociatedObject(alertView, @selector(alertView:removeEntryCell:), cell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [alertView showAnimated:YES completionHandler:nil];
            handled = YES;
        }
    }
    return handled;
}

- (BOOL)performUnchangedButtonAction:(NSString *)buttonAction forEntry:(NSDictionary *)entryDetail {
    BOOL handled = NO;
    NSString *entryPath = entryDetail[XXTExplorerViewEntryAttributePath];
    NSString *entryName = entryDetail[XXTExplorerViewEntryAttributeName];
    if ([buttonAction isEqualToString:XXTExplorerEntryButtonActionLaunch]) {
#ifndef APPSTORE
        NSDictionary *userInfo =
        @{XXTENotificationShortcutInterface: @"launch",
          XXTENotificationShortcutUserData: @{ @"path": (entryPath ? entryPath : [NSNull null]) }};
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationShortcut object:nil userInfo:userInfo]];
#endif
        handled = YES;
    }
    else if ([buttonAction isEqualToString:XXTExplorerEntryButtonActionProperty]) {
        XXTExplorerItemDetailViewController *detailController = [[XXTExplorerItemDetailViewController alloc] initWithPath:entryPath];
        XXTENavigationController *detailNavigationController = [[XXTENavigationController alloc] initWithRootViewController:detailController];
        detailNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        detailNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.navigationController presentViewController:detailNavigationController animated:YES completion:nil];
        handled = YES;
    }
    else if ([buttonAction isEqualToString:XXTExplorerEntryButtonActionInside]) {
        if ([entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle]) {
            NSError *accessError = nil;
            [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&accessError];
            if (accessError) {
                toastMessage(self, [accessError localizedDescription]);
            } else {
                XXTExplorerViewController *explorerViewController = [[XXTExplorerViewController alloc] initWithEntryPath:entryPath];
                [self.navigationController pushViewController:explorerViewController animated:YES];
            }
        }
        handled = YES;
    }
    else if ([buttonAction isEqualToString:XXTExplorerEntryButtonActionConfigure]) {
        if ([self.class.explorerEntryService hasConfiguratorForEntry:entryDetail]) {
            UIViewController *configurator = [self.class.explorerEntryService configuratorForEntry:entryDetail];
            if (configurator) {
                [self tableView:self.tableView showFormSheetController:configurator];
            } else {
                toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configuration file can't be found or loaded.", nil), entryName]));
            }
        } else {
            toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be configured because its configurator can't be found.", nil), entryName]));
        }
        handled = YES;
    }
    else if ([buttonAction isEqualToString:XXTExplorerEntryButtonActionEdit]) {
        if ([self.class.explorerEntryService hasEditorForEntry:entryDetail]) {
            UIViewController <XXTEEditor> *editor = [self.class.explorerEntryService editorForEntry:entryDetail];
            if (editor) {
                [self tableView:self.tableView showDetailController:editor];
            }
        } else {
            toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"File \"%@\" can't be edited because its editor can't be found.", nil), entryName]));
        }
        handled = YES;
    }
    else if ([buttonAction isEqualToString:XXTExplorerEntryButtonActionEncrypt]) {
#ifndef APPSTORE
        LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Encrypt Confirm", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Complie and encrypt \"%@\"?\nEncrypted script will be saved to current directory.", nil), entryDetail[XXTExplorerViewEntryAttributeName]]
                                                              style:LGAlertViewStyleActionSheet
                                                       buttonTitles:@[ ]
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                             destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                           delegate:self];
        objc_setAssociatedObject(alertView, @selector(alertView:encryptEntry:), entryDetail, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [alertView showAnimated:YES completionHandler:nil];
#endif
        handled = YES;
    }
    return handled;
}

- (NSArray *)swipeTableCell:(XXTESwipeTableCell *)cell swipeButtonsForDirection:(XXTESwipeDirection)direction
              swipeSettings:(XXTESwipeSettings *)swipeSettings expansionSettings:(XXTESwipeExpansionSettings *)expansionSettings {
    CGFloat buttonWidth = 80.0;
    cell.allowsButtonsWithDifferentWidth = YES;
    swipeSettings.transition = XXTESwipeTransitionBorder;
    expansionSettings.buttonIndex = 0;
    expansionSettings.fillOnTrigger = NO;
    BOOL hidesLabel = XXTEDefaultsBool(XXTExplorerViewEntryHideOperationLabelKey, NO);
    UIEdgeInsets buttonInsets = hidesLabel ? UIEdgeInsetsMake(0, 24.0, 0, 24.0) : UIEdgeInsetsMake(0, 8.0, 0, 8.0);
    static char *const XXTESwipeButtonAction = "XXTESwipeButtonAction";
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    if (direction == XXTESwipeDirectionLeftToRight) {
        NSMutableArray *swipeButtons = [[NSMutableArray alloc] init];
        XXTExplorerEntryReader *entryReader = entryDetail[XXTExplorerViewEntryAttributeEntryReader];
        UIColor *colorSeries = XXTE_COLOR;
#ifndef APPSTORE
        if (entryReader.executable) {
            NSString *buttonTitle = nil;
            if (!hidesLabel) {
                buttonTitle = NSLocalizedString(@"Launch", nil);
            } else {
                buttonTitle = @"";
            }
            XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:@"XXTExplorerActionIconLaunch"]
                                                       backgroundColor:colorSeries
                                                                insets:buttonInsets];
            objc_setAssociatedObject(button, XXTESwipeButtonAction, XXTExplorerEntryButtonActionLaunch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:button];
        }
#endif
        if ([entryReader respondsToSelector:@selector(configurable)]) {
            if (entryReader.configurable) {
                NSString *buttonTitle = nil;
                if (!hidesLabel) {
                    buttonTitle = NSLocalizedString(@"Configure", nil);
                } else {
                    buttonTitle = @"";
                }
                XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:@"XXTExplorerActionIconConfigure"]
                                                           backgroundColor:colorSeries
                                                                    insets:buttonInsets];
                objc_setAssociatedObject(button, XXTESwipeButtonAction, XXTExplorerEntryButtonActionConfigure, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [swipeButtons addObject:button];
            }
        }
        if (entryReader.editable) {
            NSString *buttonTitle = nil;
            if (!hidesLabel) {
                buttonTitle = NSLocalizedString(@"Edit", nil);
            } else {
                buttonTitle = @"";
            }
            XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:@"XXTExplorerActionIconEdit"]
                                                       backgroundColor:colorSeries
                                                                insets:buttonInsets];
            objc_setAssociatedObject(button, XXTESwipeButtonAction, XXTExplorerEntryButtonActionEdit, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:button];
        }
        if ([entryDetail[XXTExplorerViewEntryAttributeMaskType] isEqualToString:XXTExplorerViewEntryAttributeMaskTypeBundle]) {
            NSString *buttonTitle = nil;
            if (!hidesLabel) {
                buttonTitle = NSLocalizedString(@"Inside", nil);
            } else {
                buttonTitle = @"";
            }
            XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:@"XXTExplorerActionIconInside"]
                                                       backgroundColor:colorSeries
                                                                insets:buttonInsets];
            objc_setAssociatedObject(button, XXTESwipeButtonAction, XXTExplorerEntryButtonActionInside, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:button];
        }
#ifndef APPSTORE
        if (entryReader.encryptionType != XXTExplorerEntryReaderEncryptionTypeNone)
        {
            NSString *buttonTitle = nil;
            if (!hidesLabel) {
                buttonTitle = NSLocalizedString(@"Encrypt", nil);
            } else {
                buttonTitle = @"";
            }
            XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:@"XXTExplorerActionIconEncrypt"]
                                                       backgroundColor:colorSeries
                                                                insets:buttonInsets];
            objc_setAssociatedObject(button, XXTESwipeButtonAction, XXTExplorerEntryButtonActionEncrypt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [swipeButtons addObject:button];
        }
#endif
        NSString *buttonTitle = nil;
        if (!hidesLabel) {
            buttonTitle = NSLocalizedString(@"Property", nil);
        } else {
            buttonTitle = @"";
        }
        XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:@"XXTExplorerActionIconProperty"]
                                                   backgroundColor:colorSeries
                                                            insets:buttonInsets];
        objc_setAssociatedObject(button, XXTESwipeButtonAction, XXTExplorerEntryButtonActionProperty, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [swipeButtons addObject:button];
        
        CGFloat stepValue = 0.6 / swipeButtons.count;
        for (NSUInteger idx = 0; idx < swipeButtons.count; idx++) {
            XXTESwipeButton *buttonItem = swipeButtons[idx];
            if (!hidesLabel) {
                buttonItem.titleLabel.font = [UIFont systemFontOfSize:12.f];
                [buttonItem centerIconOverText];
            }
            buttonItem.buttonWidth = buttonWidth;
            buttonItem.backgroundColor = [colorSeries colorWithAlphaComponent:(1.0 - stepValue * idx)];
        }
        
        return [swipeButtons copy];
    } else if (direction == XXTESwipeDirectionRightToLeft) {
        NSString *buttonTitle = nil;
        if (!hidesLabel) {
            buttonTitle = NSLocalizedString(@"Trash", nil);
        } else {
            buttonTitle = @"";
        }
        XXTESwipeButton *button = [XXTESwipeButton buttonWithTitle:buttonTitle icon:[UIImage imageNamed:@"XXTExplorerActionIconTrash"]
                                                   backgroundColor:XXTE_COLOR_DANGER
                                                            insets:buttonInsets];
        if (!hidesLabel) {
            button.titleLabel.font = [UIFont systemFontOfSize:12.f];
            [button centerIconOverText];
        }
        button.buttonWidth = buttonWidth;
        objc_setAssociatedObject(button, XXTESwipeButtonAction, XXTExplorerEntryButtonActionTrash, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return @[button];
    }
    return @[];
}

@end
