//
//  XXTExplorerViewController+SharedInstance.h
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController.h"

@class XXTExplorerEntryParser, XXTExplorerEntryService;

@interface XXTExplorerViewController (SharedInstance)

+ (NSString *)initialPath;
+ (NSFileManager *)explorerFileManager;

+ (NSString *)selectedScriptPath;
+ (BOOL)isFetchingSelectedScript;
+ (void)setFetchingSelectedScript:(BOOL)fetching;

+ (XXTExplorerEntryParser *)explorerEntryParser;
+ (XXTExplorerEntryService *)explorerEntryService;

@end
