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
#import "XUIAdapter.h"
#import "XUITheme.h"

@interface XUICellFactory ()

@property (nonatomic, strong, readonly) NSArray <NSDictionary *> *items;

@end

@implementation XUICellFactory

- (instancetype)initWithAdapter:(XUIAdapter *)adapter Error:(NSError *__autoreleasing *)error {
    if (self = [super init]) {
        _adapter = adapter;
        _logger = [[XUILogger alloc] init];
        
        NSDictionary *rootEntry = [adapter rootEntryWithError:error];
        if (!rootEntry) return nil;
        _rootEntry = rootEntry;
        
        NSDictionary *themeDictionary = rootEntry[@"theme"];
        if (!themeDictionary || ![themeDictionary isKindOfClass:[NSDictionary class]])
            _theme = [[XUITheme alloc] init];
        else
            _theme = [[XUITheme alloc] initWithDictionary:themeDictionary];
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
            cellInstance.adapter = self.adapter;
            cellInstance.theme = self.theme;
            NSArray <NSString *> *itemAllKeys = [itemDictionary allKeys];
            for (NSUInteger keyIdx = 0; keyIdx < itemAllKeys.count; ++keyIdx) {
                NSString *itemKey = itemAllKeys[keyIdx];
                if (![itemKey isEqualToString:@"value"])
                {
                    id itemValue = itemDictionary[itemKey];
                    [self setObject:itemValue forKey:itemKey forCellInstance:cellInstance atIndex:itemIdx];
                }
            }
            NSString *itemKey = @"value";
            id itemValue = itemDictionary[itemKey];
            [self setObject:itemValue forKey:itemKey forCellInstance:cellInstance atIndex:itemIdx];
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
                [otherCells[otherCellIdx] addObject:otherCell];
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
    } @finally {
        assert(self.sectionCells.count == self.otherCells.count);
    }
}

- (void)setObject:(id)itemValue forKey:(NSString *)itemKey forCellInstance:(XUIBaseCell *)cellInstance atIndex:(NSUInteger)itemIdx {
    if (!itemValue || !itemKey || !cellInstance) return;
    NSString *propertyName = [NSString stringWithFormat:@"xui_%@", itemKey];
    if (class_getProperty([cellInstance class], [propertyName UTF8String])) {
        [cellInstance setValue:itemValue forKey:propertyName];
    } else {
        [self.logger logMessage:[NSString stringWithFormat:XUIParserErrorUndefinedKey(@"items[%lu] -> %@"), itemIdx, propertyName]];
    }
}

@end
