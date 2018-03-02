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
#import "XXTExplorerViewController+ArchiverOperation.h"

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTENotificationCenterDefines.h"

#import "XXTEScanViewController.h"
#import "XXTENavigationController.h"
#import "XXTExplorerCreateItemViewController.h"
#import "XXTEMoreViewController.h"
#import "XXTEMoreNavigationController.h"

#import <LGAlertView/LGAlertView.h>

#import <objc/runtime.h>
#import <objc/message.h>

#import "XXTExplorerViewController+XXTExplorerCreateItemViewControllerDelegate.h"
#import "XXTExplorerViewController+SharedInstance.h"
#import "XXTExplorerEntryParser.h"

#import "XXTEDispatchDefines.h"

@interface XXTExplorerViewController ()

@end

@implementation XXTExplorerViewController (XXTExplorerToolbarDelegate)

- (void)configureToolbar {
    if (self.isPreviewed) return;
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
    {
        BOOL sortEnabled = (self.historyMode == NO);
        if (self.explorerSortOrder == XXTExplorerViewEntryListSortOrderAsc) {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort status:XXTExplorerToolbarButtonStatusNormal enabled:sortEnabled];
        } else {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort status:XXTExplorerToolbarButtonStatusSelected enabled:sortEnabled];
        }
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
            if (self.historyMode) {
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash enabled:YES];
            } else {
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash enabled:NO];
            }
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste enabled:NO];
        }
    } else {
#ifndef APPSTORE
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeScan enabled:YES];
#else
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSettings enabled:YES];
#endif
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeAddItem enabled:YES];
        if (self.historyMode) {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort enabled:NO];
        } else {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort enabled:YES];
        }
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
        if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeSettings]) {
            XXTEMoreViewController *moreViewController = [[XXTEMoreViewController alloc] initWithStyle:UITableViewStyleGrouped];
            XXTEMoreNavigationController *masterNavigationControllerRight = [[XXTEMoreNavigationController alloc] initWithRootViewController:moreViewController];
            masterNavigationControllerRight.modalPresentationStyle = UIModalPresentationFormSheet;
            masterNavigationControllerRight.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self.navigationController presentViewController:masterNavigationControllerRight animated:YES completion:nil];
        }
#endif
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeAddItem]) {
            BOOL allowsImport = XXTEDefaultsBool(XXTExplorerAllowsImportFromAlbum, YES);
            if (allowsImport) {
                XXTE_START_IGNORE_PARTIAL
                if (@available(iOS 8.0, *)) {
                    UIDocumentMenuViewController *controller = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[@"public.data"] inMode:UIDocumentPickerModeImport];
                    controller.delegate = self;
                    if (!self.historyMode) {
                        [controller addOptionWithTitle:NSLocalizedString(@"View History", nil)
                                                 image:nil
                                                 order:UIDocumentMenuOrderFirst
                                               handler:^{
                                                   [self presentHistoryViewController:buttonItem];
                                               }];
                    }
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
            } else {
                [self presentNewDocumentViewController:buttonItem];
            }
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeSort]) {
            if (self.explorerSortOrder != XXTExplorerViewEntryListSortOrderAsc) {
                self.explorerSortField = XXTExplorerViewEntryListSortFieldDisplayName;
                self.explorerSortOrder = XXTExplorerViewEntryListSortOrderAsc;
                toastMessage(self, NSLocalizedString(@"Sort by Name Ascend", nil));
            } else {
                self.explorerSortField = XXTExplorerViewEntryListSortFieldModificationDate;
                self.explorerSortOrder = XXTExplorerViewEntryListSortOrderDesc;
                toastMessage(self, NSLocalizedString(@"Sort by Modification Date Descend", nil));
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
                XXTExplorerEntry *firstAttributes = self.entryList[(NSUInteger) firstIndexPath.row];
                formatString = [NSString stringWithFormat:NSLocalizedString(@"\"%@\"", nil), firstAttributes.localizedDisplayName];
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
                XXTExplorerEntry *firstAttributes = self.entryList[(NSUInteger) firstIndexPath.row];
                NSString *entryExtension = firstAttributes.entryExtension;
                NSString *entryBaseExtension = [entryExtension lowercaseString];
                if (firstAttributes.isDirectory &&
                    [entryBaseExtension isEqualToString:@"xpp"]) {
                    isXPP = YES;
                }
                formatString = [NSString stringWithFormat:@"\"%@\"", firstAttributes.localizedDisplayName];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), selectedIndexPaths.count];
            }
            if (isXPP) {
                // XPP Bundle, jump to archive without confirm.
                [self alertView:nil archiveEntriesAtIndexPaths:selectedIndexPaths];
            } else {
                LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Archive Confirm", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Archive %@?", nil), formatString]
                                                                      style:LGAlertViewStyleActionSheet
                                                               buttonTitles:@[ ]
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                     destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                                   delegate:self];
                objc_setAssociatedObject(alertView, @selector(alertView:archiveEntriesAtIndexPaths:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [alertView showAnimated:YES completionHandler:nil];
            }
        }
        else if ([buttonType isEqualToString:XXTExplorerToolbarButtonTypeShare]) {
            NSArray <NSIndexPath *> *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
            NSMutableArray <NSURL *> *shareUrls = [[NSMutableArray alloc] init];
            for (NSIndexPath *indexPath in selectedIndexPaths) {
                XXTExplorerEntry *entryDetail = self.entryList[indexPath.row];
                if (entryDetail.isDirectory) {
                    [shareUrls removeAllObjects];
                    break;
                } else {
                    if (entryDetail.entryPath) {
                        NSURL *url = [NSURL fileURLWithPath:entryDetail.entryPath];
                        if (url) {
                            [shareUrls addObject:url];
                        }
                    }
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
            if (self.historyMode) {
                if (selectedIndexPaths.count == 0) {
                    LGAlertView *alertViewClear = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Clear Confirm", nil)
                                                                              message:NSLocalizedString(@"Clear all history?\nThis operation cannot be revoked.", nil)
                                                                                style:LGAlertViewStyleActionSheet
                                                                         buttonTitles:@[ ]
                                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                               destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                                       actionHandler:nil cancelHandler:^(LGAlertView * _Nonnull alertView1) {
                                                                           [alertView1 dismissAnimated];
                                                                       } destructiveHandler:^(LGAlertView * _Nonnull alertView1) {
                                                                           [alertView1 dismissAnimated];
                                                                           [self removeAllEntryContents];
                                                                       }];
                    [alertViewClear showAnimated];
                    return;
                }
            }
            NSString *formatString = nil;
            if (selectedIndexPaths.count == 1) {
                NSIndexPath *firstIndexPath = selectedIndexPaths[0];
                XXTExplorerEntry *firstAttributes = self.entryList[(NSUInteger) firstIndexPath.row];
                formatString = [NSString stringWithFormat:@"\"%@\"", firstAttributes.localizedDisplayName];
            } else {
                formatString = [NSString stringWithFormat:NSLocalizedString(@"%d items", nil), selectedIndexPaths.count];
            }
            LGAlertView *alertViewDelete = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Delete Confirm", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Delete %@?\nThis operation cannot be revoked.", nil), formatString]
                                                                  style:LGAlertViewStyleActionSheet
                                                           buttonTitles:@[ ]
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                               delegate:self];
            objc_setAssociatedObject(alertViewDelete, @selector(alertView:removeEntriesAtIndexPaths:), selectedIndexPaths, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [alertViewDelete showAnimated:YES completionHandler:nil];
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

- (void)presentHistoryViewController:(UIBarButtonItem *)buttonItem {
    NSString *historyRelativePath = uAppDefine(XXTExplorerViewBuiltHistoryPath);
    NSString *historyPath = [[XXTEAppDelegate sharedRootPath] stringByAppendingPathComponent:historyRelativePath];
    NSError *entryError = nil;
    XXTExplorerEntry *entryDetail = [[self.class explorerEntryParser] entryOfPath:historyPath withError:&entryError];
    if (!entryError) {
        [self performHistoryActionForEntry:entryDetail];
    } else {
        toastMessage(self, entryError.localizedDescription);
    }
}

- (void)removeAllEntryContents {
    if (!self.historyMode) {
        return;
    }
    NSString *entryPath = self.entryPath;
    NSError *localError = nil;
    NSArray <NSString *> *entrySubdirectoryPathList = [self.class.explorerFileManager contentsOfDirectoryAtPath:entryPath error:&localError];
    if (localError) {
        toastMessage(self, localError.localizedDescription);
        return;
    }
    [self setEditing:NO animated:YES];
    UIViewController *blockController = blockInteractions(self, YES);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        for (NSString *entrySubdirectoryName in entrySubdirectoryPathList) {
            @autoreleasepool {
                NSError *removeError = nil;
                NSString *entrySubdirectoryPath = [self.entryPath stringByAppendingPathComponent:entrySubdirectoryName];
                BOOL removeResult = [self.class.explorerFileManager removeItemAtPath:entrySubdirectoryPath error:&removeError];
                if (!removeResult) {
                    
                }
            }
        }
        dispatch_async_on_main_queue(^{
            [self loadEntryListData];
            [self.tableView reloadData];
            blockInteractions(blockController, NO);
        });
    });
}

@end
