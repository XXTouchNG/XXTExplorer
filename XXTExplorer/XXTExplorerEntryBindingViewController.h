//
//  XXTExplorerEntryBindingViewController.h
//  XXTExplorer
//
//  Created by Zheng on 15/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XXTExplorerEntryBindingViewController;

@protocol XXTExplorerEntryBindingViewControllerDelegate <NSObject>

- (void)bindingViewController:(XXTExplorerEntryBindingViewController *)controller bindingDidChanged:(NSString *)controllerName;

@end

@interface XXTExplorerEntryBindingViewController : UITableViewController

@property (nonatomic, copy, readonly) NSString *extension;
@property (nonatomic, weak) id <XXTExplorerEntryBindingViewControllerDelegate> delegate;

- (instancetype)initWithExtension:(NSString *)extension;

@end
