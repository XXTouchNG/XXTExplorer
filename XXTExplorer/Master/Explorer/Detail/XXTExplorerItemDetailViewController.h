//
//  XXTExplorerItemDetailViewController.h
//  XXTExplorer
//
//  Created by Zheng on 10/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerItemDetailViewController : UITableViewController

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path;
+ (BOOL)checkRecordingScript:(NSString *)entryPath;

@end
