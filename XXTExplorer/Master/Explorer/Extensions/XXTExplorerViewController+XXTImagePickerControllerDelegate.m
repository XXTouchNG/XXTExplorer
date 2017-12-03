//
//  XXTExplorerViewController+XXTImagePickerControllerDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 17/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+XXTImagePickerControllerDelegate.h"
#import "XXTEUserInterfaceDefines.h"
#import "XXTEDispatchDefines.h"
#import <AssetsLibrary/AssetsLibrary.h>

#import "XXTExplorerViewController+XXTExplorerToolbarDelegate.h"
#import "XXTExplorerViewController+Notification.h"

@implementation XXTExplorerViewController (XXTImagePickerControllerDelegate)

- (void)presentImagePickerController {
    NSBundle *frameBundle = [NSBundle mainBundle];
    XXTImagePickerController *cont = [[XXTImagePickerController alloc] initWithNibName:@"XXTImagePickerController" bundle:frameBundle];
    cont.delegate = self;
    cont.nResultType = XXT_PICKER_RESULT_ASSET;
    cont.nMaxCount = XXT_NO_LIMIT_SELECT;
    cont.nColumnCount = 4;
    [self.navigationController presentViewController:cont animated:YES completion:nil];
}

#pragma mark - XXTImagePickerControllerDelegate

- (void)didCancelImagePickerController:(XXTImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)didSelectPhotosFromImagePickerController:(XXTImagePickerController *)picker
                                          result:(NSArray *)aSelected
{
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
                [self selectCellEntriesAtPaths:importedPaths];
                blockInteractions(blockVC, NO);
            });
        });
    }];
}

@end
