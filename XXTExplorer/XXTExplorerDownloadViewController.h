//
// Created by Zheng on 11/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerDownloadViewController : UITableViewController
// supports single file, single thread download with progress bar and error handling.

- (instancetype)initWithSourceURL:(NSURL *)url targetPath:(NSString *)path;

@end
