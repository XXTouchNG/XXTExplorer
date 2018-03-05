//
//  XXTExplorerViewController+XXTImagePickerControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 17/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTImagePickerControllerDelegate.h"
#import <AssetsLibrary/AssetsLibrary.h>

#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"
#import "XXTExplorerViewController+Notification.h"

@implementation XXTExplorerViewController (XXTImagePickerControllerDelegate)

- (void)presentImagePickerController:(UIBarButtonItem *)buttonItem {
    NSBundle *frameBundle = [NSBundle mainBundle];
    XXTImagePickerController *controller = [[XXTImagePickerController alloc] initWithNibName:@"XXTImagePickerController" bundle:frameBundle];
    controller.delegate = self;
    controller.nResultType = XXT_PICKER_RESULT_ASSET;
    controller.nMaxCount = XXT_NO_LIMIT_SELECT;
    if (XXTE_IS_IPAD) {
        controller.nColumnCount = 6;
    } else if (XXTE_IS_IPHONE_6_BELOW) {
        controller.nColumnCount = 3;
    } else {
        controller.nColumnCount = 4;
    }
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

#pragma mark - XXTImagePickerControllerDelegate

- (void)didCancelImagePickerController:(XXTImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSelectPhotosFromImagePickerController:(XXTImagePickerController *)picker
                                          result:(NSArray *)aSelected
{
    if (aSelected.count == 0) {
        return; // do not accept or dismiss
    }
    UIViewController *blockVC = blockInteractions(self, YES);
    @weakify(self);
    [picker dismissViewControllerAnimated:YES completion:^{
        @strongify(self);
        NSString *currentDirectory = self.entryPath;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSUInteger succeedCount = 0;
            NSError *error = nil;
            NSMutableArray <NSString *> *importedPaths = [[NSMutableArray alloc] initWithCapacity:aSelected.count];
            for (ALAsset *asset in aSelected) {
                ALAssetRepresentation *assetRepr = asset.defaultRepresentation;
                if (assetRepr) {
                    Byte *buffer = (Byte *)malloc((size_t)assetRepr.size);
                    NSUInteger buffered = [assetRepr getBytes:buffer fromOffset:0 length:(NSUInteger)assetRepr.size error:&error];
                    if (error) {
                        continue;
                    }
                    NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                    if (assetRepr.filename) {
                        NSString *writePath = [currentDirectory stringByAppendingPathComponent:assetRepr.filename];
                        BOOL result = [data writeToFile:writePath atomically:YES];
                        if (result) {
                            [importedPaths addObject:writePath];
                            succeedCount++;
                        }
                    }
                }
            }
            dispatch_async_on_main_queue(^{
                toastMessage(self, ([NSString stringWithFormat:NSLocalizedString(@"Image(s) imported, %lu succeed, %lu failed.", nil), succeedCount, aSelected.count - succeedCount]));
                [self setEditing:YES animated:YES];
                [self loadEntryListData];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:XXTExplorerViewSectionIndexList] withRowAnimation:UITableViewRowAnimationAutomatic];
                {
                    [self.tableView reloadData];
                }
                [self selectCellEntriesAtPaths:importedPaths animated:NO];
                blockInteractions(blockVC, NO);
            });
        });
    }];
}

@end
