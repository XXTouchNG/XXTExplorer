//
//  NSString+Template.m
//  XXTExplorer
//
//  Created by Zheng on 2018/5/12.
//  Copyright © 2018 Zheng. All rights reserved.
//

#import "NSString+Template.h"

@implementation NSString (Template)

- (NSString *)stringByReplacingTagsInDictionary:(NSDictionary *)dictionary {
    if (!dictionary || dictionary.count == 0) return [self copy];
    NSString *htmlTemplate = self;
    NSMutableString *htmlString = [[NSMutableString alloc] initWithString:htmlTemplate];
    
    NSRegularExpression *tagRegExp = [[NSRegularExpression alloc] initWithPattern:@"\\{\\{\\s*([A-Za-z0-9|_]+)\\s*\\}\\}" options:NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnixLineSeparators error:nil];
    __block int offset = 0;
    [tagRegExp enumerateMatchesInString:htmlTemplate options:0 range:NSMakeRange(0, htmlString.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        if (result.numberOfRanges != 2) return;
        NSRange tagRange = [result rangeAtIndex:0];
        NSRange tagNameRange = [result rangeAtIndex:1];
        if (tagRange.location != NSNotFound && tagNameRange.location != NSNotFound)
        {
            tagRange.location += offset;
            NSString *tagName = [htmlTemplate substringWithRange:tagNameRange];
            NSString *repl = dictionary[tagName];
            if (!repl) repl = @"";
            [htmlString replaceCharactersInRange:tagRange withString:repl];
            offset += repl.length - tagRange.length;
        }
    }];
    
    return [htmlString copy];
}

@end
