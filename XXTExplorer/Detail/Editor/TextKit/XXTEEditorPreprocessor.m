//
//  XXTEEditorPreprocessor.m
//  XXTExplorer
//
//  Created by Zheng on 02/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorPreprocessor.h"
#import "XXTEAppDefines.h"
#import "XXTEEditorEncodingController.h"
#import "XXTEEditorEncodingHelper.h"


static NSString *kXXTErrorInvalidStringEncodingDomain = @"com.darwindev.XXTExplorer.error.invalid-string-encoding";

@implementation XXTEEditorPreprocessor

+ (NSString *)preprocessedStringWithContentsOfFile:(NSString *)path
                                     NumberOfLines:(NSUInteger *)num
                                          Encoding:(CFStringEncoding *)encoding
                                         LineBreak:(NSStringLineBreakType *)lineBreak
                                             Error:(NSError **)error
{
    NSData *data = [[NSData alloc] initWithContentsOfFile:path options:kNilOptions error:error];
    if (!data) {
        return nil;
    }
    CFStringEncoding preferredEncoding = *encoding;
    if (preferredEncoding == kCFStringEncodingInvalidId) {
        return nil;
    }
    CFStringRef cfString = CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, data.length, preferredEncoding, NO);
    NSString *rawString = (__bridge NSString *)(cfString);
    if (!rawString) {
        *error = [NSError errorWithDomain:kXXTErrorInvalidStringEncodingDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot open file with encoding \"%@\".", nil), [XXTEEditorEncodingHelper encodingNameForEncoding:preferredEncoding]] }];
        return nil;
    } else {
#ifdef DEBUG
        NSLog(@"document opened with encoding %@: %@", [XXTEEditorEncodingHelper encodingNameForEncoding:preferredEncoding], path);
#endif
    }
    if ([rawString rangeOfString:@"\r\n"].location != NSNotFound) {
        *lineBreak = NSStringLineBreakTypeCRLF;
    }
    else if ([rawString rangeOfString:@"\r"].location != NSNotFound) {
        *lineBreak = NSStringLineBreakTypeCR;
    }
    else {
        *lineBreak = NSStringLineBreakTypeLF;
    }
    rawString = [rawString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    rawString = [rawString stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    NSUInteger numberOfLines, index, stringLength = [rawString length];
    for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
        index = NSMaxRange([rawString lineRangeForRange:NSMakeRange(index, 0)]);
    *num = numberOfLines;
    return rawString;
}

@end
