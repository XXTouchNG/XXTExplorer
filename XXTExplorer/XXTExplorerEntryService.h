//
//  XXTExplorerEntryService.h
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XXTEViewer;

@interface XXTExplorerEntryService : NSObject

- (BOOL)hasDefaultViewControllerForEntry:(NSDictionary *)entry;
- (UIViewController <XXTEViewer> *)viewControllerForEntry:(NSDictionary *)entry;
- (UIViewController *)openInControllerForEntry:(NSDictionary *)entry;

@end
