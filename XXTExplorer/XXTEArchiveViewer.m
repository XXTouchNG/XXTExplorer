//
//  XXTEArchiveViewer.m
//  XXTExplorer
//
//  Created by Zheng on 16/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEArchiveViewer.h"
#import "XXTExplorerEntryArchiver.h"

@implementation XXTEArchiveViewer

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return @"Archiver";
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[ @"zip" ];
}

+ (Class)relatedReader {
    return [XXTExplorerEntryArchiver class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _entryPath = path;
    }
    return self;
}

@end
