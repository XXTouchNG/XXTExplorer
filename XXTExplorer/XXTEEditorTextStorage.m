//
//  XXTEEditorTextStorage.m
//  XXTExplorer
//
//  Created by Zheng Wu on 15/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTEEditorTextStorage.h"

@interface XXTEEditorTextStorage ()

@property (nonatomic, strong) NSMutableAttributedString *attributedString;

@end

@implementation XXTEEditorTextStorage

- (instancetype)init {
    if (self = [super init]) {
        _attributedString = [[NSMutableAttributedString alloc] init];
    }
    return self;
}

- (NSString *)string {
    return [_attributedString string];
}

- (void)setAttributedString:(NSAttributedString *)attrString
{
    _attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attrString];
}

- (NSUInteger)length
{
    return [_attributedString length];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    return [_attributedString attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)inRange withString:(NSString *)str
{
    [self beginEditing];
    
    [_attributedString replaceCharactersInRange:inRange withString:str];
    [self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:inRange changeInLength:str.length - inRange.length];
    
    [self endEditing];
}

- (void)setAttributes:(NSDictionary*)attrs range:(NSRange)range
{
    [self beginEditing];
    
    [_attributedString setAttributes:attrs range:range];
    
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

- (void)processEditing
{
    [super processEditing];
}

@end
