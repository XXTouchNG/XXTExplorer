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
#import "XXTENetworkDefines.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEDispatchDefines.h"
#import "XXTExplorerEntryReader.h"

#import <PromiseKit/PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

#import <sys/stat.h>
#import "xui32.h"

#import "XXTEPermissionDefines.h"

@interface XXTExplorerViewController () <LGAlertViewDelegate>

@end

@implementation XXTExplorerViewController (FileOperation)

#pragma mark - File Operations

#ifndef APPSTORE
- (void)alertView:(LGAlertView *)alertView encryptEntry:(XXTExplorerEntry *)entryDetail {
    NSString *currentPath = self.entryPath;
    XXTExplorerEntryReader *entryReader = entryDetail.entryReader;
    NSString *encryptionExtension = entryReader.encryptionExtension;
    if (!encryptionExtension) return;
    NSString *entryPath = entryDetail.entryPath;
    NSString *entryName = [entryPath lastPathComponent];
    NSString *encryptedName = [entryName stringByDeletingPathExtension];
    NSString *encryptedNameWithExt = [encryptedName stringByAppendingPathExtension:encryptionExtension];
    NSString *encryptedPath = [currentPath stringByAppendingPathComponent:encryptedNameWithExt];
    NSUInteger encryptedIndex = 2;
    struct stat encryptTestStat;
    while (0 == lstat(encryptedPath.UTF8String, &encryptTestStat)) {
        encryptedNameWithExt = [NSString stringWithFormat:@"%@-%lu.%@", encryptedName, (unsigned long) encryptedIndex, encryptionExtension];
        encryptedPath = [currentPath stringByAppendingPathComponent:encryptedNameWithExt];
        encryptedIndex++;
    }
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Encrypt", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Encrypt \"%@\" to \"%@\"", nil), entryName, encryptedNameWithExt]
                                                                               style:LGAlertViewStyleActionSheet
                                                                   progressLabelText:entryPath
                                                                        buttonTitles:nil
                                                                   cancelButtonTitle:nil
                                                              destructiveButtonTitle:nil
                                                                            delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    }
    @weakify(self);
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        @strongify(self);
        if (error) {
            toastDaemonError(self, error);
        } else {
            [self setEditing:YES animated:YES];
        }
        UIViewController *blockController = blockInteractions(self, YES);
        [alertView1 dismissAnimated:YES completionHandler:^{
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (nil == error) {
                for (NSUInteger i = 0; i < self.entryList.count; i++) {
                    XXTExplorerEntry *entryDetail = self.entryList[i];
                    if ([entryDetail.entryPath isEqualToString:encryptedPath]) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                        break;
                    }
                }
                [self updateToolbarStatus];
            }
            blockInteractions(blockController, NO);
        }];
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            promiseFixPermission(currentPath, NO); // fix permission
            if (entryReader.encryptionType == XXTExplorerEntryReaderEncryptionTypeRemote) {
                [NSURLConnection POST:uAppDaemonCommandUrl(@"encript_file") JSON:@{ @"in_file": entryPath, @"out_file": encryptedPath }]
                .then(convertJsonString)
                .then(^(NSDictionary *jsonDirectory) {
                    if ([jsonDirectory[@"code"] isEqualToNumber:@(0)]) {
                        dispatch_async_on_main_queue(^{
                            self.busyOperationProgressFlag = NO;
                            completionBlock(YES, nil);
                        });
                    } else {
                        @throw [NSString stringWithFormat:NSLocalizedString(@"Cannot encrypt: %@", nil), jsonDirectory[@"message"]];
                    }
                    return [PMKPromise promiseWithValue:@{}];
                })
                .catch(^(NSError *serverError) {
                    dispatch_async_on_main_queue(^{
                        self.busyOperationProgressFlag = NO;
                        completionBlock(NO, serverError);
                    });
                })
                .finally(^() {
                    
                });
            } else {
                xui_32 *xui = XUICreateWithContentsOfFile(entryPath.UTF8String);
                if (xui) {
                    int result = XUIWriteToFile(encryptedPath.UTF8String, xui);
                    XUIRelease(xui);
                    if (result == 0) {
                        dispatch_async_on_main_queue(^{
                            self.busyOperationProgressFlag = NO;
                            completionBlock(YES, nil);
                        });
                    } else {
                        dispatch_async_on_main_queue(^{
                            self.busyOperationProgressFlag = NO;
                            NSString *errorMessage =
                            [NSString stringWithFormat:NSLocalizedString(@"Cannot open: \"%@\"", nil), encryptedPath];
                            completionBlock(NO, [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: errorMessage}]);
                        });
                    }
                } else {
                    dispatch_async_on_main_queue(^{
                        self.busyOperationProgressFlag = NO;
                        NSString *errorMessage =
                        [NSString stringWithFormat:NSLocalizedString(@"Cannot encrypt: %@", nil), NSLocalizedString(@"Invalid RAW Data.", nil)];
                        completionBlock(NO, [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: errorMessage}]);
                    });
                }
            }
            
        });
    });
}
#endif

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
    @weakify(self);
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        @strongify(self);
        if (error) {
            toastMessage(self, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
        }
        UIViewController *blockController = blockInteractions(self, YES);
        [alertView1 dismissAnimated:YES completionHandler:^{
            [self.class.explorerPasteboard setStrings:@[]];
            [self updateToolbarStatus];
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (nil == error) {
                for (NSUInteger i = 0; i < self.entryList.count; i++) {
                    XXTExplorerEntry *entryDetail = self.entryList[i];
                    BOOL shouldSelect = NO;
                    for (NSString *resultPath in resultPaths) {
                        if ([entryDetail.entryPath isEqualToString:resultPath]) {
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
            blockInteractions(blockController, NO);
        }];
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            promiseFixPermission(destinationPath, NO); // fix permission
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
                    NSDictionary *entryDetail = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryDetail[NSFileType] isEqualToString:NSFileTypeDirectory]) {
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
                                BOOL mkdirResult = (mkdir([targetPath fileSystemRepresentation], 0755) == 0);
                                if (!mkdirResult) {
                                    // TODO: pause by mkdir error
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
    @weakify(self);
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        @strongify(self);
        if (error) {
            toastMessage(self, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
        }
        UIViewController *blockController = blockInteractions(self, YES);
        [alertView1 dismissAnimated:YES completionHandler:^{
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (nil == error) {
                for (NSUInteger i = 0; i < self.entryList.count; i++) {
                    XXTExplorerEntry *entryDetail = self.entryList[i];
                    BOOL shouldSelect = NO;
                    for (NSString *resultPath in resultPaths) {
                        if ([entryDetail.entryPath isEqualToString:resultPath]) {
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
            blockInteractions(blockController, NO);
        }];
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            promiseFixPermission(destinationPath, NO); // fix permission
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
                    NSDictionary *entryDetail = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryDetail[NSFileType] isEqualToString:NSFileTypeDirectory]) {
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
    @weakify(self);
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        @strongify(self);
        if (error) {
            toastMessage(self, [error localizedDescription]);
        } else {
            [self setEditing:YES animated:YES];
        }
        UIViewController *blockController = blockInteractions(self, YES);
        [alertView1 dismissAnimated:YES completionHandler:^{
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (nil == error) {
                for (NSUInteger i = 0; i < self.entryList.count; i++) {
                    XXTExplorerEntry *entryDetail = self.entryList[i];
                    BOOL shouldSelect = NO;
                    for (NSString *resultPath in resultPaths) {
                        if ([entryDetail.entryPath isEqualToString:resultPath]) {
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
            blockInteractions(blockController, NO);
        }];
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            promiseFixPermission(destinationPath, NO); // fix permission
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
    XXTExplorerEntry *entryDetail = self.entryList[indexPath.row];
    NSString *entryPath = entryDetail.entryPath;
    NSUInteger entryCount = 1;
    NSMutableArray <NSIndexPath *> *deletedPaths = [[NSMutableArray alloc] initWithCapacity:entryCount];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Delete", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Deleting \"%@\"", nil), [entryDetail localizedDisplayName]]
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
        if (error) {
            toastMessage(self, [error localizedDescription]);
        } else {
            [self setEditing:NO animated:YES];
        }
        UIViewController *blockController = blockInteractions(self, YES);
        [alertView1 dismissAnimated:YES completionHandler:^{
            UITableView *tableView = self.tableView;
            if (error) {
                [self loadEntryListData];
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
                for (NSIndexPath *indexPath in deletedPaths) {
                    [indexSet addIndex:indexPath.row];
                }
                [self.entryList removeObjectsAtIndexes:[indexSet copy]];
                [tableView beginUpdates];
                [tableView deleteRowsAtIndexPaths:deletedPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                [tableView endUpdates];
                [self reloadFooterView];
            }
            blockInteractions(blockController, NO);
        }];
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @strongify(self);
            promiseFixPermission(entryPath, YES); // fix permission
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
                    NSDictionary *entryDetail = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryDetail[NSFileType] isEqualToString:NSFileTypeDirectory]) {
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
                    break;
                }
                if (!self.busyOperationProgressFlag) {
                    error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Removing process terminated: User interrupt occurred.", nil)}];
                    break;
                }
            }
            struct stat removeStat;
            if (0 != lstat(entryPath.UTF8String, &removeStat)) {
                [deletedPaths addObject:indexPath];
            }
            BOOL result = (error == nil);
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
        if (indexPath.section == XXTExplorerViewSectionIndexList) {
            [entryPaths addObject:self.entryList[indexPath.row].entryPath];
        }
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
    @weakify(self);
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        @strongify(self);
        if (error) {
            toastMessage(self, [error localizedDescription]);
        } else {
            [self setEditing:NO animated:YES];
        }
        UIViewController *blockController = blockInteractions(self, YES);
        [alertView1 dismissAnimated:YES completionHandler:^{
            UITableView *tableView = self.tableView;
            if (error) {
                [self loadEntryListData];
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
                for (NSIndexPath *indexPath in deletedPaths) {
                    [indexSet addIndex:indexPath.row];
                }
                [self.entryList removeObjectsAtIndexes:[indexSet copy]];
                [tableView beginUpdates];
                [tableView deleteRowsAtIndexPaths:deletedPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                [tableView endUpdates];
                [self reloadFooterView];
            }
            blockInteractions(blockController, NO);
        }];
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            for (NSString *fixPath in entryPaths)
            {
                promiseFixPermission(fixPath, YES); // fix permission
            }
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
                    NSDictionary *entryDetail = [fileManager attributesOfItemAtPath:enumPath error:&error];
                    if ([entryDetail[NSFileType] isEqualToString:NSFileTypeDirectory]) {
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
                struct stat removeStat;
                if (0 != lstat(entryPath.UTF8String, &removeStat)) {
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
