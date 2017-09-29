//
//  XUIListViewController+SharedInstance.m
//  XXTExplorer
//
//  Created by Zheng Wu on 29/09/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIListViewController+SharedInstance.h"

@implementation XUIListViewController (SharedInstance)

+ (XXTExplorerEntryParser *)entryParser {
    static XXTExplorerEntryParser *entryParser = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!entryParser) {
            entryParser = [[XXTExplorerEntryParser alloc] init];
        }
    });
    return entryParser;
}

+ (XXTExplorerEntryService *)entryService {
    static XXTExplorerEntryService *entryService = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!entryService) {
            entryService = [XXTExplorerEntryService sharedInstance];
        }
    });
    return entryService;
}

@end
