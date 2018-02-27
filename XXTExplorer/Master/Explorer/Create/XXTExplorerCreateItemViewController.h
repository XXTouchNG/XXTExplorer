//
//  XXTExplorerCreateItemViewController.h
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTExplorerCreateItemViewController;

@protocol XXTExplorerCreateItemViewControllerDelegate <NSObject>

- (void)createItemViewControllerDidDismiss:(XXTExplorerCreateItemViewController *)controller;
- (void)createItemViewController:(XXTExplorerCreateItemViewController *)controller didFinishCreatingItemAtPath:(NSString *)path;

@end

@interface XXTExplorerCreateItemViewController : UITableViewController

@property (nonatomic, weak) id <XXTExplorerCreateItemViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL editImmediately;

+ (NSDateFormatter *)itemTemplateDateFormatter;

@property (nonatomic, copy, readonly) NSString *entryPath;
- (instancetype)initWithEntryPath:(NSString *)entryPath;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
