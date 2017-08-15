//
//  XXTETextStorage.m
//  XXTExplorer
//
//  Created by Zheng Wu on 15/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import "XXTETextStorage.h"
#import "XXTEDispatchDefines.h"
#import "XXTExplorer-Swift.h"

@interface XXTETextStorage ()

@property (nonatomic, strong) NSMutableAttributedString *attributedString;

@property (nonatomic, strong, readonly) SKHelper *helper;
@property (nonatomic, strong, readonly) SKAttributedParser *attributedParser;
@property (nonatomic, strong, readonly) NSOperationQueue *highlightQueue;
@property (atomic, strong, readonly) SKAttributedParsingOperation *lastOperation;

@end

@implementation XXTETextStorage

- (instancetype)initWithConfig:(SKHelperConfig *)config {
    if (self = [super init]) {
        _attributedString = [[NSMutableAttributedString alloc] init];
        
        SKHelper *helper = [[SKHelper alloc] initWithConfig:config];
        SKAttributedParser *parser = [helper attributedParser];
        
        _helper = helper;
        _attributedParser = parser;
        _highlightQueue = [NSOperationQueue mainQueue];
        _highlightQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (NSString *)string {
    return [_attributedString string];
}

- (void)setAttributedString:(NSAttributedString *)attrString {
    _attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attrString];
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
    
    {
        NSString *inputString = self.string;
        SKAttributedParsingOperation *operation = nil;
        if (_lastOperation == nil) {
            operation = [self.helper newAttributedOperationWithString:inputString callback:^(NSArray <NSValue *> * _Nonnull rangeArray, NSArray<NSDictionary <NSString *,id> *> * _Nonnull attributesArray, SKAttributedParsingOperation * _Nonnull operation) {
                for (NSUInteger idx = 0; idx < rangeArray.count; idx++) {
                    NSRange range = [rangeArray[idx] rangeValue];
                    NSDictionary *attributes = attributesArray[idx];
                    if (attributes != nil) {
                        [self addAttributes:attributes range:range];
                    }
                }
            }];
        } else {
            BOOL insertion = (inRange.length == 0 && str.length > 0);
            NSRange editedRange = self.editedRange;
            if (editedRange.location != NSNotFound) {
                operation = [self.helper attributedOperationWithString:inputString previousOperation:_lastOperation changeIsInsertion:insertion changedRange:editedRange];
            }
        }
        if (operation) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(addHighlightOperation:) withObject:operation afterDelay:.2f];
            _lastOperation = operation;
        }
    }
    
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

- (void)addHighlightOperation:(SKAttributedParsingOperation *)operation {
    [self.highlightQueue addOperation:operation];
}

@end
