//
//  XXTExplorerEntryUpdateDelegate.h
//  XXTExplorer
//
//  Created by Zheng on 2018/4/15.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XXTExplorerEntryUpdateDelegate <NSObject>

@optional
- (void)explorerEntryUpdater:(id)sender entryDidUpdatedAtPath:(NSString *)entryPath;

@end
