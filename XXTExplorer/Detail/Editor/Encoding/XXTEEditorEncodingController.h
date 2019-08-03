//
//  XXTEEditorEncodingController.h
//  XXTExplorer
//
//  Created by Darwin on 8/2/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XXTEEditorEncodingController;

@protocol XXTEEditorEncodingControllerDelegate <NSObject>

@optional
- (void)encodingControllerDidConfirm:(XXTEEditorEncodingController *)controller;
- (void)encodingControllerDidChange:(XXTEEditorEncodingController *)controller;
- (void)encodingControllerDidCancel:(XXTEEditorEncodingController *)controller;

@end

@interface XXTEEditorEncodingController : UITableViewController

@property (nonatomic, weak) id <XXTEEditorEncodingControllerDelegate> delegate;
@property (nonatomic, assign) BOOL reopenMode;
@property (nonatomic, assign) CFStringEncoding selectedEncoding;

@end

NS_ASSUME_NONNULL_END
