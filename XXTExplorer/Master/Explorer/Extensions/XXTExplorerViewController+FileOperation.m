//
//  XXTExplorerViewController+FileOperation.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+FileOperation.h"
#import "XXTExplorerViewController+PasteboardOperations.h"
#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"

#import <LGAlertView/LGAlertView.h>

#import "XXTEAppDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEDispatchDefines.h"

#import <sys/stat.h>

@interface XXTExplorerViewController () <LGAlertViewDelegate>

@end

@implementation XXTExplorerViewController (FileOperation)

#pragma mark - File Operations

- (void)alertView:(LGAlertView *)alertView movePasteboardItemsAtPath:(NSString *)path {
    NSArray <NSString *> *storedPaths = [self.class.explorerPasteboard strings];
    NSUInteger storedCount = storedPaths.count;
    NSMutableArray <NSString *> *storedNames = [[NSMutableArray alloc] initWithCapacity:storedCount];
    for (NSString *storedPath in storedPaths) {
        [storedNames addObject:[storedPath lastPathComponent]];
    }
    NSString *storedDisplayName = nil;
    if (storedCount == 1) {
        storedDisplayName = [NSString stringWithFormat:@"\"%@\"", [storedPaths[0] lastPathComponent]];
    } else {
        storedDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), storedCount];
    }
    NSString *destinationPath = path;
    NSString *destinationName = [destinationPath lastPathComponent];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Move", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Move %@ to \"%@\"", nil), storedDisplayName, destinationName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    NSMutableArray <NSString *> *resultPaths = [[NSMutableArray alloc] initWithCapacity:storedCount];
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [self alertView:alertView1 clearPasteboardEntriesStored:nil];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        if (error) {
            toastMessage(self, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
            for (NSUInteger i = 0; i < self.entryList.count; i++) {
                NSDictionary *entryDetail = self.entryList[i];
                BOOL shouldSelect = NO;
                for (NSString *resultPath in resultPaths) {
                    if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:resultPath]) {
                        shouldSelect = YES;
                    }
                }
                if (shouldSelect) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            [self updateToolbarStatus];
        }
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSError *error = nil;
            NSMutableArray <NSString *> *recursiveSubpaths = [[NSMutableArray alloc] initWithArray:storedPaths];
            NSMutableArray <NSString *> *recursiveSubnames = [[NSMutableArray alloc] initWithArray:storedNames];
            while (recursiveSubnames.count != 0) {
                if (error != nil) break;
                NSString *enumPath = [recursiveSubpaths lastObject];
                NSString *enumName = [recursiveSubnames lastObject];
                dispatch_async_on_main_queue(^{
                    callbackBlock(enumPath);
                });
                [recursiveSubpaths removeLastObject];
                [recursiveSubnames removeLastObject];
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:enumName];
                BOOL isDirectory = NO;
                BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                if (!fileExists) {
                    // TODO: pause by non-exists error
                    continue;
                }
                if (fileExists) {
                    NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                        if (isDirectory) {
                            NSArray <NSString *> *groupSubnames = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                            if (groupSubnames.count != 0) {
                                NSMutableArray <NSString *> *groupSubpathsAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                                NSMutableArray <NSString *> *groupSubnamesAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                                for (NSString *groupSubname in groupSubnames) {
                                    [groupSubpathsAppended addObject:[enumPath stringByAppendingPathComponent:groupSubname]];
                                    [groupSubnamesAppended addObject:[enumName stringByAppendingPathComponent:groupSubname]];
                                }
                                BOOL mkdirResult = (mkdir([targetPath fileSystemRepresentation], 0755) == 0);
                                if (!mkdirResult) {
                                    // TODO: pause by mkdir error
                                }
                                [recursiveSubpaths addObject:enumPath];
                                [recursiveSubnames addObject:enumName];
                                [recursiveSubpaths addObjectsFromArray:groupSubpathsAppended];
                                [recursiveSubnames addObjectsFromArray:groupSubnamesAppended];
                            } else {
                                BOOL rmdirResult = (rmdir([enumPath fileSystemRepresentation]) == 0);
                                if (!rmdirResult) {
                                    // TODO: pause by rmdir error
                                }
                            }
                            continue;
                        }
                    }
                }
                BOOL moveResult = [fileManager moveItemAtPath:enumPath toPath:targetPath error:&error];
                if (!moveResult) {
                    // TODO: pause by move error
                    break;
                }
                if (!self.busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Moving process terminated: User interrupt occurred.", nil)}];
                    break;
                }
            }
            for (NSString *storedName in storedNames) {
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:storedName];
                BOOL isDirectory = NO;
                BOOL exists = [fileManager fileExistsAtPath:targetPath isDirectory:&isDirectory];
                if (exists) {
                    [resultPaths addObject:targetPath];
                }
            }
            BOOL result = (resultPaths.count != 0);
            dispatch_async_on_main_queue(^{
                self.busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView pastePasteboardItemsAtPath:(NSString *)path {
    NSArray <NSString *> *storedPaths = [self.class.explorerPasteboard strings];
    NSUInteger storedCount = storedPaths.count;
    NSMutableArray <NSString *> *storedNames = [[NSMutableArray alloc] initWithCapacity:storedCount];
    for (NSString *storedPath in storedPaths) {
        [storedNames addObject:[storedPath lastPathComponent]];
    }
    NSString *storedDisplayName = nil;
    if (storedCount == 1) {
        storedDisplayName = [NSString stringWithFormat:@"\"%@\"", [storedPaths[0] lastPathComponent]];
    } else {
        storedDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), storedCount];
    }
    NSString *destinationPath = path;
    NSString *destinationName = [destinationPath lastPathComponent];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Paste", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Paste %@ to \"%@\"", nil), storedDisplayName, destinationName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    NSMutableArray <NSString *> *resultPaths = [[NSMutableArray alloc] initWithCapacity:storedCount];
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        if (error) {
            toastMessage(self, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
            for (NSUInteger i = 0; i < self.entryList.count; i++) {
                NSDictionary *entryDetail = self.entryList[i];
                BOOL shouldSelect = NO;
                for (NSString *resultPath in resultPaths) {
                    if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:resultPath]) {
                        shouldSelect = YES;
                    }
                }
                if (shouldSelect) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            [self updateToolbarStatus];
        }
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSError *error = nil;
            NSMutableArray <NSString *> *recursiveSubpaths = [[NSMutableArray alloc] initWithArray:storedPaths];
            NSMutableArray <NSString *> *recursiveSubnames = [[NSMutableArray alloc] initWithArray:storedNames];
            while (recursiveSubnames.count != 0) {
                if (error != nil) break;
                NSString *enumPath = [recursiveSubpaths lastObject];
                NSString *enumName = [recursiveSubnames lastObject];
                dispatch_async_on_main_queue(^{
                    callbackBlock(enumPath);
                });
                [recursiveSubpaths removeLastObject];
                [recursiveSubnames removeLastObject];
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:enumName];
                BOOL isDirectory = NO;
                BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                if (!fileExists) {
                    // TODO: pause by non-exists error
                    continue;
                }
                if (fileExists) {
                    NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                        if (isDirectory) {
                            NSArray <NSString *> *groupSubnames = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                            NSMutableArray <NSString *> *groupSubpathsAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                            NSMutableArray <NSString *> *groupSubnamesAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                            for (NSString *groupSubname in groupSubnames) {
                                [groupSubpathsAppended addObject:[enumPath stringByAppendingPathComponent:groupSubname]];
                                [groupSubnamesAppended addObject:[enumName stringByAppendingPathComponent:groupSubname]];
                            }
                            BOOL mkdirResult = (mkdir([targetPath fileSystemRepresentation], 0755) == 0);
                            if (!mkdirResult) {
                                // TODO: pause by mkdir error
                            }
                            [recursiveSubpaths addObjectsFromArray:groupSubpathsAppended];
                            [recursiveSubnames addObjectsFromArray:groupSubnamesAppended];
                            continue;
                        }
                    }
                }
                BOOL copyResult = [fileManager copyItemAtPath:enumPath toPath:targetPath error:&error];
                if (!copyResult) {
                    // TODO: pause by copy error
                    break;
                }
                if (!self.busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Pasting process terminated: User interrupt occurred.", nil)}];
                    break;
                }
            }
            for (NSString *storedName in storedNames) {
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:storedName];
                BOOL isDirectory = NO;
                BOOL exists = [fileManager fileExistsAtPath:targetPath isDirectory:&isDirectory];
                if (exists) {
                    [resultPaths addObject:targetPath];
                }
            }
            BOOL result = (resultPaths.count != 0);
            dispatch_async_on_main_queue(^{
                self.busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView symlinkPasteboardItemsAtPath:(NSString *)path {
    NSArray <NSString *> *storedPaths = [self.class.explorerPasteboard strings];
    NSUInteger storedCount = storedPaths.count;
    NSString *storedDisplayName = nil;
    if (storedCount == 1) {
        storedDisplayName = [NSString stringWithFormat:@"\"%@\"", [storedPaths[0] lastPathComponent]];
    } else {
        storedDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), storedCount];
    }
    NSString *destinationPath = path;
    NSString *destinationName = [destinationPath lastPathComponent];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Link", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Link %@ to \"%@\"", nil), storedDisplayName, destinationName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    NSMutableArray <NSString *> *resultPaths = [[NSMutableArray alloc] initWithCapacity:storedCount];
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        if (error) {
            toastMessage(self, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
            for (NSUInteger i = 0; i < self.entryList.count; i++) {
                NSDictionary *entryDetail = self.entryList[i];
                BOOL shouldSelect = NO;
                for (NSString *resultPath in resultPaths) {
                    if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:resultPath]) {
                        shouldSelect = YES;
                    }
                }
                if (shouldSelect) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
            [self updateToolbarStatus];
        }
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSError *error = nil;
            for (NSString *storedPath in storedPaths) {
                if (error != nil) break;
                dispatch_async_on_main_queue(^{
                    callbackBlock(storedPath);
                });
                NSString *storedName = [storedPath lastPathComponent];
                NSString *targetPath = [destinationPath stringByAppendingPathComponent:storedName];
                BOOL linkResult = [fileManager createSymbolicLinkAtPath:targetPath withDestinationPath:storedPath error:&error];
                if (!linkResult) {
                    // TODO: pause by link error
                    break;
                }
                [resultPaths addObject:targetPath];
                if (!self.busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Linking process terminated: User interrupt occurred.", nil)}];
                    break;
                }
            }
            BOOL result = (resultPaths.count != 0);
            dispatch_async_on_main_queue(^{
                self.busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView removeEntryCell:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *entryDetail = self.entryList[indexPath.row];
    NSString *entryPath = entryDetail[XXTExplorerViewEntryAttributePath];
    NSString *entryName = entryDetail[XXTExplorerViewEntryAttributeName];
    NSUInteger entryCount = 1;
    NSMutableArray <NSIndexPath *> *deletedPaths = [[NSMutableArray alloc] initWithCapacity:entryCount];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Delete", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Deleting \"%@\"", nil), entryName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:entryPath
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    
    @weakify(self);
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        @strongify(self);
        [alertView1 dismissAnimated];
        [self setEditing:NO animated:YES];
        if (error == nil) {
            [self loadEntryListData];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:deletedPaths withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            toastMessage(self, [error localizedDescription]);
        }
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @strongify(self);
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSError *error = nil;
            NSMutableArray <NSString *> *recursiveSubpaths = [@[entryPath] mutableCopy];
            while (recursiveSubpaths.count != 0) {
                if (error != nil) break;
                NSString *enumPath = [recursiveSubpaths lastObject];
                dispatch_async_on_main_queue(^{
                    callbackBlock(enumPath);
                });
                [recursiveSubpaths removeLastObject];
                BOOL isDirectory = NO;
                BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                if (fileExists) {
                    NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                        if (isDirectory) {
                            NSArray <NSString *> *groupSubpaths = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                            if (groupSubpaths.count != 0) {
                                NSMutableArray <NSString *> *groupSubpathsAppended = [[NSMutableArray alloc] initWithCapacity:groupSubpaths.count];
                                for (NSString *groupSubpath in groupSubpaths) {
                                    [groupSubpathsAppended addObject:[enumPath stringByAppendingPathComponent:groupSubpath]];
                                }
                                [recursiveSubpaths addObject:enumPath];
                                [recursiveSubpaths addObjectsFromArray:groupSubpathsAppended];
                                continue;
                            }
                        }
                    }
                }
                BOOL removeResult = [fileManager removeItemAtPath:enumPath error:&error];
                if (!removeResult) {
                    // TODO: pause by remove error
                }
                if (!self.busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Removing process terminated: User interrupt occurred.", nil)}];
                    break;
                }
            }
            if ([fileManager fileExistsAtPath:entryPath] == NO) {
                [deletedPaths addObject:indexPath];
            }
            BOOL result = (deletedPaths.count != 0);
            dispatch_async_on_main_queue(^{
                self.busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView removeEntriesAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    NSMutableArray <NSString *> *entryPaths = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        [entryPaths addObject:self.entryList[indexPath.row][XXTExplorerViewEntryAttributePath]];
    }
    NSUInteger entryCount = entryPaths.count;
    NSMutableArray <NSIndexPath *> *deletedPaths = [[NSMutableArray alloc] initWithCapacity:entryCount];
    NSString *entryDisplayName = nil;
    if (entryCount == 1) {
        entryDisplayName = [NSString stringWithFormat:@"\"%@\"", [entryPaths[0] lastPathComponent]];
    } else {
        entryDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), entryPaths.count];
    }
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Delete", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Deleting %@", nil), entryDisplayName]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:@"..."
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self setEditing:NO animated:YES];
        if (error == nil) {
            [self loadEntryListData];
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:deletedPaths withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        } else {
            toastMessage(self, [error localizedDescription]);
        }
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            NSMutableArray <NSString *> *recursiveSubpaths = [[NSMutableArray alloc] initWithArray:entryPaths];
            NSError *error = nil;
            while (recursiveSubpaths.count != 0) {
                if (error != nil) break;
                NSString *enumPath = [recursiveSubpaths lastObject];
                dispatch_async_on_main_queue(^{
                    callbackBlock(enumPath);
                });
                [recursiveSubpaths removeLastObject];
                
                BOOL isDirectory = NO;
                BOOL fileExists = [fileManager fileExistsAtPath:enumPath isDirectory:&isDirectory];
                if (fileExists) {
                    NSDictionary *entryAttributes = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                        if (isDirectory) {
                            NSArray <NSString *> *groupSubpaths = [fileManager contentsOfDirectoryAtPath:enumPath error:&error];
                            if (groupSubpaths.count != 0) {
                                NSMutableArray <NSString *> *groupSubpathsAppended = [[NSMutableArray alloc] initWithCapacity:groupSubpaths.count];
                                for (NSString *groupSubpath in groupSubpaths) {
                                    [groupSubpathsAppended addObject:[enumPath stringByAppendingPathComponent:groupSubpath]];
                                }
                                [recursiveSubpaths addObject:enumPath];
                                [recursiveSubpaths addObjectsFromArray:groupSubpathsAppended];
                                continue;
                            }
                        }
                    }
                }
                BOOL removeResult = [fileManager removeItemAtPath:enumPath error:&error];
                if (!removeResult) {
                    // TODO: pause by remove error
                }
                if (!self.busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Removing process terminated: User interrupt occurred.", nil)}];
                    break;
                }
            }
            for (NSUInteger i = 0; i < entryPaths.count; i++) {
                NSString *entryPath = entryPaths[i];
                if ([fileManager fileExistsAtPath:entryPath] == NO) {
                    [deletedPaths addObject:indexPaths[i]];
                }
            }
            BOOL result = (deletedPaths.count != 0);
            dispatch_async_on_main_queue(^{
                self.busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

@end
