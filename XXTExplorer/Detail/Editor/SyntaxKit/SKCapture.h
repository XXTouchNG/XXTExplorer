//
//  SKCapture.h
//  SyntaxKit
//
//  Represents a capture in a TextMate grammar.
//
//  Created by Zheng on 13/08/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SKCapture : NSObject

// MARK: - Properties
@property (nonatomic, strong, readonly) NSString *name;

// MARK: - Initializers
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
