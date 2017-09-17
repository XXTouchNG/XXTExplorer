//
//  XXTExplorerViewController+UIDocumentMenuDelegate.m
//  XXTExplorer
//
//  Created by Zheng on 17/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+UIDocumentMenuDelegate.h"
#import "XXTExplorerViewController+UIDocumentPickerDelegate.h"

@implementation XXTExplorerViewController (UIDocumentMenuDelegate)

- (void)documentMenuWasCancelled:(UIDocumentMenuViewController *)documentMenu {
    
}

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    [self.navigationController presentViewController:documentPicker animated:YES completion:nil];
}

@end
