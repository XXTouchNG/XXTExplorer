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

extern NSString * const kXUICellFactoryErrorDomain;
extern NSString * const kXUICellFactoryErrorMissingEntryDomain;
extern NSString * const kXUICellFactoryErrorInvalidTypeDomain;
extern NSString * const kXUICellFactoryErrorEmptyWarningDomain;
extern NSString * const kXUICellFactoryErrorUnknownEnumDomain;
extern NSString * const kXUICellFactoryErrorUndefinedKeyDomain;
extern NSString * const kXUICellFactoryErrorSizeDismatchDomain;

static inline NSString * XUIParserErrorMissingEntry(NSString *path1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[%@]\nPath \"%@\" is missing.", nil), kXUICellFactoryErrorMissingEntryDomain, (path1)];
}

static inline NSString * XUIParserErrorInvalidType(NSString *path1, NSString *type1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[%@\nPath \"%@\" should be \"%@\".", nil), kXUICellFactoryErrorInvalidTypeDomain, (path1), (type1)];
}

static inline NSString * XUIParserErrorEmptyWarning(NSString *path1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[%@]\nPath \"%@\" (treated as \"NSArray\") is empty.", nil), kXUICellFactoryErrorEmptyWarningDomain, (path1)];
}

static inline NSString * XUIParserErrorUnknownEnum(NSString *path1, NSString *value1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[%@]\nThe value of path \"%@\" (\"%@\") is invalid.", nil), kXUICellFactoryErrorUnknownEnumDomain, (path1), (value1)];
}

static inline NSString * XUIParserErrorUndefinedKey(NSString *path1) {
    return [NSString stringWithFormat:NSLocalizedString(@"[%@]\nThe key of path \"%@\" is undefined.", nil), kXUICellFactoryErrorUndefinedKeyDomain, (path1)];
}

@interface XUILogger : NSObject

- (void)logMessage:(NSString *)message;

@end

#endif /* XUILogger_h */
