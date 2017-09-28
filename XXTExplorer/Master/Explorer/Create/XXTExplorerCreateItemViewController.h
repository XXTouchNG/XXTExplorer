//
//  XXTExplorerCreateItemViewController.h
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerCreateItemViewController : UITableViewController

+ (NSDateFormatter *)itemTemplateDateFormatter;
- (instancetype)initWithEntryPath:(NSString *)entryPath;

@end
