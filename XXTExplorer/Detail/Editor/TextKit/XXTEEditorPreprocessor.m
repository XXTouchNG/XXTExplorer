//
//  XXTEEditorPreprocessor.m
//  XXTExplorer
//
//  Created by Zheng on 02/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorPreprocessor.h"

@implementation XXTEEditorPreprocessor

+ (NSString *)preprocessedStringWithContentsOfFile:(NSString *)path Error:(NSError **)error {
    NSString *rawString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
    NSString *newString = [rawString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    return newString;
}

@end
