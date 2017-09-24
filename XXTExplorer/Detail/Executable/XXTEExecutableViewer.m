//
//  XXTEExecutableViewer.m
//  XXTExplorer
//
//  Created by Zheng on 16/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEExecutableViewer.h"
#import "XXTExplorerEntryLauncher.h"

@implementation XXTEExecutableViewer

@synthesize entryPath = _entryPath, awakeFromOutside = _awakeFromOutside;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Launcher", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"lua", @"xxt", @"xpp" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryLauncher class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
    }
    return self;
}

@end
