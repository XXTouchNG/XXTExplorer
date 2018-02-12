//
//  NSString+VersionValue.m
//  XXTExplorer
//
//  Created by Zheng on 25/01/2018.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "NSString+VersionValue.h"

@implementation NSString (VersionValue)

static inline NSComparisonResult NSComparationInt(int a, int b) {
    if (a == b) return NSOrderedSame;
    return (a > b) ? (NSOrderedDescending) : (NSOrderedAscending);
}

- (NSComparisonResult)compareVersion:(nonnull NSString *)version {
    static NSCharacterSet *separatorSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" .-"];
    });
    int digit = 0, digit_v = 0;
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSScanner *scanner_v = [NSScanner scannerWithString:version];
    BOOL scan = [scanner scanInt:&digit];
    BOOL scan_v = [scanner_v scanInt:&digit_v];
    while (scan && scan_v) {
        if (digit != digit_v) {
            break;
        }
        digit = 0; digit_v = 0;
        [scanner scanCharactersFromSet:separatorSet intoString:nil];
        [scanner_v scanCharactersFromSet:separatorSet intoString:nil];
        scan = [scanner scanInt:&digit];
        scan_v = [scanner_v scanInt:&digit_v];
    }
    return NSComparationInt(digit, digit_v);
}

@end
