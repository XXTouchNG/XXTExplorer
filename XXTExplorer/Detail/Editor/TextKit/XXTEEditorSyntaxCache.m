//
//  XXTEEditorSyntaxCache.m
//  XXTExplorer
//
//  Created by Darwin on 8/7/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import "XXTEEditorSyntaxCache.h"

@implementation XXTEEditorSyntaxCache

- (BOOL)isEqual:(XXTEEditorSyntaxCache *)object
{
    return self.referencedParser == object.referencedParser && [self.text isEqualToString:object.text];
}

@end
