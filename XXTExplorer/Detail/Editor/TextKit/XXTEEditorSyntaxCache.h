//
//  XXTEEditorSyntaxCache.h
//  XXTExplorer
//
//  Created by Darwin on 8/7/19.
//  Copyright © 2019 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKAttributedParser.h"


NS_ASSUME_NONNULL_BEGIN

@interface XXTEEditorSyntaxCache : NSObject

@property (nonatomic, weak) SKAttributedParser *referencedParser;
@property (nonatomic, copy) NSString *text;
@property (atomic, strong) NSMutableIndexSet *renderedSet;
@property (atomic, strong) NSMutableArray <NSValue *> *rangesArray;
@property (atomic, strong) NSMutableArray <NSDictionary *> *attributesArray;

@end

NS_ASSUME_NONNULL_END
