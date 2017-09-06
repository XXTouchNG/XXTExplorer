//
//  SKResult.h
//  XXTExplorer
//
//  Represents a match by the parser.
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKResult : NSObject

// MARK: - Properties
@property (nonatomic, strong, readonly) NSString *patternIdentifier;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, strong, readonly) NSTextCheckingResult *rawResult;
@property (nonatomic, strong, readonly) id attribute;

// MARK: - Initializers
- (instancetype)initWithIdentifier:(NSString *)identifier range:(NSRange)range rawResult:(NSTextCheckingResult *)rawResult attribute:(id)attribute;

- (BOOL)isEqual:(SKResult *)scope;

@end
