//
//  XXTExplorerViewController+ArchiverOperations.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+ArchiverOperations.h"
#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"

#import <LGAlertView/LGAlertView.h>

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"

#import "zip.h"
#import <sys/stat.h>
#import <objc/runtime.h>

@interface XXTExplorerViewController () <LGAlertViewDelegate>

@end

@implementation XXTExplorerViewController (Archiver)

- (void)tableView:(UITableView *)tableView archiveEntryCellTappedWithEntryPath:(NSString *)entryPath {
    NSString *entryName = [entryPath lastPathComponent];
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Unarchive Confirm", nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Unarchive \"%@\" to current directory?", nil), entryName]
                                                          style:LGAlertViewStyleActionSheet
                                                   buttonTitles:@[]
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                       delegate:self];
    objc_setAssociatedObject(alertView, @selector(alertView:unarchiveEntryPath:), entryPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alertView showAnimated:YES completionHandler:nil];
}

- (void)alertView:(LGAlertView *)alertView archiveEntriesAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    NSString *currentPath = self.entryPath;
    NSMutableArray <NSString *> *entryNames = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        NSDictionary *entryDetail = self.entryList[indexPath.row];
        [entryNames addObject:entryDetail[XXTExplorerViewEntryAttributeName]];
    }
    NSUInteger entryCount = entryNames.count;
    NSString *entryDisplayName = nil;
    NSString *archiveName = nil;
    if (entryCount == 1) {
        archiveName = entryNames[0];
        entryDisplayName = [NSString stringWithFormat:@"\"%@\"", archiveName];
    } else {
        archiveName = @"Archive";
        entryDisplayName = [NSString stringWithFormat:NSLocalizedString(@"%lu items", nil), entryNames.count];
    }
    NSString *archiveNameWithExt = [NSString stringWithFormat:@"%@.zip", archiveName];
    NSString *archivePath = [currentPath stringByAppendingPathComponent:archiveNameWithExt];
    NSUInteger archiveIndex = 2;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    while ([fileManager fileExistsAtPath:archivePath]) {
        archiveNameWithExt = [NSString stringWithFormat:@"%@-%lu.zip", archiveName, (unsigned long) archiveIndex];
        archivePath = [currentPath stringByAppendingPathComponent:archiveNameWithExt];
        archiveIndex++;
    }
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Archive", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Archive %@ to \"%@\"", nil), entryDisplayName, archiveNameWithExt]
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
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        [self setEditing:YES animated:YES];
        for (NSUInteger i = 0; i < self.entryList.count; i++) {
            NSDictionary *entryDetail = self.entryList[i];
            if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:archivePath]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                break;
            }
        }
        [self updateToolbarStatus];
        if (error) {
            toastMessage(self, [error localizedDescription]);
        }
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSFileManager *fileManager1 = [[NSFileManager alloc] init];
            struct zip_t *zip = zip_open([archivePath fileSystemRepresentation], ZIP_DEFAULT_COMPRESSION_LEVEL, 'w');
            NSError *error = nil;
            BOOL result = (zip != NULL);
            if (!result) {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot create archive file \"%@\".", nil), archivePath]}];
            } else {
                NSMutableArray <NSString *> *recursiveSubnames = [[NSMutableArray alloc] initWithArray:entryNames];
                while (recursiveSubnames.count != 0) {
                    if (error != nil) break;
                    NSString *enumName = [recursiveSubnames lastObject];
                    NSString *enumPath = [currentPath stringByAppendingPathComponent:enumName];
                    dispatch_async_on_main_queue(^{
                        callbackBlock(enumPath);
                    });
                    [recursiveSubnames removeLastObject];
                    BOOL isDirectory = NO;
                    BOOL fileExists = [fileManager1 fileExistsAtPath:enumPath isDirectory:&isDirectory];
                    if (fileExists) {
                        NSDictionary *entryAttributes = [fileManager1 attributesOfItemAtPath:enumPath error:&error];
                        if ([entryAttributes[NSFileType] isEqualToString:NSFileTypeDirectory]) {
                            if (isDirectory) {
                                NSArray <NSString *> *groupSubnames = [fileManager1 contentsOfDirectoryAtPath:enumPath error:&error];
                                if (groupSubnames.count == 0) {
                                    enumName = [enumName stringByAppendingString:@"/"];
                                } else {
                                    NSMutableArray <NSString *> *groupSubnamesAppended = [[NSMutableArray alloc] initWithCapacity:groupSubnames.count];
                                    for (NSString *groupSubname in groupSubnames) {
                                        [groupSubnamesAppended addObject:[enumName stringByAppendingPathComponent:groupSubname]];
                                    }
                                    [recursiveSubnames addObjectsFromArray:groupSubnamesAppended];
                                    continue;
                                }
                            }
                        }
                    }
                    int open_result = zip_entry_open(zip, [enumName fileSystemRepresentation]);
                    {
                        zip_entry_fwrite(zip, [enumPath fileSystemRepresentation]);
                    }
                    int close_result = zip_entry_close(zip);
                    if (open_result != 0 || close_result != 0) {
                        // TODO: pause by archive error
                    }
                    if (!self.busyOperationProgressFlag) {
                        error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Archiving process terminated: User interrupt occurred.", nil)}];
                        break;
                    }
                }
                zip_close(zip);
            }
            dispatch_async_on_main_queue(^{
                self.busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

- (void)alertView:(LGAlertView *)alertView unarchiveEntryPath:(NSString *)entryPath {
    NSString *entryName = [entryPath lastPathComponent];
    NSString *entryParentPath = [entryPath stringByDeletingLastPathComponent];
    NSString *destinationPath = [entryParentPath stringByAppendingPathComponent:@"Archive"];
    NSString *destinationPathWithIndex = destinationPath;
    NSUInteger destinationIndex = 2;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    while ([fileManager fileExistsAtPath:destinationPathWithIndex]) {
        destinationPathWithIndex = [NSString stringWithFormat:@"%@-%lu", destinationPath, (unsigned long) destinationIndex];
        destinationIndex++;
    }
    NSString *destinationName = [destinationPathWithIndex lastPathComponent];
    LGAlertView *alertView1 = [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Unarchive", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"Unarchiving \"%@\" to \"%@\"", nil), entryName, destinationName]
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
    void (^completionBlock)(BOOL, NSError *) = ^(BOOL result, NSError *error) {
        [alertView1 dismissAnimated];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        [self setEditing:YES animated:YES];
        for (NSUInteger i = 0; i < self.entryList.count; i++) {
            NSDictionary *entryDetail = self.entryList[i];
            if ([entryDetail[XXTExplorerViewEntryAttributePath] isEqualToString:destinationPathWithIndex]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:XXTExplorerViewSectionIndexList];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                break;
            }
        }
        [self updateToolbarStatus];
        if (error) {
            toastMessage(self, [error localizedDescription]);
        }
    };
    if (self.busyOperationProgressFlag) {
        return;
    }
    self.busyOperationProgressFlag = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            const char *extractFrom = [entryPath fileSystemRepresentation];
            const char *extractTo = [destinationPathWithIndex fileSystemRepresentation];
            NSError *error = nil;
            BOOL result = (mkdir(extractTo, 0755) == 0);
            if (NO == result) {
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot create destination directory \"%@\".", nil), destinationPathWithIndex]}];
            } else {
                int (^extract_callback)(const char *, void *) = ^int(const char *filename, void *arg) {
                    dispatch_async_on_main_queue(^{
                        callbackBlock([NSString stringWithUTF8String:filename]);
                    });
                    if (!self.busyOperationProgressFlag) {
                        return -1;
                    }
                    return 0;
                };
                int arg = 2;
                int status = zip_extract(extractFrom, extractTo, NULL, extract_callback, &arg);
                result = (status == 0);
                if (NO == result) {
                    if (!self.busyOperationProgressFlag) {
                        error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unarchiving process terminated: User interrupt occurred.", nil)}];
                    } else {
                        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot read archive file \"%@\".", nil), entryPath]}];
                    }
                }
            }
            dispatch_async_on_main_queue(^{
                self.busyOperationProgressFlag = NO;
                completionBlock(result, error);
            });
        });
    });
}

@end
