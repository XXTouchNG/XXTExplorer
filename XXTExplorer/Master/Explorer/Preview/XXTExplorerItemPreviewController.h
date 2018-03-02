//
//  XXTExplorerItemPreviewController.h
//  XXTExplorer
//
//  Created by Zheng Wu on 2018/2/26.
//  Copyright © 2018年 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTExplorerItemPreviewController, XXTExplorerEntry;

@protocol XXTExplorerItemPreviewDelegate <NSObject>

@end

@protocol XXTExplorerItemPreviewActionDelegate <NSObject>

XXTE_START_IGNORE_PARTIAL
- (NSArray <UIPreviewAction *> *)itemPreviewController:(XXTExplorerItemPreviewController *)controller previewActionsForEntry:(XXTExplorerEntry *)entry;
XXTE_END_IGNORE_PARTIAL

@end

@interface XXTExplorerItemPreviewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, copy) NSString *entryPath;
@property (nonatomic, copy, readonly) XXTExplorerEntry *entry;

@property (nonatomic, weak) id <XXTExplorerItemPreviewDelegate> previewDelegate;
@property (nonatomic, weak) id <XXTExplorerItemPreviewActionDelegate> previewActionDelegate;
@property (nonatomic, weak) id previewActionSender;

@end
