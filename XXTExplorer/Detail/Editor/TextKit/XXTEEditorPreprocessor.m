//
//  XXTEEditorPreprocessor.m
//  XXTExplorer
//
//  Created by Zheng on 02/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorPreprocessor.h"

@implementation XXTEEditorPreprocessor

+ (NSString *)preprocessedStringWithContentsOfFile:(NSString *)path
                                     NumberOfLines:(NSUInteger *)num
                                             Error:(NSError **)error
{
    NSString *rawString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
    NSString *newString = [rawString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    NSUInteger numberOfLines, index, stringLength = [newString length];
    for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
        index = NSMaxRange([newString lineRangeForRange:NSMakeRange(index, 0)]);
    *num = numberOfLines;
    return newString;
}

@end
