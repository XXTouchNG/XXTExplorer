//
//  XXTECodeViewerSettingsController.h
//  XXTExplorer
//
//  Created by Darwin on 7/29/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XXTECodeViewerSettingsController;

@protocol XXTECodeViewerSettingsControllerDelegate <NSObject>
- (void)codeViewerSettingsControllerDidChange:(XXTECodeViewerSettingsController *)controller;

@end

@interface XXTECodeViewerSettingsController : UITableViewController
@property (nonatomic, weak) id <XXTECodeViewerSettingsControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
