//
//  XXTETextPreprocessor.m
//  XXTExplorer
//
//  Created by Zheng on 02/10/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTETextPreprocessor.h"

#import "XXTEAppDefines.h"
#import "XXTExplorerDefaults.h"
#import "XXTEEncodingController.h"
#import "XXTEEncodingHelper.h"
#import "XXTEEditorTextProperties.h"


@implementation XXTETextPreprocessor

+ (NSString *)preprocessedStringWithContentsOfFile:(NSString *)path
                                     NumberOfLines:(NSUInteger *)num
                                          Encoding:(CFStringEncoding *)encoding
                                         LineBreak:(NSStringLineBreakType *)lineBreak
                                     MaximumLength:(NSUInteger *)len
                                             Error:(NSError **)error
{
    NSData *data = nil;
    if (!len) {
        data = [[NSData alloc] initWithContentsOfFile:path options:kNilOptions error:error];
    } else {
        NSURL *pathURL = [NSURL fileURLWithPath:path];
        NSUInteger actualLen = *len;
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:pathURL error:error];
        data = [handle readDataOfLength:actualLen];
        [handle closeFile];
    }
    if (!data) {
        return nil;
    }
    CFStringEncoding preferredEncoding = kCFStringEncodingInvalidId;
    if (encoding && *encoding != kCFStringEncodingInvalidId) {
        preferredEncoding = *encoding;
    } else {
        NSInteger encodingIndex = XXTEDefaultsInt(XXTExplorerDefaultEncodingKey, 0);
        CFStringEncoding encoding = [XXTEEncodingHelper encodingAtIndex:encodingIndex];
        preferredEncoding = encoding;
    }
    if (preferredEncoding == kCFStringEncodingInvalidId) {
        return nil;
    }
    NSString *rawString = CFBridgingRelease(CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, data.length, preferredEncoding, NO));
    if (!rawString) {
        *error = [NSError errorWithDomain:kXXTErrorInvalidStringEncodingDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Cannot open file with encoding \"%@\".", nil), [XXTEEncodingHelper encodingNameForEncoding:preferredEncoding]] }];
        return nil;
    } else {
#ifdef DEBUG
        NSLog(@"document opened with encoding %@: %@", [XXTEEncodingHelper encodingNameForEncoding:preferredEncoding], path);
#endif
    }
    if (lineBreak) {
        if ([rawString rangeOfString:@NSStringLineBreakCRLF].location != NSNotFound) {
            *lineBreak = NSStringLineBreakTypeCRLF;
        }
        else if ([rawString rangeOfString:@NSStringLineBreakCR].location != NSNotFound) {
            *lineBreak = NSStringLineBreakTypeCR;
        }
        else {
            *lineBreak = NSStringLineBreakTypeLF;
        }
    }
    rawString = [rawString stringByReplacingOccurrencesOfString:@NSStringLineBreakCRLF withString:@NSStringLineBreakLF];
    rawString = [rawString stringByReplacingOccurrencesOfString:@NSStringLineBreakCR withString:@NSStringLineBreakLF];
    if (num) {
        NSUInteger numberOfLines, index, stringLength = [rawString length];
        for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
            index = NSMaxRange([rawString lineRangeForRange:NSMakeRange(index, 0)]);
        *num = numberOfLines;
    }
    return rawString;
}

@end
