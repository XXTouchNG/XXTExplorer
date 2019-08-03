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
#import "XXTEEditorTextProperties.h"


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
    NSString *rawString = CFBridgingRelease(CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, data.length, preferredEncoding, NO));
    if (!rawString) {
        *error = [NSError errorWithDomain:kXXTErrorInvalidStringEncodingDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot open file with encoding \"%@\".", nil), [XXTEEditorEncodingHelper encodingNameForEncoding:preferredEncoding]] }];
        return nil;
    } else {
#ifdef DEBUG
        NSLog(@"document opened with encoding %@: %@", [XXTEEditorEncodingHelper encodingNameForEncoding:preferredEncoding], path);
#endif
    }
    if ([rawString rangeOfString:@NSStringLineBreakCRLF].location != NSNotFound) {
        *lineBreak = NSStringLineBreakTypeCRLF;
    }
    else if ([rawString rangeOfString:@NSStringLineBreakCR].location != NSNotFound) {
        *lineBreak = NSStringLineBreakTypeCR;
    }
    else {
        *lineBreak = NSStringLineBreakTypeLF;
    }
    rawString = [rawString stringByReplacingOccurrencesOfString:@NSStringLineBreakCRLF withString:@NSStringLineBreakLF];
    rawString = [rawString stringByReplacingOccurrencesOfString:@NSStringLineBreakCR withString:@NSStringLineBreakLF];
    NSUInteger numberOfLines, index, stringLength = [rawString length];
    for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
        index = NSMaxRange([rawString lineRangeForRange:NSMakeRange(index, 0)]);
    *num = numberOfLines;
    return rawString;
}

@end
