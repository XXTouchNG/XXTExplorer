//
//  XUIConfigurationParser.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XUIConfigurationParser.h"

#define XUIParseErrorMissingEntry(path1) ([NSString stringWithFormat:NSLocalizedString(@"[Missing Entry]\nPath \"%@\" is missing.", nil), (path1)])
#define XUIParseErrorInvalidType(path1, type1) ([NSString stringWithFormat:NSLocalizedString(@"[Invalid Type]\nPath \"%@\" should be %@.", nil), (path1), (type1)])
#define XUIParseErrorEmptyWarning(path1) ([NSString stringWithFormat:NSLocalizedString(@"[Empty Warning]\nPath \"%@\" (treated as array) is empty.", nil), (path1)])

NSString * const kXUIConfigurationParserErrorDomain = @"com.xxtouch.xui.parser.error";

@interface XUIConfigurationParser ()
@property (nonatomic, strong, readonly) NSArray <NSDictionary *> *items;

@end

@implementation XUIConfigurationParser

- (instancetype)initWithRootEntry:(NSDictionary <NSString *, id> *)rootEntry {
    if (self = [super init]) {
        @try {
            NSArray <NSDictionary *> *items = rootEntry[@"items"];
            if (!items) {
                @throw XUIParseErrorMissingEntry(@"items");
            }
            if (![items isKindOfClass:[NSArray class]]) {
                @throw XUIParseErrorInvalidType(@"items", @"array");
            }
            if (items.count <= 0) {
                @throw XUIParseErrorEmptyWarning(@"items");
            }
        } @catch (NSString *exception) {
            _error = [NSError errorWithDomain:kXUIConfigurationParserErrorDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: exception }];
        } @finally {
            _rootEntry = rootEntry;
        }
    }
    return self;
}

@end
