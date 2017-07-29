//
//  XUILogger.h
//  XXTExplorer
//
//  Created by Zheng on 29/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef XUILogger_h
#define XUILogger_h

#import <Foundation/Foundation.h>

static inline NSString * XUIParserErrorMissingEntry(NSString *path1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[Missing Entry]\nPath \"%@\" is missing.", nil), (path1)];
}

static inline NSString * XUIParserErrorInvalidType(NSString *path1, NSString *type1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[Invalid Type]\nPath \"%@\" should be %@.", nil), (path1), (type1)];
}

static inline NSString * XUIParserErrorEmptyWarning(NSString *path1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[Empty Warning]\nPath \"%@\" (treated as array) is empty.", nil), (path1)];
}

static inline NSString * XUIParserErrorUnknownEnum(NSString *path1, NSString *value1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[Unknown Enum]\nThe value of path \"%@\" (\"%@\") is invalid.", nil), (path1), (value1)];
}

static inline NSString * XUIParserErrorUndefinedKey(NSString *path1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[Undefined Key]\nThe key of path \"%@\" is undefined.", nil), (path1)];
}

NSString * const kXUICellFactoryErrorDomain = @"com.xxtouch.xui.parser.error";


#endif /* XUILogger_h */
