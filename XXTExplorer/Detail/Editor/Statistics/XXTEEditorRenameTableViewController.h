//
//  XXTEEditorRenameTableViewController.h
//  XXTExplorer
//
//  Created by Darwin on 8/30/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XXTEEditorRenameTableViewController;

@protocol XXTEEditorRenameTableViewControllerDelegate <NSObject>
- (void)renameTableViewController:(XXTEEditorRenameTableViewController *)controller itemDidMoveToPath:(NSString *)path;

@end

@interface XXTEEditorRenameTableViewController : UITableViewController

@property (nonatomic, weak) id <XXTEEditorRenameTableViewControllerDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *path;
- (instancetype)initWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
