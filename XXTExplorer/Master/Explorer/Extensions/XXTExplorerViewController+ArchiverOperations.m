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
    
    // entryPath UTF-8 representation
    const char *extractFrom = [entryPath fileSystemRepresentation];
    
    // entry name part
    NSString *entryName = entryPath.lastPathComponent;
    
    // entry parent part
    NSString *entryParentPath = [entryPath stringByDeletingLastPathComponent];
    
    // sub-entries count in that zip
    int subentryCount = zip_root_entry_count(extractFrom);
    
    // decide the destionation
    BOOL combinedMode = (subentryCount >= 2);
    NSString *destinationPath = nil;
    if (combinedMode) {
        destinationPath = [entryParentPath stringByAppendingPathComponent:@"Archive"];
    } else {
        destinationPath = entryParentPath;
    }
    
    // adjust destination path
    NSString *destinationPathWithIndex = destinationPath;
    if (combinedMode) {
        NSUInteger destinationIndex = 2;
        while (0 == access(destinationPathWithIndex.UTF8String, F_OK)) {
            destinationPathWithIndex = [NSString stringWithFormat:@"%@-%lu", destinationPath, (unsigned long) destinationIndex];
            destinationIndex++;
        }
    }
    
    // destination name part
    NSString *destinationName = [destinationPathWithIndex lastPathComponent];
    
    // present alert
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
    
    __block NSMutableArray <NSString *> *changedPaths = [[NSMutableArray alloc] init];
    
    // block for item that will be extracted
    int (^will_extract)(char *, void *) = ^int (char *filename, void *arg) {
        NSString *originalPath = [[NSString alloc] initWithUTF8String:filename];
        NSString *originalPathNoExt = [originalPath stringByDeletingPathExtension];
        NSString *originalPathExt = [originalPath pathExtension];
        NSString *changedPath = originalPath;
        NSUInteger changedIndex = 2;
        BOOL flag = NO;
        while (0 == access(changedPath.UTF8String, F_OK)) {
            changedPath = [[NSString stringWithFormat:@"%@-%lu", originalPathNoExt, (unsigned long) changedIndex] stringByAppendingPathExtension:originalPathExt];
            changedIndex++;
            flag = YES;
        }
        [changedPaths addObject:changedPath];
        if (flag) {
            const char *changed = changedPath.UTF8String;
            strncpy(filename, changed, MAX_PATH);
            return 1;
        } else {
            return 0;
        }
    };
    
    // callback block for extracting
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    
    @weakify(self);
    
    // block for extracted item
    int (^extract_callback)(const char *, void *) = ^int(const char *filename, void *arg) {
        @strongify(self);
        
        // display
        dispatch_async_on_main_queue(^{
            callbackBlock([NSString stringWithUTF8String:filename]);
        });
        
        // check cancel flag
        if (!self.busyOperationProgressFlag) {
            return -1;
        }
        
        return 0;
    };
    
    
    void (^completionBlock)(BOOL, NSArray <NSString *> *, NSError *) = ^(BOOL result, NSArray <NSString *> *createdEntries, NSError *error) {
        @strongify(self);
        
        [alertView1 dismissAnimated];
        [self loadEntryListData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationFade];
        [self setEditing:YES animated:YES];
        for (NSUInteger i = 0; i < self.entryList.count; i++) {
            NSDictionary *entryDetail = self.entryList[i];
            if ([createdEntries containsObject:entryDetail[XXTExplorerViewEntryAttributePath]]) {
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
    
    // busy lock
    if (self.busyOperationProgressFlag)
        return;
    self.busyOperationProgressFlag = YES;
    
    // extact delay in another thread
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @strongify(self);
            
            // destinationPath UTF-8 representation
            const char *from = [entryPath fileSystemRepresentation];
            const char *to = [destinationPathWithIndex fileSystemRepresentation];
            
            // define error
            NSError *error = nil;
            
            // make appropriate folder
            BOOL result = (access(to, F_OK) == 0 || mkdir(to, 0755) == 0);
            if (NO == result) {
                
                error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot create destination directory \"%@\".", nil), destinationPathWithIndex]}];
                
            } else {
                
                int arg = 2;
                int status = zip_extract(from, to, will_extract, extract_callback, &arg);
                
                result = (status == 0);
                
                // error handling
                if (NO == result) {
                    
                    if (!self.busyOperationProgressFlag) {
                        error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unarchiving process terminated: User interrupt occurred.", nil)}];
                    } else {
                        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot read archive file \"%@\".", nil), entryPath]}];
                    }
                    
                }
                
            }
            
            // update result in main thread
            dispatch_async_on_main_queue(^{
                
                self.busyOperationProgressFlag = NO;
                if (combinedMode) {
                    completionBlock(result, @[ destinationPathWithIndex ], error);
                } else {
                    completionBlock(result, [changedPaths copy], error);
                }
                
            }); // end updating
            
        }); // end thread
        
    }); // end delay
    
}

@end
