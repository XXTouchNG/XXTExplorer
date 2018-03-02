//
//  XXTExplorerEntryBindingViewController.h
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTExplorerEntryBindingViewController, XXTExplorerEntry;

@protocol XXTExplorerEntryBindingViewControllerDelegate <NSObject>

- (void)bindingViewController:(XXTExplorerEntryBindingViewController *)controller bindingDidChanged:(NSString *)controllerName;

@end

@interface XXTExplorerEntryBindingViewController : UITableViewController

@property (nonatomic, copy, readonly) XXTExplorerEntry *entry;
@property (nonatomic, weak) id <XXTExplorerEntryBindingViewControllerDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithEntry:(XXTExplorerEntry *)entry;

@end
