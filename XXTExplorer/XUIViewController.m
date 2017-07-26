//
// Created by Zheng on 26/07/2017.
// Copyright (c) 2017 Zheng. All rights reserved.
//

#import "XUIViewController.h"
#import "XUIEntryReader.h"

@implementation XUIViewController

@synthesize entryPath = _entryPath;

+ (NSString *)viewerName {
    return NSLocalizedString(@"Interface Viewer", nil);
}

+ (NSArray <NSString *> *)suggestedExtensions {
    return @[@"xui", @"json", @"plist"];
}

+ (Class)relatedReader {
    return [XUIEntryReader class];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {

    }
    return self;
}

@end
