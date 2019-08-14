//
//  XXTETextPreprocessor.h
//  XXTExplorer
//
//  Created by Zheng on 02/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXTEEditorTextProperties.h"


static NSString *kXXTErrorInvalidStringEncodingDomain = @"com.darwindev.XXTExplorer.error.invalid-string-encoding";

@interface XXTETextPreprocessor : NSObject

+ (NSString *)preprocessedStringWithContentsOfFile:(NSString *)path
                                     NumberOfLines:(NSUInteger *)num
                                          Encoding:(CFStringEncoding *)encoding
                                         LineBreak:(NSStringLineBreakType *)lineBreak
                                     MaximumLength:(NSUInteger *)len
                                             Error:(NSError **)error;
+ (BOOL)stringHasLongLine:(NSString *)string LineBreak:(NSStringLineBreakType)lineBreak;
+ (NSRange)lineRangeForString:(NSString *)string AtIndex:(NSInteger)target;

@end
