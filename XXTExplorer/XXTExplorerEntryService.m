//
//  XXTExplorerEntryService.m
//  XXTExplorer
//
//  Created by Zheng on 11/06/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTExplorerEntryService.h"

@interface XXTExplorerEntryService ()

@end

@implementation XXTExplorerEntryService

- (BOOL)hasDefaultViewControllerForEntry:(NSDictionary *)entry {
    return NO;
}

- (UIViewController *)defaultViewControllerForEntry:(NSDictionary *)entry {
    return nil;
}

- (UIViewController *)openInControllerForEntry:(NSDictionary *)entry {
    return nil;
}

@end
