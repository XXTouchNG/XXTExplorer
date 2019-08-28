//
//  XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <sys/stat.h>

#import "XXTExplorerViewController+XXTExplorerEntryOpenWithViewControllerDelegate.h"
#import "XXTExplorerViewController+ArchiverOperation.h"
#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerDefaults.h"
#import "XXTExplorerEntryService.h"

#import "XXTEArchiveViewer.h"
#import "XXTEExecutableViewer.h"

#import "XXTENavigationController.h"
#import "XXTExplorerViewCell.h"
#import "NSString+SHA1.h"

#import <XUI/XUIViewController.h>
#import <XUI/XUINavigationController.h>


@implementation XXTExplorerViewController (XXTExplorerEntryOpenWithViewControllerDelegate)

+ (NSDateFormatter *)historyDateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        formatter.timeZone = [NSTimeZone localTimeZone];
        formatter.locale = [NSLocale currentLocale];
    });
    return formatter;
}

#pragma mark - XXTExplorerEntryOpenWithViewControllerDelegate

- (void)openWithViewController:(XXTExplorerEntryOpenWithViewController *)controller viewerDidSelected:(NSString *)controllerName {
    [controller dismissViewControllerAnimated:YES completion:^{
        XXTExplorerEntry *entry = controller.entry;
        NSString *entryPath = entry.entryPath;
        UIViewController *detailController = [[self.class explorerEntryService] viewerWithName:controllerName forEntryPath:entryPath];
        [self tableView:self.tableView showDetailController:detailController];
    }];
}

- (void)tableView:(UITableView *)tableView showDetailController:(UIViewController *)controller {
    [self tableView:tableView showDetailController:controller animated:YES];
}

- (void)tableView:(UITableView *)tableView showDetailController:(UIViewController *)controller animated:(BOOL)animated {
    if ([controller isKindOfClass:[UIViewController class]] &&
        [controller conformsToProtocol:@protocol(XXTEDetailViewController)])
    {
        UIViewController <XXTEDetailViewController> *viewer = (UIViewController <XXTEDetailViewController> *)controller;
        NSString *entryPath = viewer.entryPath;
        if ([viewer isKindOfClass:[XXTEExecutableViewer class]])
        {
#ifndef APPSTORE
            [self performViewerExecutableActionForEntryAtPath:entryPath];
#endif
        }
        else if ([viewer isKindOfClass:[XXTEArchiveViewer class]]) {
            [self tableView:tableView unarchiveEntryCellTappedWithEntryPath:entryPath];
        }
        else
        {
            if (XXTE_COLLAPSED) {
                XXTE_START_IGNORE_PARTIAL
                if (@available(iOS 8.0, *)) {
                    XXTENavigationController *navigationController = [[XXTENavigationController alloc] initWithRootViewController:viewer];
                    [self.splitViewController showDetailViewController:navigationController sender:self];
                }
                XXTE_END_IGNORE_PARTIAL
            } else {
                [self.navigationController pushViewController:viewer animated:animated];
            }
        }
        [self linkHistoryEntryAtPath:entryPath];
    }
}

- (void)tableView:(UITableView *)tableView showFormSheetController:(UIViewController *)controller {
    if ([controller isKindOfClass:[UIViewController class]] &&
        [controller conformsToProtocol:@protocol(XXTEDetailViewController)]) {
        UIViewController <XXTEDetailViewController> *viewer = (UIViewController <XXTEDetailViewController> *)controller;
        {
            UIViewController *navigationController = nil;
            if ([viewer isKindOfClass:[XUIViewController class]]) {
                navigationController = [[XUINavigationController alloc] initWithRootViewController:viewer];
            } else {
                navigationController = [[XXTENavigationController alloc] initWithRootViewController:viewer];
            }
            navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
            navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            navigationController.presentationController.delegate = self;
            [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
        }
    }
}

- (void)linkHistoryEntryAtPath:(NSString *)entryPath {
    if (self.historyMode) return;
    NSFileManager *manager = [[self class] explorerFileManager];
    
    NSString *historyRelativePath = uAppDefine(XXTExplorerViewBuiltHistoryPath);
    NSString *historyRootPath = [XXTERootPath() stringByAppendingPathComponent:historyRelativePath];
    NSURL *historyRootURL = [NSURL fileURLWithPath:historyRootPath];
    
    NSInteger historyLimitChoice = XXTEDefaultsInt(XXTExplorerHistoryStoreLimit, 3);
    NSTimeInterval historyLimit;
    switch (historyLimitChoice) {
        case 0:
            historyLimit = 604800;
            break;
        case 1:
            historyLimit = 604800 * 2;
            break;
        case 2:
            historyLimit = 2592000;
            break;
        case 3:
            historyLimit = 7776000;
            break;
        case 4:
            historyLimit = 15552000;
            break;
        case 5:
            historyLimit = 31536000;
            break;
        case 6:
            historyLimit = INT_MAX;
            break;
        default:
            historyLimit = 7776000;
            break;
    }
    
    NSDirectoryEnumerator *enumerator = [manager enumeratorAtURL:historyRootURL
                                      includingPropertiesForKeys:@[ NSURLPathKey, NSURLIsDirectoryKey ]
                                                         options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                    errorHandler:^BOOL(NSURL *url, NSError *error) {
#ifdef DEBUG
        NSLog(@"[Error] %@ (%@)", error, url);
#endif
        return YES;
    }];
    
    NSDateFormatter *dateFormatter = [[self class] historyDateFormatter];
    for (NSURL *dateDirectoryURL in enumerator) {
        NSNumber *isPathDirectory = nil;
        [dateDirectoryURL getResourceValue:&isPathDirectory forKey:NSURLIsDirectoryKey error:nil];
        if (![isPathDirectory boolValue]) {
            continue;
        }
        
        NSString *dateDirectoryPath = nil;
        [dateDirectoryURL getResourceValue:&dateDirectoryPath forKey:NSURLPathKey error:nil];
        
        NSString *dateDirectoryName = [dateDirectoryPath lastPathComponent];
        NSDate *dateDirectoryDate = [dateFormatter dateFromString:dateDirectoryName];
        if (!dateDirectoryDate) {
            continue;
        }
        
        if (fabs([dateDirectoryDate timeIntervalSinceNow]) > historyLimit)
        {
            [manager removeItemAtURL:dateDirectoryURL error:nil];
        }
    }
    
    NSString *historyDatePath = [historyRootPath stringByAppendingPathComponent:[dateFormatter stringFromDate:[NSDate date]]];
    [manager createDirectoryAtPath:historyDatePath withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSString *pathHash = [entryPath sha1String];
    if (pathHash.length > 8) {
        NSString *pathSubhash = [pathHash substringToIndex:7];
        NSString *entryName = [entryPath lastPathComponent];
        NSString *entryLinkName = [pathSubhash stringByAppendingFormat:@"@%@", entryName];
        NSString *entryLinkPath = [historyDatePath stringByAppendingPathComponent:entryLinkName];
        NSError *linkError = nil;
        if (entryLinkPath.length > 0 && entryPath.length > 0) {
            NSError *cleanError = nil;
            struct stat cleanStat;
            if (0 == lstat(entryLinkPath.fileSystemRepresentation, &cleanStat)) {
                [manager removeItemAtPath:entryLinkPath error:&cleanError];
            }
            [manager createSymbolicLinkAtURL:[NSURL fileURLWithPath:entryLinkPath] withDestinationURL:[NSURL fileURLWithPath:entryPath] error:&linkError];
        }
    }
}

@end
