//
//  XXTEUIViewController+XUIFileCell.m
//  XXTExplorer
//
//  Created by Zheng Wu on 29/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEUIViewController+XUIFileCell.h"
#import "XUIFileCell.h"

#import <objc/runtime.h>

static const void * XUIFileCellStorageKey = &XUIFileCellStorageKey;

@implementation XXTEUIViewController (XUIFileCell)

- (void)tableView:(UITableView *)tableView XUIFileCell:(UITableViewCell *)cell {
    XUIFileCell *fileCell = (XUIFileCell *)cell;
    NSString *bundlePath = [self.bundle bundlePath];
    NSString *initialPath = fileCell.xui_initialPath;
    BOOL isFile = [fileCell.xui_isFile boolValue];
    
    if (initialPath) {
        if ([initialPath isAbsolutePath]) {
            
        } else {
            initialPath = [bundlePath stringByAppendingPathComponent:initialPath];
        }
    } else {
        initialPath = bundlePath;
    }
    objc_setAssociatedObject(self, XUIFileCellStorageKey, fileCell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    XXTExplorerItemPicker *itemPicker = [[XXTExplorerItemPicker alloc] initWithEntryPath:initialPath];
    itemPicker.delegate = self;
    itemPicker.allowedExtensions = fileCell.xui_allowedExtensions;
    itemPicker.isFile = isFile;
    [self.navigationController pushViewController:itemPicker animated:YES];
}

#pragma mark - XXTExplorerItemPickerDelegate

- (void)itemPicker:(XXTExplorerItemPicker *)picker didSelectItemAtPath:(NSString *)path {
    XUIFileCell *fileCell = objc_getAssociatedObject(self, XUIFileCellStorageKey);
    if ([fileCell isKindOfClass:[XUIFileCell class]]) {
        fileCell.xui_value = path;
        [self storeCellWhenNeeded:fileCell];
        [self storeCellsIfNecessary];
        [self.navigationController popToViewController:self animated:YES];
    }
    objc_setAssociatedObject(self, XUIFileCellStorageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [fileCell setNeedsLayout];
    [fileCell layoutIfNeeded];
}

@end
