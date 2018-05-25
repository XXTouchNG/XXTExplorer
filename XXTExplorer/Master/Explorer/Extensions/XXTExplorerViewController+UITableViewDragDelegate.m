//
//  XXTExplorerViewController+UITableViewDragDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 2018/5/14.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+UITableViewDragDelegate.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation XXTExplorerViewController (UITableViewDragDelegate)

XXTE_START_IGNORE_PARTIAL
- (NSArray <UIDragItem *> *)tableView:(UITableView *)tableView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != XXTExplorerViewSectionIndexList) {
        return @[];
    }
    NSUInteger idx = indexPath.row;
    if (idx >= self.entryList.count) {
        return @[];
    }
    XXTExplorerEntry *entry = self.entryList[indexPath.row];
    NSItemProvider *provider = [[NSItemProvider alloc] init];
    [provider registerFileRepresentationForTypeIdentifier:(NSString *)kUTTypeItem fileOptions:0 visibility:NSItemProviderRepresentationVisibilityAll loadHandler:^NSProgress * _Nullable(void (^ _Nonnull completionHandler)(NSURL * _Nullable, BOOL, NSError * _Nullable)) {
        completionHandler([NSURL fileURLWithPath:entry.entryPath], NO, nil);
        return nil;
    }];
    UIDragItem *dragItem = [[UIDragItem alloc] initWithItemProvider:provider];
    return @[ dragItem ];
}
XXTE_END_IGNORE_PARTIAL

@end