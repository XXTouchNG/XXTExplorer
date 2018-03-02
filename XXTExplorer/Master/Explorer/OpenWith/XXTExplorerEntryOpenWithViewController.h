//
//  XXTExplorerEntryOpenWithViewController.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTExplorerEntryOpenWithViewController, XXTExplorerEntry;

@protocol XXTExplorerEntryOpenWithViewControllerDelegate <NSObject>

- (void)openWithViewController:(XXTExplorerEntryOpenWithViewController *)controller viewerDidSelected:(NSString *)controllerName;

@end

@interface XXTExplorerEntryOpenWithViewController : UITableViewController

@property (nonatomic, copy, readonly) XXTExplorerEntry *entry;
@property (nonatomic, weak) id <XXTExplorerEntryOpenWithViewControllerDelegate> delegate;

- (instancetype)initWithEntry:(XXTExplorerEntry *)entry;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
