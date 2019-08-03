//
//  XXTEEditorLineBreakHelper.m
//  XXTExplorer
//
//  Created by Darwin on 8/3/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorLineBreakHelper.h"

@implementation XXTEEditorLineBreakHelper

+ (NSDictionary *)lineBreakMap {
    static NSDictionary *lineBreakMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lineBreakMap = @{
                        @(NSStringLineBreakTypeLF): @"LF (Unix)",
                        @(NSStringLineBreakTypeCRLF): @"CRLF (Windows)",
                        @(NSStringLineBreakTypeCR): @"CR (Mac)",
                        };
    });
    return lineBreakMap;
}

+ (NSString *)lineBreakNameForType:(NSStringLineBreakType)type {
    return [[self class] lineBreakMap][@(type)];
}

@end
