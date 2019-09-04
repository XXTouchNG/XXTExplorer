//
//  XXTEEditorLineBreakController.h
//  XXTouch
//
//  Created by Darwin on 8/3/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XXTEEditorTextProperties.h"

NS_ASSUME_NONNULL_BEGIN

@class XXTEEditorLineBreakController;

@protocol XXTEEditorLineBreakControllerDelegate <NSObject>

@optional
- (BOOL)linebreakControllerCanSaveDocument:(XXTEEditorLineBreakController *)controller;
- (void)linebreakControllerDidChange:(XXTEEditorLineBreakController *)controller shouldSave:(BOOL)save;

@end

@interface XXTEEditorLineBreakController : UITableViewController

@property (nonatomic, weak) id <XXTEEditorLineBreakControllerDelegate> delegate;
@property (nonatomic, assign) NSStringLineBreakType selectedLineBreakType;

@end

NS_ASSUME_NONNULL_END
