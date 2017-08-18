//
//  SKAttributedParsingOperation.h
//  SyntaxKit
//
//  Subclass of NSOperation that can be used for mutithreaded incremental
//  parsing with all the benefits of NSOperationQueue.
//
//  It's underlying parser is an attributed parser. In theory this could be
//  refactored into a superclass that uses parser and a subclass that uses
//  attributed parser, but honestly I don't see a use-case of ParsingOperation
//  so there is only this class.
//
//  Note that the callback returns an array of results instead of each result
//  separately. This is more efficient since it allows coalescing the edits
//  between a beginEditing and an endEditing call.
//
//  Created by Zheng on 19/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKTheme.h"

@class SKAttributedParsingOperation;
@class SKLanguage;
@class SKDiff;
@class SKScopedString;

// MARK: - Types

/// Asynchronous or synchronous callback to which the results are passed
///
/// The sender is passed in so it can be used to check if the operation was
/// cancelled after the call.
typedef void (^SKAttributedParsingOperationCallback)(NSArray <NSValue *> *rangeArray, NSArray <SKAttributes> *attributesArray, SKAttributedParsingOperation *operation);

@interface SKAttributedParsingOperation : NSOperation

// MARK: - Initializers

/// Initializer for the first instance in the NSOperationQueue
///
/// Can also be used if no incremental parsing is desired
- (instancetype)initWithString:(NSString *)string language:(SKLanguage *)language theme:(SKTheme *)theme callback:(SKAttributedParsingOperationCallback)callback;

/// Initializer for operations that allow incremental parsing
///
/// The given change has to match the change in the string between the two
/// operations. Otherwise the entire string will be reparsed. If newCallback
/// is nil the callback from the previous operation will be used.
///
/// - parameter string:             The new String to parse.
/// - parameter previousOperation:  The preceding operation in the queue.
/// - parameter insertion:          True if the change was an insertion.
/// - parameter range:              Either the range in the old string that
///                                 was deleted or the range in the new
///                                 string that was added.
/// - parameter callback:           The callback to call with results.
- (instancetype)initWithString:(NSString *)string previousOperation:(SKAttributedParsingOperation *)previousOperation changeIsInsertion:(BOOL)insertion changedRange:(NSRange)range newCallback:(SKAttributedParsingOperationCallback)callback;

+ (NSRange)outdatedRangeIn:(NSString *)newString forChange:(SKDiff *)diff updatingPreviousResult:(SKScopedString **)previous;

@end
