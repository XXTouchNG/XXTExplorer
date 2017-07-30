//
//  XUICellFactory.m
//  XXTExplorer
//
//  Created by Zheng on 17/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <objc/runtime.h>
#import "XUICellFactory.h"
#import "XUIBaseCell.h"
#import "XUIGroupCell.h"
#import "XUILogger.h"

@interface XUICellFactory ()

@property (nonatomic, strong, readonly) XUILogger *logger;
@property (nonatomic, strong, readonly) NSArray <NSDictionary *> *items;

@end

@implementation XUICellFactory

- (instancetype)initWithRootEntry:(NSDictionary <NSString *, id> *)rootEntry {
    if (self = [super init]) {
        _rootEntry = rootEntry;
        _logger = [[XUILogger alloc] init];
    }
    return self;
}

- (void)parse {
    @try {
        NSBundle *bundle = [NSBundle mainBundle];
        NSDictionary *rootEntry = self.rootEntry;
        NSArray <NSDictionary *> *items = rootEntry[@"items"];
        if (!items)
            @throw XUIParserErrorMissingEntry(@"items");
        if (![items isKindOfClass:[NSArray class]])
            @throw XUIParserErrorInvalidType(@"items", @"NSArray");
        NSUInteger itemCount = items.count;
        if (itemCount <= 0)
            @throw XUIParserErrorEmptyWarning(@"items");
        NSMutableArray <XUIBaseCell *> *cells = [[NSMutableArray alloc] initWithCapacity:itemCount];
        for (NSUInteger itemIdx = 0; itemIdx < itemCount; itemIdx++) {
            NSDictionary *itemDictionary = items[itemIdx];
            NSString *cellClassName = itemDictionary[@"cell"];
            if (!cellClassName) {
                [self.logger logMessage:[NSString stringWithFormat:XUIParserErrorMissingEntry(@"items[%lu] -> cell"), itemIdx]];
                continue;
            }
            if (![cellClassName isKindOfClass:[NSString class]]) {
                [self.logger logMessage:[NSString stringWithFormat:XUIParserErrorInvalidType(@"items[%lu] -> cell", @"NSString"), itemIdx]];
                continue;
            }
            Class cellClass = NSClassFromString(cellClassName);
            if (!cellClass || ![cellClass isSubclassOfClass:[XUIBaseCell class]]) {
                [self.logger logMessage:[NSString stringWithFormat:XUIParserErrorUnknownEnum(@"items[%lu] -> cell", cellClassName), itemIdx]];
                continue;
            }
            XUIBaseCell *cellInstance = nil;
            if ([[cellClass class] xibBasedLayout]) {
                cellInstance = [[bundle loadNibNamed:cellClassName owner:self options:nil] lastObject];
            } else {
                cellInstance = [[cellClass alloc] init];
            }
            NSError *checkError = nil;
            BOOL checkResult = [[cellInstance class] checkEntry:itemDictionary withError:&checkError];
            if (!checkResult) {
                [self.logger logMessage:[NSString stringWithFormat:NSLocalizedString(@"[%@]\nPath \"items[%lu]\", %@", nil), checkError.domain, itemIdx, checkError.localizedDescription]];
                continue;
            }
            cellInstance.bundle = self.bundle;
            NSArray <NSString *> *itemAllKeys = [itemDictionary allKeys];
            for (int keyIdx = 0; keyIdx < itemAllKeys.count; ++keyIdx) {
                NSString *itemKey = itemAllKeys[(NSUInteger) keyIdx];
                NSString *propertyName = [NSString stringWithFormat:@"xui_%@", itemKey];
                if (class_getProperty([cellInstance class], [propertyName UTF8String])) {
                    [cellInstance setValue:itemDictionary[itemKey] forKey:propertyName];
                } else {
                    [self.logger logMessage:[NSString stringWithFormat:XUIParserErrorUndefinedKey(@"items[%lu] -> %@"), itemIdx, propertyName]];
                }
            }
            [cells addObject:cellInstance];
        }
        NSMutableArray <XUIGroupCell *> *groupCells = [[NSMutableArray alloc] init];
        for (XUIBaseCell *baseCell in cells) {
            if ([baseCell isKindOfClass:[XUIGroupCell class]])
            {
                XUIGroupCell *groupCell = (XUIGroupCell *) baseCell;
                [groupCells addObject:groupCell];
            }
        }
        NSUInteger cellCount = cells.count;
        NSUInteger groupCount = groupCells.count;
        if (groupCount <= 0 && cellCount > 0) {
            XUIGroupCell *groupCell1 = [[XUIGroupCell alloc] init];
            [groupCells addObject:groupCell1];
        } // default group cell
        NSMutableArray <NSMutableArray <XUIBaseCell *> *> *otherCells = [[NSMutableArray alloc] initWithCapacity:groupCount];
        for (NSUInteger groupIdx = 0; groupIdx < groupCount; ++groupIdx) {
            [otherCells addObject:[[NSMutableArray alloc] init]];
        }
        NSInteger otherCellIdx = -1;
        for (XUIBaseCell *otherCell in cells) {
            if ([otherCell isKindOfClass:[XUIGroupCell class]]) {
                otherCellIdx++;
            } else if (otherCellIdx >= 0 && otherCellIdx < groupCount) {
                [otherCells[(NSUInteger) otherCellIdx] addObject:otherCell];
            }
        }
        _sectionCells = groupCells;
        _otherCells = otherCells;
        if (_delegate && [_delegate respondsToSelector:@selector(cellFactoryDidFinishParsing:)]) {
            [_delegate cellFactoryDidFinishParsing:self];
        }
    } @catch (NSString *exception) {
        NSError *error = [NSError errorWithDomain:kXUICellFactoryErrorDomain code:400 userInfo:@{ NSLocalizedDescriptionKey: exception }];
        if (_delegate && [_delegate respondsToSelector:@selector(cellFactory:didFailWithError:)]) {
            [_delegate cellFactory:self didFailWithError:error];
        }
        _error = error;
    } @finally {
        assert(self.sectionCells.count == self.otherCells.count);
    }
}

@end
