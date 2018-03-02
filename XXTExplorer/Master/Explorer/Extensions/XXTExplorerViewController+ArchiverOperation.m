//
//  XXTExplorerViewController+ArchiverOperation.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+ArchiverOperation.h"
#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"

#import <LGAlertView/LGAlertView.h>

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"

#import "zip.h"
#import <sys/stat.h>
#import <objc/runtime.h>

#ifdef APPSTORE
#import <UnrarKit/UnrarKit.h>
#endif

typedef enum : NSUInteger {
    XXTEArchiveTypeZip = 0,
    XXTEArchiveTypeRar,
} XXTEArchiveType;

@interface XXTExplorerViewController () <LGAlertViewDelegate>

@end

@implementation XXTExplorerViewController (Archiver)

- (void)tableView:(UITableView *)tableView unarchiveEntryCellTappedWithEntryPath:(NSString *)entryPath {
    NSString *entryName = [entryPath lastPathComponent];
    LGAlertView *alertView = [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Unarchive Confirm", nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Unarchive \"%@\" to current directory?", nil), entryName]
                                                          style:LGAlertViewStyleActionSheet
                                                   buttonTitles:@[ ]
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:NSLocalizedString(@"Confirm", nil)
                                                       delegate:self];
    objc_setAssociatedObject(alertView, @selector(alertView:unarchiveEntryPath:), entryPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alertView showAnimated:YES completionHandler:nil];
}

- (void)alertView:(LGAlertView *)alertView archiveEntriesAtIndexPaths:(NSArray <NSIndexPath *> *)indexPaths {
    NSMutableArray <XXTExplorerEntry *> *entryDetails = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.section == XXTExplorerViewSectionIndexList) {
            XXTExplorerEntry *entryDetail = self.entryList[indexPath.row];
            [entryDetails addObject:entryDetail];
        }
    }
    NSMutableArray <NSString *> *entryNames = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];
    for (XXTExplorerEntry *entryDetail in entryDetails) {
        [entryNames addObject:entryDetail.entryName];
    }
    if (entryNames.count == 1 && entryDetails.count == 1)
    {
        XXTExplorerEntry *entryDetail = entryDetails[0];
        NSString *entryBaseExtension = entryDetail.entryExtension;
        if (entryDetail.isDirectory &&
            [entryBaseExtension isEqualToString:@"xpp"])
        {
            LGAlertView *alertView1 =
            [[LGAlertView alloc] initWithTitle:NSLocalizedString(@"Package Operation", nil)
                                       message:[NSString stringWithFormat:NSLocalizedString(@"Choose an package operation for \"%@\".", nil), entryDetail.localizedDisplayName]
                                         style:LGAlertViewStyleActionSheet
                                  buttonTitles:@[ NSLocalizedString(@"Continue as Archive", nil) ]
                             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                        destructiveButtonTitle:NSLocalizedString(@"Create Package", nil)
                                 actionHandler:^(LGAlertView * _Nonnull alertViewA, NSUInteger index, NSString * _Nullable title) {
                                     if (index == 0) { [self alertView:alertViewA archiveEntriesAtPaths:entryNames baseDirectory:@"" baseExtension:@"zip"]; } else { [alertViewA dismissAnimated]; }
                                 } cancelHandler:^(LGAlertView * _Nonnull alertViewA) {
                                     [alertViewA dismissAnimated];
                                 } destructiveHandler:^(LGAlertView * _Nonnull alertViewA) {
                                     [self alertView:alertViewA archiveEntriesAtPaths:entryNames baseDirectory:@"Payload" baseExtension:@"xpa"];
                                 }];
            if (alertView && alertView.isShowing) {
                [alertView transitionToAlertView:alertView1 completionHandler:nil];
            } else {
                [alertView1 showAnimated];
            }
            return;
        }
    }
    // Archive directly
    [self alertView:alertView archiveEntriesAtPaths:entryNames baseDirectory:@"" baseExtension:@"zip"];
}

- (void)alertView:(LGAlertView *)alertView archiveEntriesAtPaths:(NSArray <NSString *> *)entryNames baseDirectory:(NSString *)baseDirectory baseExtension:(NSString *)baseExtension {
    NSString *currentPath = self.entryPath;
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
    NSString *archiveNameWithExt = [NSString stringWithFormat:@"%@.%@", archiveName, baseExtension];
    NSString *archivePath = [currentPath stringByAppendingPathComponent:archiveNameWithExt];
    NSUInteger archiveIndex = 2;
    struct stat archiveTestStat;
    while (0 == lstat(archivePath.UTF8String, &archiveTestStat)) {
        archiveNameWithExt = [NSString stringWithFormat:@"%@-%lu.%@", archiveName, (unsigned long) archiveIndex, baseExtension];
        archivePath = [currentPath stringByAppendingPathComponent:archiveNameWithExt];
        archiveIndex++;
    }
    LGAlertView *alertView1 =
    [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Archive", nil)
                                                   message:[NSString stringWithFormat:NSLocalizedString(@"Archive %@ to \"%@\"", nil), entryDisplayName, archiveNameWithExt]
                                                     style:LGAlertViewStyleActionSheet
                                         progressLabelText:@"..."
                                              buttonTitles:nil
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:nil
                                                  delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    } else {
        [alertView1 showAnimated];
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
            [self setEditing:YES animated:YES];
        }
        UIViewController *blockController = blockInteractions(self, YES);
        [alertView1 dismissAnimated:YES completionHandler:^{
            [self loadEntryListData];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (nil == error) {
                for (NSUInteger i = 0; i < self.entryList.count; i++) {
                    XXTExplorerEntry *entryDetail = self.entryList[i];
                    if ([entryDetail.entryPath isEqualToString:archivePath]) {
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
                        NSDictionary *entryDetail = [fileManager1 attributesOfItemAtPath:enumPath error:&error];
                        if ([entryDetail[NSFileType] isEqualToString:NSFileTypeDirectory]) {
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
                    NSString *respName = [baseDirectory stringByAppendingPathComponent:enumName];
                    int open_result = zip_entry_open(zip, [respName fileSystemRepresentation]);
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

static int32_t const kZipArchiveHeaderLocalDirMagic = 0x04034b50;
static int32_t const kZipArchiveHeaderCentralDirMagic = 0x02014b50;

#ifdef APPSTORE
static int32_t const kRarArchiveHeaderMagic = 0x21726152;
#endif

- (void)alertView:(LGAlertView *)alertView unarchiveEntryPath:(NSString *)entryPath {
    
    // entryPath UTF-8 representation
//    const char *extractFrom = [entryPath fileSystemRepresentation];
    
    // entry name part
    NSString *entryName = entryPath.lastPathComponent;
    
    // entry parent part
    NSString *entryParentPath = [entryPath stringByDeletingLastPathComponent];
    
    // sub-entries count in that zip
//    int subentry = zip_root_entry_alone(extractFrom);
    
    // decide the destionation
//    BOOL singleMode = (subentry == 0);
    NSString *destinationPath = nil;
//    if (singleMode) {
//        destinationPath = entryParentPath;
//    } else {
        destinationPath = [entryParentPath stringByAppendingPathComponent:@"Archive"];
//    }
    
    // adjust destination path
    NSString *destinationPathWithIndex = destinationPath;
//    if (!singleMode) {
        NSUInteger destinationIndex = 2;
        while (0 == access(destinationPathWithIndex.UTF8String, F_OK)) {
            destinationPathWithIndex = [NSString stringWithFormat:@"%@-%lu", destinationPath, (unsigned long) destinationIndex];
            destinationIndex++;
        }
//    }

    // destination name part
    NSString *destinationName = [destinationPathWithIndex lastPathComponent];
    
    // present alert
    LGAlertView *alertView1 =
    [[LGAlertView alloc] initWithActivityIndicatorAndTitle:NSLocalizedString(@"Unarchive", nil)
                                                   message:[NSString stringWithFormat:NSLocalizedString(@"Unarchiving \"%@\" to \"%@\"", nil), entryName, destinationName]
                                                     style:LGAlertViewStyleActionSheet
                                         progressLabelText:entryPath
                                              buttonTitles:nil
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:nil
                                                  delegate:self];
    if (alertView && alertView.isShowing) {
        [alertView transitionToAlertView:alertView1 completionHandler:nil];
    } else {
        [alertView1 showAnimated];
    }
    
    // callback block for extracting
    void (^callbackBlock)(NSString *) = ^(NSString *filename) {
        alertView1.progressLabelText = filename;
    };
    
    __block NSMutableArray <NSString *> *changedPaths = [[NSMutableArray alloc] init];
    
    @weakify(self);
    
    int (^will_extract)(const char *, void *) = ^int(const char *filename, void *arg) {
        return zip_extract_override;
    };
    
    int (^did_extract)(const char *, void *) = ^int(const char *filename, void *arg) {
        @strongify(self);
        
        NSString *changedPath = [[NSString alloc] initWithUTF8String:filename];
        
        // display
        dispatch_async_on_main_queue(^{
            callbackBlock(changedPath);
        });
        
        [changedPaths addObject:changedPath];
        
        // check cancel flag
        if (!self.busyOperationProgressFlag) {
            return -1;
        }
        
        return 0;
    };
    
#ifdef APPSTORE
    BOOL (^did_extract_rar)(URKFileInfo *, CGFloat) = ^BOOL(URKFileInfo *currentFile, CGFloat percentArchiveDecompressed) {
        return (did_extract(currentFile.filename.fileSystemRepresentation, &percentArchiveDecompressed) == 0);
    };
#endif
    
    void (^completionBlock)(BOOL, NSArray <NSString *> *, NSError *) = ^(BOOL result, NSArray <NSString *> *createdEntries, NSError *error) {
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
                    BOOL contains = NO;
                    for (NSString *createdEntry in createdEntries) {
                        NSString *listPath = entryDetail.entryPath;
                        BOOL isDirectory = entryDetail.isDirectory;
                        if (
                            [createdEntry isEqualToString:listPath] ||
                            (isDirectory && [createdEntry hasPrefix:[listPath stringByAppendingString:@"/"]])
                            ) {
                            contains = YES;
                            break;
                        }
                    }
                    if (contains) {
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
    
    FILE *fp = fopen(entryPath.fileSystemRepresentation, "rb");
    if (!fp) {
        NSError *checkError = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot open archive file \"%@\".", nil), entryPath]}];
        completionBlock(NO, @[], checkError);
        return;
    }
    int32_t header_magic;
    size_t numOfUnits = fread(&header_magic, 4, 1, fp);
    if (numOfUnits <= 0) {
        fclose(fp);
        NSError *checkError = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot recognize the format of archive file \"%@\".", nil), entryPath]}];
        completionBlock(NO, @[], checkError);
        return;
    }
    XXTEArchiveType archiveType;
    if (header_magic == kZipArchiveHeaderLocalDirMagic ||
        header_magic == kZipArchiveHeaderCentralDirMagic) {
        archiveType = XXTEArchiveTypeZip;
    }
#ifdef APPSTORE
    else if (header_magic == kRarArchiveHeaderMagic) {
        archiveType = XXTEArchiveTypeRar;
    }
#endif
    else {
        fclose(fp);
        NSError *checkError = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot process archive file \"%@\" (0x%02x).", nil), entryPath, header_magic]}];
        completionBlock(NO, @[], checkError);
        return;
    }
    fclose(fp);
    
    // busy lock
    if (self.busyOperationProgressFlag)
        return;
    self.busyOperationProgressFlag = YES;
    
    // extact delay in another thread
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
                
                if (archiveType == XXTEArchiveTypeZip) {
                    int arg = 2;
                    int status = zip_extract(from, to, will_extract, did_extract, &arg);
                    
                    result = (status == 0);
                }
#ifdef APPSTORE
                else if (archiveType == XXTEArchiveTypeRar) {
                    
                    NSString *fromPath = [[NSString alloc] initWithUTF8String:from];
                    URKArchive *rarArchive = [[URKArchive alloc] initWithPath:fromPath error:&error];
                    
                    result = (error == nil);
                    if ([rarArchive isPasswordProtected]) {
                        result = NO;
                        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot read archive file \"%@\": Password protected archive is not supported.", nil), entryPath]}];
                    } else {
                        if (rarArchive) {
                            NSString *toPath = [[NSString alloc] initWithUTF8String:to];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                            result = [rarArchive extractFilesTo:toPath overwrite:YES progress:did_extract_rar error:&error];
#pragma clang diagnostic pop
                        }
                    }
                    
                }
#endif
                
                // error handling
                if (NO == result) {
                    
                    if (!self.busyOperationProgressFlag) {
                        error = [NSError errorWithDomain:kXXTErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unarchiving process terminated: User interrupt occurred.", nil)}];
                    } else {
                        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot read archive file \"%@\".", nil), entryPath]}];
                    }
                    
                }
                
            }
            
            // update result in main thread
            dispatch_async_on_main_queue(^{
                
                self.busyOperationProgressFlag = NO;
//                if (singleMode) {
//                    completionBlock(result, [changedPaths copy], error);
//                } else {
                    completionBlock(result, @[ destinationPathWithIndex ], error);
//                }
                
            }); // end updating
            
        }); // end thread
        
    }); // end delay
    
}

@end
