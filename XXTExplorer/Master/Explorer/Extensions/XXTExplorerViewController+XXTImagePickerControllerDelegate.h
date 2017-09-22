//
//  XXTExplorerViewController+XXTImagePickerControllerDelegate.h
//  XXTExplorer
//
//  Created by Zheng on 17/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"
#import "XXTImagePickerController.h"

@interface XXTExplorerViewController (XXTImagePickerControllerDelegate) <XXTImagePickerControllerDelegate>

- (void)presentImagePickerController;

@end
