//
//  XXTExplorerItemRepeatViewController.h
//  XXTExplorer
//
//  Created by Zheng on 06/04/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerItemRepeatViewController : UITableViewController

@property (nonatomic, copy) NSString *entryPath;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path;

@end
