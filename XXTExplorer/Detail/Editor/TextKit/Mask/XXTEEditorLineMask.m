//
//  XXTEEditorLineMask.m
//  XXTExplorer
//
//  Created by MMM on 8/17/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorLineMask.h"

@implementation XXTEEditorLineMask

- (instancetype)init {
    self = [super init];
    if (self) {
        _lineIndex = NSNotFound;
        _maskType = XXTEEditorLineMaskNone;
        _maskDescription = nil;
        _relatedObject = nil;
    }
    return self;
}

@end
