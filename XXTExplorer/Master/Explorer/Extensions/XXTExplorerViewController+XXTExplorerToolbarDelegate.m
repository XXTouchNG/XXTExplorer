//
//  XXTExplorerViewController+XXTExplorerToolbarDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"
#import "XXTExplorerViewController+LGAlertViewDelegate.h"
#import "XXTExplorerViewController+PasteboardOperations.h"
#import "XXTExplorerViewController+UIDocumentMenuDelegate.h"
#import "XXTExplorerViewController+XXTImagePickerControllerDelegate.h"

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENotificationCenterDefines.h"

#import "XXTEScanViewController.h"
#import "XXTENavigationController.h"
#import "XXTExplorerCreateItemViewController.h"

#import <LGAlertView/LGAlertView.h>

#import <objc/runtime.h>
#import <objc/message.h>

#import "XXTExplorerViewController+XXTExplorerCreateItemViewControllerDelegate.h"

@interface XXTExplorerViewController ()

@end

@implementation XXTExplorerViewController (XXTExplorerToolbarDelegate)

- (void)configureToolbar {
    XXTExplorerToolbar *toolbar = [[XXTExplorerToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44.f)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    toolbar.tapDelegate = self;
    self.toolbar = toolbar;
    if (@available(iOS 11.0, *)) {
        [self.tableView setTableHeaderView:toolbar];
    } else {
        [self.view addSubview:toolbar];
    }
}

#pragma mark - XXTExplorerToolbar

- (void)updateToolbarButton {
    [self updateToolbarButton:self.toolbar];
}

- (void)updateToolbarStatus {
    [self updateToolbarStatus:self.toolbar];
}

- (void)updateToolbarButton:(XXTExplorerToolbar *)toolbar {
    if (XXTEDefaultsEnum(XXTExplorerViewEntryListSortOrderKey, XXTExplorerViewEntryListSortOrderAsc) == XXTExplorerViewEntryListSortOrderAsc) {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort status:XXTExplorerToolbarButtonStatusNormal enabled:YES];
    } else {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort status:XXTExplorerToolbarButtonStatusSelected enabled:YES];
    }
}

- (void)updateToolbarStatus:(XXTExplorerToolbar *)toolbar {
    if ([[[self class] explorerPasteboard] strings].count > 0) {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:YES];
    } else {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:NO];
    }
    if ([self isEditing]) {
        if (([self.tableView indexPathsForSelectedRows].count) > 0) {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeShare enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeCompress enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash enabled:YES];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:YES];
        } else {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeShare enabled:NO];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeCompress enabled:NO];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash enabled:NO];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:NO];
        }
    } else {
#ifndef APPSTORE
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeScan enabled:YES];
#endif
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeAddItem enabled:YES];
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort enabled:YES];
    }
}

#pragma mark - XXTExplorerToolbarDelegate

- (void)toolbar:(XXTExplorerToolbar *)toolbar buttonTypeTapped:(NSString *)buttonType buttonItem:(UIBarButtonItem *)buttonItem {
    if (toolbar == self.toolbar) {
#ifndef APPSTORE
        if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeScan]) {
            NSDictionary *userInfo =
            @{XXTENotificationShortcutInterface: @"scan",
              XXTENotificationShortcutUserData: [NSNull null]};
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:XXTENotificationShortcut object:buttonItem userInfo:userInfo]];
        }
#else
        if (NO) {
            
        }
#endif
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeAddItem]) {
            XXTE_START_IGNORE_PARTIAL
            if (@available(iOS 8.0, *)) {
                UIDocumentMenuViewController *controller = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeImport];
                controller.delegate = self;
                [controller addOptionWithTitle:NSLocalizedString(@"Photos Library", nil)
                                         image:nil
                                         order:UIDocumentMenuOrderFirst
                                       handler:^{
                                           [self presentImagePickerController:buttonItem];
                                       }];
                [controller addOptionWithTitle:NSLocalizedString(@"New Item", nil)
                                         image:nil
                                         order:UIDocumentMenuOrderFirst
                                       handler:^{
                                           [self presentNewDocumentViewController:buttonItem];
                                       }];
                controller.modalPresentationStyle = UIModalPresentationPopover;
                UIPopoverPresentationController *popoverController = controller.popoverPresentationController;
                popoverController.barButtonItem = buttonItem;
                popoverController.backgroundColor = [UIColor whiteColor];
                [self.navigationController presentViewController:controller animated:YES completion:nil];
            } else {
                [self presentNewDocumentViewController:buttonItem];
            }
            XXTE_END_IGNORE_PARTIAL
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeSort]) {
            if (XXTEDefaultsEnum(XXTExplorerViewEntryListSortOrderKey, XXTExplorerViewEntryListSortOrderAsc) != XXTExplorerViewEntryListSortOrderAsc) {
                XXTEDefaultsSetBasic(XXTExplorerViewEntryListSortOrderKey, XXTExplorerViewEntryListSortOrderAsc);
                XXTEDefaultsSetObject(XXTExplorerViewEntryListSortFieldKey, XXTExplorerViewEntryAttributeName);
            } else {
                XXTEDefaultsSetBasic(XXTExplorerViewEntryListSortOrderKey, XXTExplorerViewEntryListSortOrderDesc);
                XXTEDefaultsSetObject(XXTExplorerViewEntryListSortFieldKey, XXTExplorerViewEntryAttributeCreationDate);
            }
            [self updateToolbarButton];
            [self loadEntryListData];
            [self.tableView reloadData];
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypePaste]) {
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            if (!selectedIndexPaths) {
                selectedIndexPaths = @[];
            }
            NSString *formatString = nil;
            if (selectedIndexPaths.count == 1) {
                NSIndexPath *firstIndexPath = selectedIndexPaths[0];
                NSDictionary *firstAttributes = self.entryList[(NSUInteger) firstIndexPath.row];
                formatString = [NSString stringWithFormat:NSLocalizedString(@"\"%@\"", nil), firstAttributes[XXTExplorerViewEntryAttributeName]];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), selectedIndexPaths.count];
            }
            BOOL clearEnabled = NO;
            NSArray <NSString *> *pasteboardArray = [self.class.explorerPasteboard strings];
            NSUInteger pasteboardCount = pasteboardArray.count;
            NSString *pasteboardFormatString = nil;
            if (pasteboardCount == 0) {
                pasteboardFormatString = NSLocalizedString(@"No item", nil);
                clearEnabled = NO;
            } else {
                if (pasteboardCount == 1) {
                    pasteboardFormatString = NSLocalizedString(@"1 item", nil);
                } else {
                    pasteboardFormatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), pasteboardCount];
                }
                clearEnabled = YES;
            }
            if ([self isEditing]) {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Pasteboard", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"%@ stored.", nil), pasteboardFormatString]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[
                                                                              [NSString stringWithFormat:NSLocalizedString(@"Copy %@", nil), formatString]
                                                                              ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clear Pasteboard", nil)
                                                                   delegate:self];
                alertView.buttonsTextAlignment = NSTextAlignmentLeft;
                alertView.destructiveButtonEnabled = clearEnabled;
                alertView.buttonsIconImages = @[[UIImage imageNamed:XXTExplorerAlertViewActionPasteboardExportCopy]];
                objc_setAssociatedObject(alertView, [XXTExplorerAlertViewAction UTF8String], XXTExplorerAlertViewActionPasteboardImport, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(alertView, [XXTExplorerAlertViewContext UTF8String], selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(alertView, @selector(alertView:clearPasteboardEntriesStored:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated];
            } else {
                NSString *entryName = [self.entryPath lastPathComponent];
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Pasteboard", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"%@ stored.", nil), pasteboardFormatString]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[
                                                                              [NSString stringWithFormat:NSLocalizedString(@"Paste to \"%@\"", nil), entryName],
                                                                              [NSString stringWithFormat:NSLocalizedString(@"Move to \"%@\"", nil), entryName],
                                                                              [NSString stringWithFormat:NSLocalizedString(@"Create Link at \"%@\"", nil), entryName]
                                                                              ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Clear Pasteboard", nil)
                                                                   delegate:self];
                alertView.buttonsTextAlignment = NSTextAlignmentLeft;
                alertView.destructiveButtonEnabled = clearEnabled;
                alertView.buttonsEnabled = (pasteboardCount != 0);
                alertView.buttonsIconImages = @[[UIImage imageNamed:XXTExplorerAlertViewActionPasteboardExportPaste], [UIImage imageNamed:XXTExplorerAlertViewActionPasteboardExportCut], [UIImage imageNamed:XXTExplorerAlertViewActionPasteboardExportLink]];
                objc_setAssociatedObject(alertView, [XXTExplorerAlertViewAction UTF8String], XXTExplorerAlertViewActionPasteboardExport, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(alertView, [XXTExplorerAlertViewContext UTF8String], self.entryPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(alertView, @selector(alertView:clearPasteboardEntriesStored:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated];
            }
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeCompress]) {
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            BOOL isXPP = NO;
            NSString *formatString = nil;
            if (selectedIndexPaths.count == 1) {
                NSIndexPath *firstIndexPath = selectedIndexPaths[0];
                NSDictionary *firstAttributes = self.entryList[(NSUInteger) firstIndexPath.row];
                NSString *entryBaseExtension = [firstAttributes[XXTExplorerViewEntryAttributeExtension] lowercaseString];
                if ([entryBaseExtension isEqualToString:@"xpp"]) {
                    isXPP = YES;
                }
                formatString = [NSString stringWithFormat:@"\"%@\"", firstAttributes[XXTExplorerViewEntryAttributeName]];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), selectedIndexPaths.count];
            }
            NSArray *buttonTitles = nil;
            if (isXPP) {
                buttonTitles = @[ NSLocalizedString(@"Create Package", nil) ];
            } else {
                buttonTitles = @[ ];
            }
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Archive Confirm", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Archive %@?", nil), formatString]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:buttonTitles
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            if (isXPP) {
                objc_setAssociatedObject(alertView, @selector(alertView:archivePackageEntriesAtIndexPaths:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            } else {
                objc_setAssociatedObject(alertView, @selector(alertView:archiveEntriesAtIndexPaths:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            [alertView showAnimated:YES completionHandler:nil];
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeShare]) {
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            NSMutableArray <NSURL *> *shareUrls = [[NSMutableArray alloc] init];
            for (NSIndexPath *indexPath in selectedIndexPaths) {
                NSDictionary *entryDetail = self.entryList[indexPath.row];
                if ([entryDetail[XXTExplorerViewEntryAttributeType] isEqualToString:XXTExplorerViewEntryAttributeTypeDirectory]) {
                    [shareUrls removeAllObjects];
                    break;
                } else {
                    [shareUrls addObject:[NSURL fileURLWithPath:entryDetail[XXTExplorerViewEntryAttributePath]]];
                }
            }
            if (shareUrls.count != 0) {
                XXTE_START_IGNORE_PARTIAL
                if (@available(iOS 8.0, *)) {
                    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:shareUrls applicationActivities:nil];
                    activityViewController.modalPresentationStyle = UIModalPresentationPopover;
                    UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
                    popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                    popoverPresentationController.barButtonItem = buttonItem;
                    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
                } else {
                    toastMessage(self, NSLocalizedString(@"This feature is not supported.", nil));
                }
                XXTE_END_IGNORE_PARTIAL
            } else {
                toastMessage(self, NSLocalizedString(@"You cannot share directory.", nil));
            }
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeTrash]) {
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            NSString *formatString = nil;
            if (selectedIndexPaths.count == 1) {
                NSIndexPath *firstIndexPath = selectedIndexPaths[0];
                NSDictionary *firstAttributes = self.entryList[(NSUInteger) firstIndexPath.row];
                formatString = [NSString stringWithFormat:@"\"%@\"", firstAttributes[XXTExplorerViewEntryAttributeName]];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), selectedIndexPaths.count];
            }
            LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Confirm", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Delete %@?\nThis operation cannot be revoked.", nil), formatString]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[ ]
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            objc_setAssociatedObject(alertView, @selector(alertView:removeEntriesAtIndexPaths:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [alertView showAnimated:YES completionHandler:nil];
        }
    }
}

- (void)presentNewDocumentViewController:(UIBarButtonItem *)buttonItem {
    XXTExplorerCreateItemViewController *createItemViewController = [[XXTExplorerCreateItemViewController alloc] initWithEntryPath:self.entryPath];
    createItemViewController.delegate = self;
    XXTENavigationController *createItemNavigationController = [[XXTENavigationController alloc] initWithRootViewController:createItemViewController];
    createItemNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    createItemNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController presentViewController:createItemNavigationController animated:YES completion:nil];
}

@end
