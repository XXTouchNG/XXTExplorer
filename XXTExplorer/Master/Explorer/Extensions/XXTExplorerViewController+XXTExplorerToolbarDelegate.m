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

#import "XXTExplorerDefaults.h"

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


@interface XXTExplorerViewController ()

@end

@implementation XXTExplorerViewController (XXTExplorerToolbarDelegate)

- (void)configureToolbarAndCover {
    if (self.isPreviewed) return;
    
#ifndef APPSTORE
    CGRect toolbarRect = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 44.f);
#else
    CGRect toolbarRect = CGRectMake(0.0, CGRectGetHeight(self.view.bounds) - 44.0, CGRectGetWidth(self.view.bounds), 44.f);
#endif
    
    XXTExplorerToolbar *toolbar = [[XXTExplorerToolbar alloc] initWithFrame:toolbarRect];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    toolbar.tapDelegate = self;
    if (self.historyMode) {
        [toolbar updateStatus:XXTExplorerToolbarStatusHistoryMode];
    } else {
        [toolbar updateStatus:XXTExplorerToolbarStatusDefault];
    }
    self.toolbar = toolbar;
    
    UILabel *toolbarCover = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.bounds), 44.f)];
    toolbarCover.textAlignment = NSTextAlignmentCenter;
    toolbarCover.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    toolbarCover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    toolbarCover.hidden = YES;
    UIFont *font = [UIFont systemFontOfSize:14.0];
    toolbarCover.font = font;
    toolbarCover.textColor = XXTColorForeground();
    toolbarCover.text = NSLocalizedString(@"Drop to parent directory", nil);
    self.toolbarCover = toolbarCover;
    
    [toolbar addSubview:toolbarCover];
    [self.view addSubview:toolbar];
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
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort toStatus:XXTExplorerToolbarButtonStatusNormal toEnabled:@(sortEnabled)];
        } else {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort toStatus:XXTExplorerToolbarButtonStatusSelected toEnabled:@(sortEnabled)];
        }
    }
}

- (void)updateToolbarStatus:(XXTExplorerToolbar *)toolbar {
    // Pasteboard
    if (self.historyMode) {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste toEnabled:@(NO)];
    } else {
        if ([[[self class] explorerPasteboard] strings].count > 0) {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste toEnabled:@(YES)];
        } else {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste toEnabled:@(NO)];
        }
    }
    
    // Editing Related
    if (self.historyMode) {
        [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash toEnabled:@(YES)];
#ifdef APPSTORE
        if ([self isEditing]) {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSettings toEnabled:@(NO)];
        } else {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSettings toEnabled:@(YES)];
        }
#endif
    } else {
        if ([self isEditing]) {
            if (([self.tableView indexPathsForSelectedRows].count) > 0) {
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypeShare toEnabled:@(YES)];
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypeCompress toEnabled:@(YES)];
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste toEnabled:@(YES)];
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash toEnabled:@(YES)];
            } else {
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypeShare toEnabled:@(NO)];
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypeCompress toEnabled:@(NO)];
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypePaste toEnabled:@(NO)];
                [toolbar updateButtonType:XXTExplorerToolbarButtonTypeTrash toEnabled:@(NO)];
            }
        } else {
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeAddItem toEnabled:@(YES)];
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSort toEnabled:@(YES)];
#ifndef APPSTORE
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeScan toEnabled:@(YES)];
#else
            [toolbar updateButtonType:XXTExplorerToolbarButtonTypeSettings toEnabled:@(YES)];
#endif
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
            XXTEMoreViewController *moreViewController = nil;
            if (@available(iOS 13.0, *)) {
                moreViewController = [[XXTEMoreViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
            } else {
                moreViewController = [[XXTEMoreViewController alloc] initWithStyle:UITableViewStyleGrouped];
            }
            XXTEMoreNavigationController *masterNavigationControllerRight = [[XXTEMoreNavigationController alloc] initWithRootViewController:moreViewController];
            masterNavigationControllerRight.modalPresentationStyle = UIModalPresentationFormSheet;
            masterNavigationControllerRight.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            masterNavigationControllerRight.presentationController.delegate = self;
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
                                                 image:[UIImage imageNamed:@"XXTEAddOptionHistory"]
                                                 order:UIDocumentMenuOrderFirst
                                               handler:^{
                            [self presentHistoryViewController:buttonItem];
                        }];
                    }
                    [controller addOptionWithTitle:NSLocalizedString(@"Photos Library", nil)
                                             image:[UIImage imageNamed:@"XXTEAddOptionPhotosLibrary"]
                                             order:UIDocumentMenuOrderFirst
                                           handler:^{
                        [self presentImagePickerController:buttonItem];
                    }];
                    [controller addOptionWithTitle:NSLocalizedString(@"New Item", nil)
                                             image:[UIImage imageNamed:@"XXTEAddOptionNew"]
                                             order:UIDocumentMenuOrderFirst
                                           handler:^{
                        [self presentNewDocumentViewController:buttonItem];
                    }];
                    controller.modalPresentationStyle = UIModalPresentationPopover;
                    UIPopoverPresentationController *popoverController = controller.popoverPresentationController;
                    popoverController.barButtonItem = buttonItem;
                    popoverController.backgroundColor = XXTColorPlainBackground();
                    controller.presentationController.delegate = self;
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
            XXTExplorerViewEntryListSortField sortFieldIdx = self.explorerSortField;
            XXTExplorerViewEntryListSortOrder sortOrderIdx = self.explorerSortOrder;
            @weakify(self);
            LGAlertView *sortAlert = [LGAlertView alertViewWithTitle:NSLocalizedString(@"Sort By", nil)
                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Currently sorted by %@, %@.", nil), XXTELocalizedNameForSortField(sortFieldIdx), XXTELocalizedNameForSortOrder(sortOrderIdx)]
                                                               style:LGAlertViewStyleActionSheet
                                                        buttonTitles:XXTELocalizedNamesForAllSortFields()
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              destructiveButtonTitle:(sortOrderIdx == XXTExplorerViewEntryListSortOrderDesc ? NSLocalizedString(@"Switch to Ascending Order", nil) : NSLocalizedString(@"Switch to Descending Order", nil))
                                                       actionHandler:^(LGAlertView * _Nonnull alertView, NSUInteger index, NSString * _Nullable title) {
                @strongify(self);
                [self setExplorerSortField:index];
                [self updateToolbarButton];
                [self reloadEntryListView];
                [alertView dismissAnimated:YES completionHandler:^{
                    toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Currently sorted by %@, %@.", nil), XXTELocalizedNameForSortField(self.explorerSortField), XXTELocalizedNameForSortOrder(self.explorerSortOrder)]);
                }];
            } cancelHandler:^(LGAlertView * _Nonnull alertView) {
                [alertView dismissAnimated];
            } destructiveHandler:^(LGAlertView * _Nonnull alertView) {
                @strongify(self);
                [self setExplorerSortOrder:(sortOrderIdx == XXTExplorerViewEntryListSortOrderDesc ? XXTExplorerViewEntryListSortOrderAsc : XXTExplorerViewEntryListSortOrderDesc)];
                [self updateToolbarButton];
                [self reloadEntryListView];
                [alertView dismissAnimated:YES completionHandler:^{
                    toastMessage(self, [NSString stringWithFormat:NSLocalizedString(@"Currently sorted by %@, %@.", nil), XXTELocalizedNameForSortField(self.explorerSortField), XXTELocalizedNameForSortOrder(self.explorerSortOrder)]);
                }];
            }];
            [sortAlert showAnimated];
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
                if (@available(iOS 9.0, *)) {
                    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:shareUrls applicationActivities:nil];
                    if (XXTE_IS_IPAD) {
                        activityViewController.modalPresentationStyle = UIModalPresentationPopover;
                        UIPopoverPresentationController *popoverPresentationController = activityViewController.popoverPresentationController;
                        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                        popoverPresentationController.barButtonItem = buttonItem;
                    }
                    activityViewController.presentationController.delegate = self;
                    [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
                } else {
                    toastMessage(self, NSLocalizedString(@"This feature requires iOS 9.0 or later.", nil));
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
    createItemNavigationController.presentationController.delegate = self;
    [self.navigationController presentViewController:createItemNavigationController animated:YES completion:nil];
}

- (void)presentHistoryViewController:(UIBarButtonItem *)buttonItem {
    NSError *entryError = nil;
    XXTExplorerEntry *entryDetail = [[self.class explorerEntryParser] entryOfPath:[[self class] historyDirectoryPath] withError:&entryError];
    if (!entryError) {
        [self performHistoryActionForEntry:entryDetail];
    } else {
        toastError(self, entryError);
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
        toastError(self, localError);
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

#pragma mark - History

+ (NSString *)historyDirectoryPath {
    return [XXTERootPath() stringByAppendingPathComponent:uAppDefine(XXTExplorerViewBuiltHistoryPath)];
}

@end
