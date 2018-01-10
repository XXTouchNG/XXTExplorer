//
//  XXTExplorerItemGroupViewController.h
//  XXTExplorer
//
//  Created by Zheng on 08/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerItemGroupViewController : UITableViewController

@property (nonatomic, strong) NSString *entryPath;
- (instancetype)initWithPath:(NSString *)path;

@end
