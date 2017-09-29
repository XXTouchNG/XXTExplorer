//
//  XUIListViewController+XUITitleValueCell.m
//  XXTExplorer
//
//  Created by Zheng Wu on 29/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIListViewController+XUITitleValueCell.h"
#import "XXTEObjectViewController.h"

#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"

#import <objc/runtime.h>

static const void * XUITitleValueCellStorageKey = &XUITitleValueCellStorageKey;

@implementation XUIListViewController (XUITitleValueCell)

- (void)tableView:(UITableView *)tableView XUITitleValueCell:(UITableViewCell *)cell {
    XUITitleValueCell *titleValueCell = (XUITitleValueCell *)cell;
    if (titleValueCell.xui_value) {
        id extendedValue = titleValueCell.xui_value;
        XXTEObjectViewController *objectViewController = [[XXTEObjectViewController alloc] initWithRootObject:extendedValue];
        objectViewController.title = titleValueCell.textLabel.text;
        objectViewController.entryBundle = self.bundle;
        [self.navigationController pushViewController:objectViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryXUITitleValueCell:(XUITitleValueCell *)cell {
    XUITitleValueCell *titleValueCell = (XUITitleValueCell *)cell;
    if (titleValueCell.xui_snippet) {
        NSString *snippetPath = [self.bundle pathForResource:titleValueCell.xui_snippet ofType:nil];
        NSError *snippetError = nil;
        XXTPickerSnippet *snippet = [[XXTPickerSnippet alloc] initWithContentsOfFile:snippetPath Error:&snippetError];
        if (snippetError) {
            [self presentErrorAlertController:snippetError];
            return;
        }
        XXTPickerFactory *factory = [XXTPickerFactory sharedInstance];
        factory.delegate = self;
        [factory executeTask:snippet fromViewController:self];
        objc_setAssociatedObject(self, XUITitleValueCellStorageKey, titleValueCell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - XXTPickerFactoryDelegate

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldEnterNextStep:(XXTPickerSnippet *)task {
    return YES;
}

- (BOOL)pickerFactory:(XXTPickerFactory *)factory taskShouldFinished:(XXTPickerSnippet *)task {
    blockInteractionsWithDelay(self, YES, 0);
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @strongify(self);
        NSError *error = nil;
        id result = [task generateWithError:&error];
        dispatch_async_on_main_queue(^{
            blockInteractions(self, NO);
            if (result) {
                XUITitleValueCell *cell = objc_getAssociatedObject(self, XUITitleValueCellStorageKey);
                if ([cell isKindOfClass:[XUITitleValueCell class]]) {
                    cell.xui_value = result;
                    [self storeCellWhenNeeded:cell];
                    [self storeCellsIfNecessary];
                }
                objc_setAssociatedObject(self, XUITitleValueCellStorageKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            } else {
                [self presentErrorAlertController:error];
            }
        });
    });
    return YES;
}

@end
