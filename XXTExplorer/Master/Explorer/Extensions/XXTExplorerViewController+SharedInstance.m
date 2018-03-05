//
//  XXTExplorerViewController+SharedInstance.m
//  XXTExplorer
//
//  Created by Zheng on 2017/8/6.
//  Copyright © 2017年 Zheng. All rights reserved.
//

#import "XXTExplorerViewController+SharedInstance.h"

#import "XXTExplorerDefaults.h"

#import "XXTExplorerEntryParser.h"
#import "XXTExplorerEntryService.h"

static BOOL _kXXTExplorerFetchingSelectedScript = NO;

@implementation XXTExplorerViewController (SharedInstance)

+ (BOOL)isFetchingSelectedScript {
    return _kXXTExplorerFetchingSelectedScript;
}

+ (void)setFetchingSelectedScript:(BOOL)fetching {
    _kXXTExplorerFetchingSelectedScript = fetching;
}

+ (NSString *)initialPath {
    static NSString *initialPath = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!initialPath) {
            initialPath = ({
                NSString *initialRelativePath = uAppDefine(XXTExplorerViewBuiltInitialPath);
                [XXTERootPath() stringByAppendingPathComponent:initialRelativePath];
            });
        }
    });
    return initialPath;
}

+ (NSFileManager *)explorerFileManager {
    static NSFileManager *explorerFileManager = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!explorerFileManager) {
            explorerFileManager = ({
                [[NSFileManager alloc] init];
            });
        }
    });
    return explorerFileManager;
}

+ (XXTExplorerEntryParser *)explorerEntryParser {
    static XXTExplorerEntryParser *explorerEntryParser = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!explorerEntryParser) {
            explorerEntryParser = [[XXTExplorerEntryParser alloc] init];
        }
    });
    return explorerEntryParser;
}

+ (XXTExplorerEntryService *)explorerEntryService {
    static XXTExplorerEntryService *explorerEntryService = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        if (!explorerEntryService) {
            explorerEntryService = [XXTExplorerEntryService sharedInstance];
        }
    });
    return explorerEntryService;
}

+ (NSString *)selectedScriptPath {
    return XXTEDefaultsObject(XXTExplorerViewEntrySelectedScriptPathKey, nil);
}

@end
