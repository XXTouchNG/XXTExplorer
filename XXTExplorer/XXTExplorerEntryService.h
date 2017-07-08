//
//  XXTExplorerEntryService.h
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XXTExplorerEntryService : NSObject

- (BOOL)hasDefaultViewControllerForEntry:(NSDictionary *)entry;
- (UIViewController *)defaultViewControllerForEntry:(NSDictionary *)entry;
- (UIViewController *)openInControllerForEntry:(NSDictionary *)entry;

@end
